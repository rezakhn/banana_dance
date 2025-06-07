import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/order_controller.dart';
import '../models/customer.dart';
import 'customer_edit_screen.dart';
import '../widgets/customer_card.dart'; // Added import

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({Key? key}) : super(key: key);

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderController>(context, listen: false).fetchCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CustomerEditScreen()),
              ).then((_) => Provider.of<OrderController>(context, listen: false).fetchCustomers());
            },
          ),
        ],
      ),
      body: Consumer<OrderController>(
        builder: (context, controller, child) {
          if (controller.isLoading && controller.customers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.errorMessage != null && controller.customers.isEmpty) {
            return Center(child: Text('Error: ${controller.errorMessage}'));
          }
          if (controller.customers.isEmpty) {
            return const Center(child: Text('No customers found. Add one!'));
          }

          return ListView.builder(
            itemCount: controller.customers.length,
            itemBuilder: (context, index) {
              final customer = controller.customers[index];
              return CustomerCard(
                customer: customer,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CustomerEditScreen(customer: customer)),
                  ).then((_) => Provider.of<OrderController>(context, listen: false).fetchCustomers());
                },
                onDelete: () async {
                  final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                          title: Text('Confirm Delete'),
                          content: Text('Are you sure you want to delete ${customer.name}? This might fail if they have associated orders.'),
                          actions: [
                              TextButton(child: Text('Cancel'), onPressed: ()=>Navigator.pop(ctx, false)),
                              TextButton(child: Text('Delete'), onPressed: ()=>Navigator.pop(ctx, true))
                          ]
                      )
                  );
                  if (confirm == true) {
                    await controller.deleteCustomer(customer.id!);
                    if (controller.errorMessage != null && mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${controller.errorMessage}')),
                          );
                      }
                  }
                }
              );
            },
          );
        },
      ),
    );
  }
}
