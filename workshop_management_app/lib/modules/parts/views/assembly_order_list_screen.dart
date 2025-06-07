import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/part_controller.dart';
import '../models/assembly_order.dart';
import 'assembly_order_edit_screen.dart';
import 'assembly_order_process_screen.dart';
import '../widgets/assembly_order_card.dart'; // Added import

class AssemblyOrderListScreen extends StatefulWidget {
  const AssemblyOrderListScreen({Key? key}) : super(key: key);

  @override
  State<AssemblyOrderListScreen> createState() => _AssemblyOrderListScreenState();
}

class _AssemblyOrderListScreenState extends State<AssemblyOrderListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PartController>(context, listen: false).fetchAssemblyOrders();
      Provider.of<PartController>(context, listen: false).fetchParts(); // For part names
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assembly Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AssemblyOrderEditScreen()),
              ).then((_) => Provider.of<PartController>(context, listen: false).fetchAssemblyOrders()); // Refresh list after add/edit
            },
          ),
        ],
      ),
      body: Consumer<PartController>(
        builder: (context, controller, child) {
          if (controller.isLoading && controller.assemblyOrders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.errorMessage != null && controller.assemblyOrders.isEmpty) {
            return Center(child: Text('Error: ${controller.errorMessage}'));
          }
          if (controller.assemblyOrders.isEmpty) {
            return const Center(child: Text('No assembly orders. Create one!'));
          }
          return ListView.builder(
            itemCount: controller.assemblyOrders.length,
            itemBuilder: (context, index) {
              final order = controller.assemblyOrders[index];
              final partName = controller.partIdToNameMap[order.partId] ?? 'Unknown Assembly';
              return AssemblyOrderCard(
                order: order,
                assemblyName: partName,
                onTap: () {
                  controller.selectAssemblyOrder(order.id!);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AssemblyOrderProcessScreen(orderId: order.id!)),
                  ).then((_) => Provider.of<PartController>(context, listen: false).fetchAssemblyOrders());
                },
                onDelete: order.status != 'Completed' ? () async {
                    final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                            title: const Text('Confirm Delete'),
                            content: Text('Are you sure you want to delete Assembly Order ID ${order.id} for "$partName"?'),
                            actions: [
                                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                            ],
                        ),
                    );
                    if (confirm == true) {
                        await controller.deleteAssemblyOrder(order.id!);
                         if (controller.errorMessage != null && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: ${controller.errorMessage}')),
                            );
                        }
                    }
                } : null,
                onLongPress: order.status != 'Completed' ? () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AssemblyOrderEditScreen(order: order)),
                    ).then((_) => Provider.of<PartController>(context, listen: false).fetchAssemblyOrders());
                } : null,
              );
            },
          );
        },
      ),
    );
  }
}
