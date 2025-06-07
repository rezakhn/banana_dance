import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Purchase Module Views
import 'package:workshop_management_app/modules/purchases/views/purchase_invoice_list_screen.dart';
import 'package:workshop_management_app/modules/purchases/views/supplier_list_screen.dart';
// Parts Module Views
import 'package:workshop_management_app/modules/parts/views/part_list_screen.dart';
// Orders Module Views
import 'package:workshop_management_app/modules/orders/views/customer_list_screen.dart';
import 'package:workshop_management_app/modules/orders/views/sales_order_list_screen.dart';
// Inventory Module Views
import 'package:workshop_management_app/modules/inventory/views/inventory_list_screen.dart'; // Added
// Employee Module
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workshop Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt_outlined),
            tooltip: 'Customers',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomerListScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_checkout_outlined),
            tooltip: 'Sales Orders',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SalesOrderListScreen()));
            },
          ),
          const VerticalDivider(width: 1, indent: 10, endIndent: 10),
          IconButton(
            icon: const Icon(Icons.storefront_outlined),
            tooltip: 'Suppliers',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SupplierListScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Purchase Invoices',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PurchaseInvoiceListScreen()));
            },
          ),
          const VerticalDivider(width: 1, indent: 10, endIndent: 10),
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: 'Inventory', // New Inventory Button
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const InventoryListScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.build_circle_outlined),
            tooltip: 'Parts & Assemblies',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PartListScreen()));
            },
          ),
           const VerticalDivider(width: 1, indent: 10, endIndent: 10),
          PopupMenuButton<String>(
            icon: const Icon(Icons.person_outline),
            tooltip: "Employee Actions",
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
      body: Consumer<EmployeeController>(
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
