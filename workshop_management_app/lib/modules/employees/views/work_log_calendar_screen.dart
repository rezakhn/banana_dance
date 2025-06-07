import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/employee_controller.dart';
import '../models/employee.dart';
import '../models/employee.dart' show WorkLog; // Explicitly import WorkLog
// We'll need a calendar package later, e.g., table_calendar
// import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // For date formatting

class WorkLogCalendarScreen extends StatefulWidget {
  final Employee employee;

  const WorkLogCalendarScreen({Key? key, required this.employee}) : super(key: key);

  @override
  State<WorkLogCalendarScreen> createState() => _WorkLogCalendarScreenState();
}

class _WorkLogCalendarScreenState extends State<WorkLogCalendarScreen> {
  // CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<WorkLog>> _workLogsByDate = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // Fetch work logs for the selected employee
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<EmployeeController>(context, listen: false);
      controller.selectEmployee(widget.employee); // Ensure employee is selected
      controller.fetchWorkLogsForSelectedEmployee().then((_) {
         _groupWorkLogsByDate(controller.workLogs);
      });
    });
  }

  void _groupWorkLogsByDate(List<WorkLog> logs) {
    _workLogsByDate = {};
    for (var log in logs) {
      final date = DateTime(log.date.year, log.date.month, log.date.day); // Normalize to day
      if (_workLogsByDate[date] == null) {
        _workLogsByDate[date] = [];
      }
      _workLogsByDate[date]!.add(log);
    }
    setState(() {});
  }

  List<WorkLog> _getLogsForDay(DateTime day) {
    return _workLogsByDate[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  void _showAddEditWorkLogDialog({WorkLog? workLog, DateTime? selectedDate}) async {
    final EmployeeController controller = Provider.of<EmployeeController>(context, listen: false);
    WorkLog? result = await showDialog<WorkLog?>(
      context: context,
      builder: (BuildContext context) {
        return AddEditWorkLogDialog(
          workLog: workLog,
          employee: widget.employee,
          selectedDate: workLog?.date ?? selectedDate ?? _selectedDay ?? DateTime.now()
        );
      },
    );

    if (result != null) {
      if (workLog == null) { // Adding new log
        await controller.addWorkLog(result);
      } else { // Editing existing log
        await controller.updateWorkLog(result);
      }
      _groupWorkLogsByDate(controller.workLogs); // Refresh grouped logs
    }
  }


  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<EmployeeController>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Work Logs for ${widget.employee.name}'),
      ),
      body: Column(
        children: [
          // Placeholder for TableCalendar - will integrate properly later
          // For now, just showing a message.
          // Consider adding table_calendar: ^3.0.0 to pubspec.yaml
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Calendar View (using table_calendar) will be here.",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Text("Selected Day: ${DateFormat.yMMMd().format(_selectedDay ?? DateTime.now())}"),
           ElevatedButton(
            onPressed: () => _onDaySelected(DateTime.now(), DateTime.now()), // Example: select today
            child: Text("Focus Today (Example)"),
          ),
          // Display logs for selected day
          Expanded(
            child: controller.isLoading && controller.workLogs.isEmpty
                ? Center(child: CircularProgressIndicator())
                : _getLogsForDay(_selectedDay ?? DateTime.now()).isEmpty
                    ? Center(child: Text('No work logs for this day.'))
                    : ListView.builder(
                        itemCount: _getLogsForDay(_selectedDay ?? DateTime.now()).length,
                        itemBuilder: (context, index) {
                          final log = _getLogsForDay(_selectedDay ?? DateTime.now())[index];
                          return ListTile(
                            title: Text(widget.employee.payType == 'daily'
                                ? (log.workedDay ? 'Worked Day' : 'Day Off')
                                : 'Hours: ${log.hoursWorked}'),
                            subtitle: Text('Overtime: ${log.overtimeHours} hrs'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () => _showAddEditWorkLogDialog(workLog: log),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () async {
                                    await controller.deleteWorkLog(log.id!);
                                    _groupWorkLogsByDate(controller.workLogs);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditWorkLogDialog(selectedDate: _selectedDay),
        child: const Icon(Icons.add),
        tooltip: 'Add Work Log',
      ),
    );
  }
  // Helper for table_calendar, can be removed if not using it or placed in utils
  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) {
      return false;
    }
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}


class AddEditWorkLogDialog extends StatefulWidget {
  final WorkLog? workLog;
  final Employee employee;
  final DateTime selectedDate;

  const AddEditWorkLogDialog({
    Key? key,
    this.workLog,
    required this.employee,
    required this.selectedDate,
  }) : super(key: key);

  @override
  _AddEditWorkLogDialogState createState() => _AddEditWorkLogDialogState();
}

class _AddEditWorkLogDialogState extends State<AddEditWorkLogDialog> {
  final _formKey = GlobalKey<FormState>();
  late double _hoursWorked;
  late bool _workedDay;
  late double _overtimeHours;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _date = widget.workLog?.date ?? widget.selectedDate;
    _hoursWorked = widget.workLog?.hoursWorked ?? 0.0;
    _workedDay = widget.workLog?.workedDay ?? false;
    _overtimeHours = widget.workLog?.overtimeHours ?? 0.0;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newLog = WorkLog(
        id: widget.workLog?.id,
        employeeId: widget.employee.id!,
        date: _date,
        hoursWorked: widget.employee.payType == 'hourly' ? _hoursWorked : 0.0,
        workedDay: widget.employee.payType == 'daily' ? _workedDay : false,
        overtimeHours: _overtimeHours,
      );
      Navigator.of(context).pop(newLog);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.workLog == null ? 'Add Work Log' : 'Edit Work Log'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: Text("Date: ${DateFormat.yMMMd().format(_date)}"),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              if (widget.employee.payType == 'hourly')
                TextFormField(
                  initialValue: _hoursWorked.toString(),
                  decoration: const InputDecoration(labelText: 'Hours Worked'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || double.tryParse(value) == null || double.parse(value) < 0) {
                      return 'Please enter valid hours';
                    }
                    return null;
                  },
                  onSaved: (value) => _hoursWorked = double.parse(value!),
                ),
              if (widget.employee.payType == 'daily')
                SwitchListTile(
                  title: const Text('Worked Day'),
                  value: _workedDay,
                  onChanged: (bool value) {
                    setState(() {
                      _workedDay = value;
                    });
                  },
                ),
              TextFormField(
                initialValue: _overtimeHours.toString(),
                decoration: const InputDecoration(labelText: 'Overtime Hours'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || double.tryParse(value) == null || double.parse(value) < 0) {
                    return 'Please enter valid overtime hours';
                  }
                  return null;
                },
                onSaved: (value) => _overtimeHours = double.parse(value!),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(widget.workLog == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
