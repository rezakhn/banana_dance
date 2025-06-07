import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/order_controller.dart';
import '../models/sales_order.dart';
import '../models/customer.dart'; // Required for _getCustomerName
import 'sales_order_edit_screen.dart';
import '../widgets/sales_order_card.dart'; // Added import

class SalesOrderListScreen extends StatefulWidget {
  const SalesOrderListScreen({Key? key}) : super(key: key);

  @override
  State<SalesOrderListScreen> createState() => _SalesOrderListScreenState();
}

class _SalesOrderListScreenState extends State<SalesOrderListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderController>(context, listen: false).fetchSalesOrders();
      Provider.of<OrderController>(context, listen: false).fetchCustomers(); // For customer names
    });
  }

  String _getCustomerName(BuildContext context, int customerId) {
    final controller = Provider.of<OrderController>(context, listen: false);
    try {
      // Ensure customers list is not empty and controller has fetched them.
      if (controller.customers.isEmpty) {
          // This might happen if fetchCustomers hasn't completed or returned empty.
          // Consider calling fetchCustomers again or handling this state.
          // For now, returning ID as fallback.
          // Provider.of<OrderController>(context, listen: false).fetchCustomers(); // Avoid calling fetch in build methods or getters like this
          return 'ID: $customerId';
      }
      return controller.customers.firstWhere((c) => c.id == customerId).name;
    } catch (e) {
      return 'Unknown Customer (ID: $customerId)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SalesOrderEditScreen()),
              ).then((_) => Provider.of<OrderController>(context, listen: false).fetchSalesOrders());
            },
          ),
        ],
      ),
      body: Consumer<OrderController>(
        builder: (context, controller, child) {
          if (controller.isLoading && controller.salesOrders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.errorMessage != null && controller.salesOrders.isEmpty) {
            return Center(child: Text('Error: ${controller.errorMessage}'));
          }
          if (controller.salesOrders.isEmpty) {
            return const Center(child: Text('No sales orders found. Create one!'));
          }

          return ListView.builder(
            itemCount: controller.salesOrders.length,
            itemBuilder: (context, index) {
              final order = controller.salesOrders[index];
              final customerName = _getCustomerName(context, order.customerId);
              return SalesOrderCard(
                order: order,
                customerName: customerName,
                onTap: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SalesOrderEditScreen(salesOrder: order)),
                  ).then((_) => Provider.of<OrderController>(context, listen: false).fetchSalesOrders());
                },
                onDelete: (order.status != 'Completed' && order.status != 'Cancelled') ? () async {
                  final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                          title: Text('Confirm Delete'),
                          content: Text('Are you sure you want to delete Sales Order #${order.id}?'),
                          actions: [
                              TextButton(child: Text('Cancel'), onPressed: ()=>Navigator.pop(ctx, false)),
                              TextButton(child: Text('Delete'), onPressed: ()=>Navigator.pop(ctx, true))
                          ]
                      )
                  );
                  if (confirm == true) {
                    await controller.deleteSalesOrder(order.id!);
                    if (controller.errorMessage != null && mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${controller.errorMessage}')),
                          );
                      }
                  }
                } : null
              );
            },
          );
        },
      ),
    );
  }
}
