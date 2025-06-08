class EmployeePerformanceData {
  final int employeeId;
  final String employeeName;
  final int totalDaysWorked;       // Applicable for daily-paid employees
  final double totalHoursWorked;    // Applicable for hourly-paid, regular hours
  final double totalOvertimeHours;  // Applicable for all
  final double totalSalaryPaid;     // Calculated for the period
  final int workLogEntryCount;     // Number of distinct work log entries

  EmployeePerformanceData({
    required this.employeeId,
    required this.employeeName,
    this.totalDaysWorked = 0,
    this.totalHoursWorked = 0.0,
    this.totalOvertimeHours = 0.0,
    required this.totalSalaryPaid,
    this.workLogEntryCount = 0,
  });

  @override
  String toString() {
    return 'EmployeePerformanceData(employee: $employeeName, daysWorked: $totalDaysWorked, hoursWorked: $totalHoursWorked, overtime: $totalOvertimeHours, salary: $totalSalaryPaid, entries: $workLogEntryCount)';
  }
}
