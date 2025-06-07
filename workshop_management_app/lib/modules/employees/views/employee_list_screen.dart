import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/employee_controller.dart';
import '../models/employee.dart';
import '../widgets/employee_card.dart';
import 'employee_edit_screen.dart'; // Will create this next
import 'work_log_calendar_screen.dart'; // Will create this later

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({Key? key}) : super(key: key);

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch employees when the screen is initialized
    // Ensure EmployeeController is available via Provider in the widget tree above this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EmployeeController>(context, listen: false).fetchEmployees();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmployeeEditScreen(), // Navigate to add new employee
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<EmployeeController>(
        builder: (context, controller, child) {
          if (controller.isLoading && controller.employees.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.errorMessage != null) {
            return Center(child: Text('Error: ${controller.errorMessage}'));
          }
          if (controller.employees.isEmpty) {
            return const Center(child: Text('No employees found. Add one!'));
          }

          return ListView.builder(
            itemCount: controller.employees.length,
            itemBuilder: (context, index) {
              final employee = controller.employees[index];
              return EmployeeCard(
                employee: employee,
                onTap: () {
                  controller.selectEmployee(employee);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EmployeeEditScreen(employee: employee),
                    ),
                  );
                },
                onDelete: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm Delete'),
                      content: Text('Are you sure you want to delete ${employee.name}?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await controller.deleteEmployee(employee.id!);
                  }
                },
                onLongPress: () {
                   controller.selectEmployee(employee);
                   Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WorkLogCalendarScreen(employee: employee),
                    ),
                  );
                },
                // The onEdit on the card itself can be used if we want an edit icon directly on the card
                // For now, onTap handles navigation to the edit screen.
                // onEdit: () {
                //   controller.selectEmployee(employee);
                //   Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //       builder: (context) => EmployeeEditScreen(employee: employee),
                //     ),
                //   );
                // }
              );
            },
          );
        },
      ),
    );
  }
}
