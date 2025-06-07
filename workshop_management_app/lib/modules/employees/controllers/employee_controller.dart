import 'package:flutter/foundation.dart';
import '../../../core/database_service.dart';
import '../models/employee.dart';

class EmployeeController with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<Employee> _employees = [];
  List<Employee> get employees => _employees;

  Employee? _selectedEmployee;
  Employee? get selectedEmployee => _selectedEmployee;

  List<WorkLog> _workLogs = [];
  List<WorkLog> get workLogs => _workLogs;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  EmployeeController() {
    // Optionally load employees when controller is created
    // fetchEmployees();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> fetchEmployees({String? query}) async {
    _setLoading(true);
    _setError(null);
    try {
      _employees = await _dbService.getEmployees(query: query);
    } catch (e) {
      _setError('Failed to load employees: ${e.toString()}');
      _employees = []; // Ensure employees list is empty on error
    }
    _setLoading(false);
  }

  Future<bool> addEmployee(Employee employee) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.insertEmployee(employee);
      await fetchEmployees(); // Refresh list
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to add employee: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateEmployee(Employee employee) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.updateEmployee(employee);
      await fetchEmployees(); // Refresh list
      if (_selectedEmployee?.id == employee.id) {
        _selectedEmployee = await _dbService.getEmployeeById(employee.id!);
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update employee: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteEmployee(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.deleteEmployee(id);
      await fetchEmployees(); // Refresh list
      if (_selectedEmployee?.id == id) {
        _selectedEmployee = null;
        _workLogs = [];
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete employee: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<void> selectEmployee(Employee? employee) async {
    _selectedEmployee = employee;
    if (employee != null) {
      await fetchWorkLogsForSelectedEmployee();
    } else {
      _workLogs = [];
    }
    notifyListeners();
  }

  Future<Employee?> getEmployeeById(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      final employee = await _dbService.getEmployeeById(id);
      _setLoading(false);
      return employee;
    } catch (e) {
      _setError('Failed to get employee: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }

  Future<void> fetchWorkLogsForSelectedEmployee({DateTime? startDate, DateTime? endDate}) async {
    if (_selectedEmployee == null) return;
    _setLoading(true);
    _setError(null);
    try {
      _workLogs = await _dbService.getWorkLogsForEmployee(
        _selectedEmployee!.id!,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _setError('Failed to load work logs: ${e.toString()}');
      _workLogs = []; // Ensure worklogs list is empty on error
    }
    _setLoading(false);
  }

  Future<bool> addWorkLog(WorkLog workLog) async {
    if (_selectedEmployee == null || workLog.employeeId != _selectedEmployee!.id) {
      _setError("Selected employee mismatch or no employee selected for work log.");
      return false;
    }
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.insertWorkLog(workLog);
      await fetchWorkLogsForSelectedEmployee(); // Refresh list
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to add work log: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateWorkLog(WorkLog workLog) async {
    if (_selectedEmployee == null || workLog.employeeId != _selectedEmployee!.id) {
       _setError("Selected employee mismatch or no employee selected for work log update.");
      return false;
    }
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.updateWorkLog(workLog);
      await fetchWorkLogsForSelectedEmployee(); // Refresh list
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update work log: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteWorkLog(int workLogId) async {
    if (_selectedEmployee == null) return false;
    _setLoading(true);
    _setError(null);
    try {
      await _dbService.deleteWorkLog(workLogId);
      await fetchWorkLogsForSelectedEmployee(); // Refresh list
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete work log: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  double calculateSalaryForPeriod(Employee employee, List<WorkLog> logsInPeriod) {
    double totalSalary = 0;
    for (var log in logsInPeriod) {
      if (log.employeeId == employee.id) {
        if (employee.payType == "hourly") {
          totalSalary += (log.hoursWorked * employee.hourlyRate);
        } else if (employee.payType == "daily") {
          if (log.workedDay) {
            totalSalary += employee.dailyRate;
          }
        }
        totalSalary += (log.overtimeHours * employee.overtimeRate);
      }
    }
    return totalSalary;
  }

  // Example of calculating salary for the current _selectedEmployee and _workLogs
  // This would typically be called with a filtered list of worklogs for a specific period
  double calculateCurrentSelectedEmployeeSalary(DateTime startDate, DateTime endDate) {
    if (_selectedEmployee == null) return 0.0;

    final relevantLogs = _workLogs.where((log) {
      return !log.date.isBefore(startDate) && !log.date.isAfter(endDate);
    }).toList();

    return calculateSalaryForPeriod(_selectedEmployee!, relevantLogs);
  }

  // TODO: Add logic for warnings for attendance (e.g., if no log for a workday)
}
