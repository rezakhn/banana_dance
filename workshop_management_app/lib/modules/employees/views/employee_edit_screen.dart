import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/employee_controller.dart';
import '../models/employee.dart';

class EmployeeEditScreen extends StatefulWidget {
  final Employee? employee; // Nullable for adding a new employee

  const EmployeeEditScreen({Key? key, this.employee}) : super(key: key);

  @override
  State<EmployeeEditScreen> createState() => _EmployeeEditScreenState();
}

class _EmployeeEditScreenState extends State<EmployeeEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _payType;
  late double _dailyRate;
  late double _hourlyRate;
  late double _overtimeRate;

  List<String> _payTypes = ['daily', 'hourly'];

  @override
  void initState() {
    super.initState();
    _payType = widget.employee?.payType ?? _payTypes.first;
    _name = widget.employee?.name ?? '';
    _dailyRate = widget.employee?.dailyRate ?? 0.0;
    _hourlyRate = widget.employee?.hourlyRate ?? 0.0;
    _overtimeRate = widget.employee?.overtimeRate ?? 0.0;
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final employeeController = Provider.of<EmployeeController>(context, listen: false);

      final newEmployee = Employee(
        id: widget.employee?.id,
        name: _name,
        payType: _payType,
        dailyRate: _payType == 'daily' ? _dailyRate : 0.0,
        hourlyRate: _payType == 'hourly' ? _hourlyRate : 0.0,
        overtimeRate: _overtimeRate,
      );

      bool success;
      if (widget.employee == null) {
        success = await employeeController.addEmployee(newEmployee);
      } else {
        success = await employeeController.updateEmployee(newEmployee);
      }

      if (success && mounted) {
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(employeeController.errorMessage ?? 'Failed to save employee')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employee == null ? 'Add Employee' : 'Edit Employee'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
                onSaved: (value) => _name = value!,
              ),
              DropdownButtonFormField<String>(
                value: _payType,
                decoration: const InputDecoration(labelText: 'Pay Type'),
                items: _payTypes.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _payType = newValue!;
                  });
                },
                validator: (value) => value == null ? 'Please select a pay type' : null,
              ),
              if (_payType == 'daily')
                TextFormField(
                  initialValue: _dailyRate.toString(),
                  decoration: const InputDecoration(labelText: 'Daily Rate'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || double.tryParse(value) == null || double.parse(value) < 0) {
                      return 'Please enter a valid daily rate';
                    }
                    return null;
                  },
                  onSaved: (value) => _dailyRate = double.parse(value!),
                ),
              if (_payType == 'hourly')
                TextFormField(
                  initialValue: _hourlyRate.toString(),
                  decoration: const InputDecoration(labelText: 'Hourly Rate'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || double.tryParse(value) == null || double.parse(value) < 0) {
                      return 'Please enter a valid hourly rate';
                    }
                    return null;
                  },
                  onSaved: (value) => _hourlyRate = double.parse(value!),
                ),
              TextFormField(
                initialValue: _overtimeRate.toString(),
                decoration: const InputDecoration(labelText: 'Overtime Rate'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || double.tryParse(value) == null || double.parse(value) < 0) {
                    return 'Please enter a valid overtime rate';
                  }
                  return null;
                },
                onSaved: (value) => _overtimeRate = double.parse(value!),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(widget.employee == null ? 'Add Employee' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
