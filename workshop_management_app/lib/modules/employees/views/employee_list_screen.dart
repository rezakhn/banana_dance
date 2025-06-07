import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workshop_management_app/modules/purchases/views/purchase_invoice_list_screen.dart'; // Added
import 'package:workshop_management_app/modules/purchases/views/supplier_list_screen.dart'; // Added
import '../controllers/employee_controller.dart';
// import '../models/employee.dart'; // Not directly used here anymore after card
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees'),
        actions: [
          IconButton(
            icon: const Icon(Icons.store),
            tooltip: 'Suppliers',
            onPressed: () {
              // Ensure PurchaseController's suppliers are loaded before navigating if needed immediately by SupplierListScreen
              // Provider.of<PurchaseController>(context, listen: false).fetchSuppliers();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SupplierListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Purchase Invoices',
            onPressed: () {
              // Ensure PurchaseController's invoices are loaded
              // Provider.of<PurchaseController>(context, listen: false).fetchPurchaseInvoices();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PurchaseInvoiceListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline), // Changed icon for differentiation
            tooltip: 'Add Employee',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmployeeEditScreen(),
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
          if (controller.errorMessage != null && controller.employees.isEmpty) { // Check if empty before showing error
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
                  controller.selectEmployee(employee); // Select before navigating
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
                   controller.selectEmployee(employee); // Select before navigating
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
