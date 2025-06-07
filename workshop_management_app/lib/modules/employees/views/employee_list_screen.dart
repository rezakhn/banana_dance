import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workshop_management_app/modules/purchases/views/purchase_invoice_list_screen.dart';
import 'package:workshop_management_app/modules/purchases/views/supplier_list_screen.dart';
import 'package:workshop_management_app/modules/parts/views/part_list_screen.dart'; // Added this line
import '../controllers/employee_controller.dart';
import 'employee_edit_screen.dart';
import 'work_log_calendar_screen.dart';
import '../widgets/employee_card.dart';

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
      // Pre-fetch other controllers' data if needed upon app start, or let their screens do it.
      // Provider.of<PurchaseController>(context, listen: false).fetchSuppliers();
      // Provider.of<PartController>(context, listen: false).fetchParts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workshop Manager'), // Updated title for home
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront_outlined), // Changed icon
            tooltip: 'Suppliers',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SupplierListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined), // Changed icon
            tooltip: 'Purchase Invoices',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PurchaseInvoiceListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.build_circle_outlined),
            tooltip: 'Parts & Assemblies',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PartListScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.person_add_alt_1_outlined), // Changed "Add Employee" to a menu for now
            tooltip: "Add Employee",
            onSelected: (value) {
              if (value == 'add_employee') {
                 Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EmployeeEditScreen(),
                    ),
                  );
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
      ),
      body: Consumer<EmployeeController>( // Body remains Employee list for now
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
                    MaterialPageRoute(
                      builder: (context) => WorkLogCalendarScreen(employee: employee),
                    ),
                  );
                },
              );
            }
          );
        },
      ),
    );
  }
}
