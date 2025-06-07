class Employee {
  final int? id;
  final String name;
  final String payType; // "daily" or "hourly"
  final double dailyRate;
  final double hourlyRate;
  final double overtimeRate;

  Employee({
    this.id,
    required this.name,
    required this.payType,
    this.dailyRate = 0.0,
    this.hourlyRate = 0.0,
    required this.overtimeRate,
  }) : assert(payType == 'daily' || payType == 'hourly', 'payType must be "daily" or "hourly"');

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'pay_type': payType,
      'daily_rate': dailyRate,
      'hourly_rate': hourlyRate,
      'overtime_rate': overtimeRate,
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'],
      name: map['name'],
      payType: map['pay_type'],
      dailyRate: map['daily_rate'],
      hourlyRate: map['hourly_rate'],
      overtimeRate: map['overtime_rate'],
    );
  }
}

class WorkLog {
  final int? id;
  final int employeeId;
  final DateTime date;
  final double hoursWorked; // Only applicable if payType is "hourly"
  final bool workedDay; // Only applicable if payType is "daily" (1 for worked, 0 for not)
  final double overtimeHours;

  WorkLog({
    this.id,
    required this.employeeId,
    required this.date,
    this.hoursWorked = 0.0,
    this.workedDay = false,
    this.overtimeHours = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'date': date.toIso8601String().substring(0, 10), // Store date as YYYY-MM-DD
      'hours_worked': hoursWorked,
      'worked_day': workedDay ? 1 : 0,
      'overtime_hours': overtimeHours,
    };
  }

  factory WorkLog.fromMap(Map<String, dynamic> map) {
    return WorkLog(
      id: map['id'],
      employeeId: map['employee_id'],
      date: DateTime.parse(map['date']),
      hoursWorked: map['hours_worked'],
      workedDay: map['worked_day'] == 1,
      overtimeHours: map['overtime_hours'],
    );
  }
}
