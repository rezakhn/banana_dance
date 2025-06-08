import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workshop_management_app/modules/reports/controllers/report_controller.dart';
import 'package:workshop_management_app/modules/reports/views/report_dashboard_screen.dart';
import 'package:workshop_management_app/modules/reports/models/income_report_data.dart';
import 'package:workshop_management_app/modules/employees/controllers/employee_controller.dart'; // For employee dropdown
import 'package:workshop_management_app/modules/employees/models/employee.dart';
import 'package:workshop_management_app/modules/reports/models/employee_performance_data.dart'; // Added
import 'package:workshop_management_app/modules/employees/models/work_log.dart'; // Added


// Mock ReportController
class MockReportController extends ChangeNotifier implements ReportController {
  DateTime? _start = DateTime.now().subtract(Duration(days:30));
  DateTime? _end = DateTime.now();
  IncomeReportData? _incomeData;
  List<EmployeePerformanceData> _empPerfData = [];
  bool _loading = false;
  String? _err;
  Employee? _selectedEmp;


  @override DateTime? get reportStartDate => _start;
  @override DateTime? get reportEndDate => _end;
  @override IncomeReportData? get incomeReportData => _incomeData;
  @override List<EmployeePerformanceData> get employeePerformanceList => _empPerfData;
  @override bool get isLoading => _loading;
  @override String? get errorMessage => _err;
  @override Employee? get selectedEmployeeForReport => _selectedEmp;


  @override void setDateRange(DateTime start, DateTime end) { _start = start; _end = end; _incomeData=null; _empPerfData=[]; notifyListeners(); }
  @override Future<void> generateIncomeReport({DateTime? startDate, DateTime? endDate}) async {
    _loading = true; notifyListeners();
    await Future.delayed(Duration(milliseconds: 50)); // Simulate async
    _incomeData = IncomeReportData(startDate: startDate ?? _start!, endDate: endDate ?? _end!, totalRevenue: 1000, totalExpenses: 400);
    _loading = false; notifyListeners();
  }
  @override Future<void> generateEmployeePerformanceReport({DateTime? startDate, DateTime? endDate, Employee? employee}) async {
    _loading = true; notifyListeners();
    await Future.delayed(Duration(milliseconds: 50));
    if (employee == null || employee.id == 1) { // Simulate data for one or all
      _empPerfData = [EmployeePerformanceData(employeeId: 1, employeeName: 'Test Emp', totalSalaryPaid: 200, workLogEntryCount: 5)];
    } else {
      _empPerfData = [];
    }
    _loading = false; notifyListeners();
  }
  @override void setSelectedEmployeeForReport(Employee? employee) { _selectedEmp = employee; notifyListeners(); }

}

// Mock EmployeeController for the dropdown
class MockEmployeeController extends ChangeNotifier implements EmployeeController {
  List<Employee> _emps = [Employee(id:1, name:"Test Emp", payType:"hourly", hourlyRate:10, overtimeRate:10)];
  bool _loading = false;
  @override List<Employee> get employees => _emps;
  @override bool get isLoading => _loading;
  // Implement other methods if ReportDashboardScreen calls them, otherwise stubs are fine
  @override Future<void> fetchEmployees({String? query}) async {}
  // Add other required overrides from EmployeeController interface
  @override Employee? get selectedEmployee => null;
  @override List<WorkLog> get workLogs => [];
  @override String? get errorMessage => null;
  @override Future<bool> addEmployee(Employee employee) async => true;
  @override Future<bool> updateEmployee(Employee employee) async => true;
  @override Future<bool> deleteEmployee(int id) async => true;
  @override Future<void> selectEmployee(Employee? employee) async {}
  @override Future<Employee?> getEmployeeById(int id) async => null;
  @override Future<void> fetchWorkLogsForSelectedEmployee({DateTime? startDate, DateTime? endDate}) async {}
  @override Future<bool> addWorkLog(WorkLog workLog) async => true;
  @override Future<bool> updateWorkLog(WorkLog workLog) async => true;
  @override Future<bool> deleteWorkLog(int workLogId) async => true;
  @override double calculateSalaryForPeriod(Employee employee, List<WorkLog> logsInPeriod) => 0;
  @override double calculateCurrentSelectedEmployeeSalary(DateTime startDate, DateTime endDate) => 0;
}


void main() {
  late MockReportController mockReportController;
  late MockEmployeeController mockEmployeeController;

  setUp(() {
    mockReportController = MockReportController();
    mockEmployeeController = MockEmployeeController();
  });

  Widget buildTestableWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ReportController>.value(value: mockReportController),
        ChangeNotifierProvider<EmployeeController>.value(value: mockEmployeeController),
      ],
      child: MaterialApp(home: ReportDashboardScreen()),
    );
  }

  testWidgets('ReportDashboardScreen displays date pickers and report type selector', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget());
    expect(find.textContaining('Select Start Date'), findsOneWidget); // Based on initial null dates in mock
    expect(find.textContaining('Select End Date'), findsOneWidget);
    expect(find.byType(SegmentedButton<ReportType>), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Generate Report'), findsOneWidget);
  });

  testWidgets('Generating Income Report displays income data', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget());

    // Select Income report type
    await tester.tap(find.widgetWithText(ButtonSegment<ReportType>, 'Income'));
    await tester.pumpAndSettle();

    // Tap Generate Report
    await tester.tap(find.widgetWithText(ElevatedButton, 'Generate Report'));
    await tester.pumpAndSettle(); // For async and state updates

    expect(find.textContaining('Total Revenue (Completed Sales):'), findsOneWidget);
    expect(find.text('\$1000.00'), findsOneWidget);
    expect(find.textContaining('Net Profit:'), findsOneWidget);
    expect(find.text('\$600.00'), findsOneWidget);
  });

  testWidgets('Generating Employee Performance Report displays employee data', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget());

    await tester.tap(find.widgetWithText(ButtonSegment<ReportType>, 'Employee'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Generate Report'));
    await tester.pumpAndSettle();

    expect(find.text('Test Emp'), findsOneWidget);
    expect(find.textContaining('Total Salary Paid (Period):'), findsOneWidget);
    expect(find.text('\$200.00'), findsOneWidget);
  });
}
