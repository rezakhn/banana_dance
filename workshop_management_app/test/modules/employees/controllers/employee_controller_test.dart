import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_management_app/modules/employees/models/employee.dart';
import 'package:workshop_management_app/modules/employees/controllers/employee_controller.dart';
// Mock DatabaseService or use a real one with caution for unit tests
// For this example, we'll test the calculation logic directly, which doesn't need DB.

void main() {
  group('EmployeeController Salary Calculation', () {
    late EmployeeController controller;
    late Employee hourlyEmployee;
    late Employee dailyEmployee;

    setUp(() {
      controller = EmployeeController(); // Assuming DB interactions are not called in constructor or are handled
      hourlyEmployee = Employee(
        id: 1,
        name: 'Hourly Worker',
        payType: 'hourly',
        hourlyRate: 20.0,
        overtimeRate: 30.0,
      );
      dailyEmployee = Employee(
        id: 2,
        name: 'Daily Worker',
        payType: 'daily',
        dailyRate: 100.0,
        overtimeRate: 25.0,
      );
    });

    test('calculates salary correctly for hourly employee with no overtime', () {
      final logs = [
        WorkLog(employeeId: 1, date: DateTime.now(), hoursWorked: 8, overtimeHours: 0),
        WorkLog(employeeId: 1, date: DateTime.now().subtract(const Duration(days: 1)), hoursWorked: 7, overtimeHours: 0),
      ];
      final salary = controller.calculateSalaryForPeriod(hourlyEmployee, logs);
      expect(salary, (8 * 20.0) + (7 * 20.0)); // 160 + 140 = 300
    });

    test('calculates salary correctly for hourly employee with overtime', () {
      final logs = [
        WorkLog(employeeId: 1, date: DateTime.now(), hoursWorked: 8, overtimeHours: 2),
      ];
      final salary = controller.calculateSalaryForPeriod(hourlyEmployee, logs);
      expect(salary, (8 * 20.0) + (2 * 30.0)); // 160 + 60 = 220
    });

    test('calculates salary correctly for daily employee with no overtime', () {
      final logs = [
        WorkLog(employeeId: 2, date: DateTime.now(), workedDay: true, overtimeHours: 0),
        WorkLog(employeeId: 2, date: DateTime.now().subtract(const Duration(days: 1)), workedDay: true, overtimeHours: 0),
        WorkLog(employeeId: 2, date: DateTime.now().subtract(const Duration(days: 2)), workedDay: false, overtimeHours: 0), // Day off
      ];
      final salary = controller.calculateSalaryForPeriod(dailyEmployee, logs);
      expect(salary, (100.0 * 2)); // 200
    });

    test('calculates salary correctly for daily employee with overtime', () {
      final logs = [
        WorkLog(employeeId: 2, date: DateTime.now(), workedDay: true, overtimeHours: 3),
      ];
      final salary = controller.calculateSalaryForPeriod(dailyEmployee, logs);
      expect(salary, 100.0 + (3 * 25.0)); // 100 + 75 = 175
    });

    test('calculates salary as 0 if no relevant logs', () {
      final logs = [
        WorkLog(employeeId: 3, date: DateTime.now(), hoursWorked: 8, overtimeHours: 0), // Different employee ID
      ];
      final salary = controller.calculateSalaryForPeriod(hourlyEmployee, logs);
      expect(salary, 0);
    });

    test('calculates salary as 0 if logs list is empty', () {
      final List<WorkLog> logs = [];
      final salary = controller.calculateSalaryForPeriod(hourlyEmployee, logs);
      expect(salary, 0);
    });
  });
}
