import 'package:flutter/foundation.dart';
import '../../../core/database_service.dart';
import '../models/income_report_data.dart';
import '../models/employee_performance_data.dart';
import '../../employees/models/employee.dart'; // For Employee details
import '../../employees/models/work_log.dart';   // For WorkLog details

class ReportController with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  // If direct access to EmployeeController's salary calculation is too complex,
  // we can replicate a simplified version here or make EmployeeController's method static/easily callable.
  // For now, we'll fetch raw data and calculate here.

  // Date Range State
  DateTime? _reportStartDate;
  DateTime? _reportEndDate;
  DateTime? get reportStartDate => _reportStartDate;
  DateTime? get reportEndDate => _reportEndDate;

  // Income Report State
  IncomeReportData? _incomeReportData;
  IncomeReportData? get incomeReportData => _incomeReportData;

  // Employee Performance Report State
  List<EmployeePerformanceData> _employeePerformanceList = [];
  List<EmployeePerformanceData> get employeePerformanceList => _employeePerformanceList;
  Employee? _selectedEmployeeForReport; // Optional filter
  Employee? get selectedEmployeeForReport => _selectedEmployeeForReport;


  // Common State
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  ReportController() {
    // Set default date range, e.g., current month
    final now = DateTime.now();
    _reportStartDate = DateTime(now.year, now.month, 1);
    _reportEndDate = DateTime(now.year, now.month + 1, 0); // Last day of current month
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void setDateRange(DateTime start, DateTime end) {
    _reportStartDate = start;
    _reportEndDate = end;
    // Clear previous report data when date range changes
    _incomeReportData = null;
    _employeePerformanceList = [];
    notifyListeners();
  }

  void setSelectedEmployeeForReport(Employee? employee) {
    _selectedEmployeeForReport = employee;
    _employeePerformanceList = []; // Clear previous data
    notifyListeners();
  }


  Future<void> generateIncomeReport({DateTime? startDate, DateTime? endDate}) async {
    final start = startDate ?? _reportStartDate;
    final end = endDate ?? _reportEndDate;

    if (start == null || end == null) {
      _setError("Please select a valid date range for the income report.");
      return;
    }
    if (end.isBefore(start)) {
      _setError("End date cannot be before start date.");
      return;
    }

    _setLoading(true);
    _setError(null);
    _incomeReportData = null; // Clear previous

    try {
      final totalRevenue = await _dbService.getSalesTotalInDateRange(start, end);
      final totalExpenses = await _dbService.getPurchaseTotalInDateRange(start, end);

      _incomeReportData = IncomeReportData(
        startDate: start,
        endDate: end,
        totalRevenue: totalRevenue,
        totalExpenses: totalExpenses,
      );

    } catch (e) {
      _setError('Failed to generate income report: ${e.toString()}');
      _incomeReportData = null;
    }
    _setLoading(false);
  }

  Future<void> generateEmployeePerformanceReport({DateTime? startDate, DateTime? endDate, Employee? employee}) async {
    final start = startDate ?? _reportStartDate;
    final end = endDate ?? _reportEndDate;
    final targetEmployee = employee ?? _selectedEmployeeForReport;


    if (start == null || end == null) {
      _setError("Please select a valid date range for the employee performance report.");
      return;
    }
     if (end.isBefore(start)) {
      _setError("End date cannot be before start date.");
      return;
    }

    _setLoading(true);
    _setError(null);
    _employeePerformanceList = []; // Clear previous

    try {
      List<Employee> employeesToReportOn = [];
      if (targetEmployee != null) {
        employeesToReportOn.add(targetEmployee);
      } else {
        employeesToReportOn = await _dbService.getEmployees(); // Get all employees
      }

      for (var emp in employeesToReportOn) {
        final workLogs = await _dbService.getWorkLogsForEmployee(emp.id!, startDate: start, endDate: end);

        double salaryForPeriod = 0;
        int daysWorked = 0;
        double hoursWorked = 0;
        double overtimeHours = 0;

        for (var log in workLogs) {
          if (emp.payType == "hourly") {
            salaryForPeriod += (log.hoursWorked * emp.hourlyRate);
            hoursWorked += log.hoursWorked;
          } else if (emp.payType == "daily") {
            if (log.workedDay) {
              salaryForPeriod += emp.dailyRate;
              daysWorked++;
            }
          }
          salaryForPeriod += (log.overtimeHours * emp.overtimeRate);
          overtimeHours += log.overtimeHours;
        }

        _employeePerformanceList.add(EmployeePerformanceData(
          employeeId: emp.id!,
          employeeName: emp.name,
          totalDaysWorked: daysWorked,
          totalHoursWorked: hoursWorked,
          totalOvertimeHours: overtimeHours,
          totalSalaryPaid: salaryForPeriod,
          workLogEntryCount: workLogs.length,
        ));
      }
    } catch (e) {
      _setError('Failed to generate employee performance report: ${e.toString()}');
      _employeePerformanceList = [];
    }
    _setLoading(false);
  }
}
