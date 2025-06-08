import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Shared Widgets
// import 'package:workshop_management_app/shared/widgets/app_drawer.dart'; // No longer directly needed here
import 'package:workshop_management_app/shared/widgets/main_layout_scaffold.dart'; // Added
// Employee Module
import '../controllers/employee_controller.dart';
import 'employee_edit_screen.dart';
import 'work_log_calendar_screen.dart';
import '../widgets/employee_card.dart';

// Other module screen imports are no longer needed here for AppBar navigation

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({Key? key}) : super(key: key);

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EmployeeController>(context, listen: false).fetchEmployees();
    });
  }

  @override
  Widget build(BuildContext context) {
    // The body of the scaffold remains the same
    final Widget screenBody = Consumer<EmployeeController>(
      builder: (context, controller, child) {
        if (controller.isLoading && controller.employees.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage != null && controller.employees.isEmpty) {
          return Center(child: Text('Error: ${controller.errorMessage}'));
        }
        if (controller.employees.isEmpty) {
          return const Center(child: Text('No employees found. Add one via the menu.'));
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
                  MaterialPageRoute(builder: (context) => EmployeeEditScreen(employee: employee)),
                ).then((_) {
                    Provider.of<EmployeeController>(context, listen: false).fetchEmployees();
                });
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
                  if (confirm == true && mounted) {
                    bool deleted = await controller.deleteEmployee(employee.id!);
                      if (!deleted && mounted && controller.errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(controller.errorMessage!)));
                      }
                  }
              },
              onLongPress: () {
                  controller.selectEmployee(employee);
                  Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WorkLogCalendarScreen(employee: employee)),
                );
              },
            );
          }
        );
      },
    );

    return MainLayoutScaffold(
      title: 'Employees', // Title for the AppBar
      appBarActions: [ // Actions specific to this screen
        PopupMenuButton<String>(
          icon: const Icon(Icons.person_add_alt_1_outlined),
          tooltip: "Add Employee",
          onSelected: (value) {
            if (value == 'add_employee') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EmployeeEditScreen()),
                ).then((_) {
                  Provider.of<EmployeeController>(context, listen: false).fetchEmployees();
                });
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'add_employee',
              child: Text('Add Employee'),
            ),
          ],
        ),
      ],
      body: screenBody, // The main content
    );
  }
}
