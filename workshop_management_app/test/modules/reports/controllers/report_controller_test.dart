import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:workshop_management_app/core/database_service.dart';
import 'package:workshop_management_app/modules/reports/controllers/report_controller.dart';
import 'package:workshop_management_app/modules/reports/models/income_report_data.dart';
import 'package:workshop_management_app/modules/reports/models/employee_performance_data.dart';
import 'package:workshop_management_app/modules/employees/models/employee.dart';
import 'package:workshop_management_app/modules/employees/models/work_log.dart';
import 'package:workshop_management_app/modules/orders/models/sales_order.dart'; // For seeding
import 'package:workshop_management_app/modules/purchases/models/purchase_invoice.dart'; // For seeding
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // For test setup


// Manual mock for DatabaseService
class MockDatabaseService extends Mock implements DatabaseService {}
// If EmployeeController's salary method was used, it would need mocking too.

// Initialize FFI for sqflite if running on host (non-Flutter environment)
void sqfliteTestInit() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}


void main() {
  sqfliteTestInit(); // Initialize sqflite_common_ffi for all tests in this file

  late ReportController reportController;
  // late MockDatabaseService mockDatabaseService; // Mock not used due to controller design

  setUp(() {
    reportController = ReportController();
    // The DatabaseService instance within ReportController will use the FFI factory
    // due to sqfliteTestInit(), so it will run on an in-memory DB for tests.
    // We need to ensure the DB is cleared and schema created for each relevant test group.
  });

  final startDate = DateTime(2023, 1, 1);
  final endDate = DateTime(2023, 1, 31);

  group('ReportController - Date Range', () {
    test('initial date range is set to current month', () {
      final now = DateTime.now();
      final expectedStart = DateTime(now.year, now.month, 1);
      final expectedEnd = DateTime(now.year, now.month + 1, 0);
      expect(reportController.reportStartDate, expectedStart);
      expect(reportController.reportEndDate, expectedEnd);
    });

    test('setDateRange updates start and end dates and clears report data', () async {
      // Populate some data first to check clearing - this will use the in-memory DB.
      // Need to ensure the DB is setup for these calls.
      // This test is a bit more involved because generateIncomeReport is async and interacts with DB.
      // For simplicity, we'll just check if dates are set and data is nulled/emptied.

      final newStart = DateTime(2023, 2, 1);
      final newEnd = DateTime(2023, 2, 28);
      reportController.setDateRange(newStart, newEnd);

      expect(reportController.reportStartDate, newStart);
      expect(reportController.reportEndDate, newEnd);
      expect(reportController.incomeReportData, null);
      expect(reportController.employeePerformanceList, isEmpty);
    });
  });

  group('ReportController - Income Report (Integration Style with In-Memory DB)', () {
    late DatabaseService dbServiceForSetup;

    setUpAll(() async {
      dbServiceForSetup = DatabaseService();
      // Ensure schema is created in the in-memory DB
      // The DatabaseService constructor will call _initDB which calls _createDB for the in-memory instance
      await (await dbServiceForSetup.database).getVersion(); // Ensures DB is open and created

      // Seed data once for this group
      // Need to insert dummy customer/supplier if FK constraints are active and matter for these inserts
      await dbServiceForSetup.insertCustomer(Customer(id:1, name: "Report Test Cust")); // Assuming ID 1 for customer
      await dbServiceForSetup.insertSupplier(Supplier(id:1, name: "Report Test Supp")); // Assuming ID 1 for supplier


      await dbServiceForSetup.insertSalesOrder(SalesOrder(customerId: 1, orderDate: DateTime(2023,1,15), totalAmount: 100, status: 'Completed', items: []));
      await dbServiceForSetup.insertSalesOrder(SalesOrder(customerId: 1, orderDate: DateTime(2023,1,20), totalAmount: 150, status: 'Completed', items: []));
      await dbServiceForSetup.insertSalesOrder(SalesOrder(customerId: 1, orderDate: DateTime(2023,2,5), totalAmount: 200, status: 'Completed', items: []));
      await dbServiceForSetup.insertSalesOrder(SalesOrder(customerId: 1, orderDate: DateTime(2023,1,10), totalAmount: 50, status: 'Pending', items: []));

      await dbServiceForSetup.insertPurchaseInvoice(PurchaseInvoice(supplierId: 1, date: DateTime(2023,1,10), totalAmount: 30, items: []));
      await dbServiceForSetup.insertPurchaseInvoice(PurchaseInvoice(supplierId: 1, date: DateTime(2023,1,25), totalAmount: 70, items: []));
      await dbServiceForSetup.insertPurchaseInvoice(PurchaseInvoice(supplierId: 1, date: DateTime(2023,2,2), totalAmount: 90, items: []));
    });

    tearDownAll(() async {
      await dbServiceForSetup.close(); // Close the setup DB instance
    });


    test('generateIncomeReport fetches data and calculates profit correctly', () async {
      await reportController.generateIncomeReport(startDate: startDate, endDate: endDate);

      expect(reportController.isLoading, false);
      expect(reportController.errorMessage, null);
      expect(reportController.incomeReportData, isNotNull);
      expect(reportController.incomeReportData!.totalRevenue, 250.0);
      expect(reportController.incomeReportData!.totalExpenses, 100.0);
      expect(reportController.incomeReportData!.netProfit, 150.0);
    });

    test('generateIncomeReport handles date validation', () async {
        await reportController.generateIncomeReport(startDate: endDate, endDate: startDate); // end before start
        expect(reportController.errorMessage, isNotNull);
        expect(reportController.incomeReportData, isNull);
    });
  });

  group('ReportController - Employee Performance Report (Integration Style with In-Memory DB)', () {
    late DatabaseService dbServiceForSetup;
    late Employee emp1;

    setUpAll(() async {
        dbServiceForSetup = DatabaseService();
        await (await dbServiceForSetup.database).getVersion(); // Ensure DB is open

        emp1 = Employee(name: 'Perf Test Emp', payType: 'hourly', hourlyRate: 10, dailyRate: 0, overtimeRate: 15);
        final emp1Id = await dbServiceForSetup.insertEmployee(emp1);
        emp1 = Employee(id: emp1Id, name: emp1.name, payType: emp1.payType, hourlyRate: emp1.hourlyRate, dailyRate: emp1.dailyRate, overtimeRate: emp1.overtimeRate);

        await dbServiceForSetup.insertWorkLog(WorkLog(employeeId: emp1Id, date: DateTime(2023,1,5), hoursWorked: 8, overtimeHours: 1));
        await dbServiceForSetup.insertWorkLog(WorkLog(employeeId: emp1Id, date: DateTime(2023,1,6), hoursWorked: 7, overtimeHours: 0));
        await dbServiceForSetup.insertWorkLog(WorkLog(employeeId: emp1Id, date: DateTime(2023,2,1), hoursWorked: 6));
    });

    tearDownAll(() async {
        await dbServiceForSetup.close();
    });

    test('generateEmployeePerformanceReport fetches and calculates correctly for all employees', () async {
      await reportController.generateEmployeePerformanceReport(startDate: startDate, endDate: endDate);

      expect(reportController.isLoading, false);
      expect(reportController.errorMessage, null);
      expect(reportController.employeePerformanceList, isNotEmpty);

      final emp1Data = reportController.employeePerformanceList.firstWhere((e) => e.employeeId == emp1.id);
      expect(emp1Data.totalHoursWorked, 15);
      expect(emp1Data.totalOvertimeHours, 1);
      expect(emp1Data.totalSalaryPaid, 165.0);
      expect(emp1Data.workLogEntryCount, 2);
    });

    test('generateEmployeePerformanceReport filters by selected employee', () async {
      var emp2 = Employee(name: 'Other Emp', payType: 'daily', dailyRate: 100, overtimeRate: 20);
      final emp2Id = await dbServiceForSetup.insertEmployee(emp2); // Use the setup instance
      emp2 = Employee(id:emp2Id, name:emp2.name, payType:emp2.payType, dailyRate:emp2.dailyRate, overtimeRate:emp2.overtimeRate);
      await dbServiceForSetup.insertWorkLog(WorkLog(employeeId: emp2Id, date: DateTime(2023,1,7), workedDay: true));

      await reportController.generateEmployeePerformanceReport(startDate: startDate, endDate: endDate, employee: emp1);

      expect(reportController.employeePerformanceList.length, 1);
      expect(reportController.employeePerformanceList.first.employeeId, emp1.id);
    });
  });
}
