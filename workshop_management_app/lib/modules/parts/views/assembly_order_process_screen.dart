import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/part_controller.dart';
import '../models/assembly_order.dart';
import '../models/part_composition.dart';
import '../../inventory/models/inventory_item.dart'; // For displaying stock

class AssemblyOrderProcessScreen extends StatefulWidget {
  final int orderId;

  const AssemblyOrderProcessScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<AssemblyOrderProcessScreen> createState() => _AssemblyOrderProcessScreenState();
}

class _AssemblyOrderProcessScreenState extends State<AssemblyOrderProcessScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PartController>(context, listen: false).selectAssemblyOrder(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Process Assembly Order'),
      ),
      body: Consumer<PartController>(
        builder: (context, controller, child) {
          final order = controller.selectedAssemblyOrder;

          if (controller.isLoading && order == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (order == null) {
            return Center(child: Text(controller.errorMessage ?? 'Order not found or could not be loaded.'));
          }

          final partToAssemble = controller.partIdToNameMap[order.partId] ?? 'Unknown Assembly';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order ID: ${order.id}', style: Theme.of(context).textTheme.titleMedium),
                Text('Assemble: $partToAssemble (ID: ${order.partId})'),
                Text('Quantity to Produce: ${order.quantityToProduce}'),
                Text('Status: ${order.status}', style: TextStyle(fontWeight: FontWeight.bold, color: order.status == 'Completed' ? Colors.green : Colors.orange)),
                const SizedBox(height: 20),
                Text('Required Components:', style: Theme.of(context).textTheme.titleMedium),
                Expanded(
                  child: FutureBuilder<List<PartComposition>>(
                    future: controller.getComponentsForAssembly(order.partId), // Direct call for simplicity here
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text('No components defined for this assembly or error loading them.');
                      }
                      final compositions = snapshot.data!;
                      return ListView.builder(
                        itemCount: compositions.length,
                        itemBuilder: (context, index) {
                          final comp = compositions[index];
                          final compName = controller.partIdToNameMap[comp.componentPartId] ?? 'Unknown';
                          final requiredQty = comp.quantity * order.quantityToProduce;
                          // Find current stock from controller.requiredComponentsStock
                          final stockItem = controller.requiredComponentsStock.firstWhere(
                              (s) => s.itemName == compName,
                              orElse: () => InventoryItem(itemName: compName, quantity: 0)
                          );
                          final hasEnoughStock = stockItem.quantity >= requiredQty;

                          return ListTile(
                            title: Text('$compName (ID: ${comp.componentPartId})'),
                            subtitle: Text('Required: $requiredQty, In Stock: ${stockItem.quantity}'),
                            trailing: Icon(
                                hasEnoughStock ? Icons.check_circle_outline : Icons.error_outline,
                                color: hasEnoughStock ? Colors.green : Colors.red,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                if (order.status != 'Completed')
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () async {
                      bool success = await controller.completeSelectedAssemblyOrder();
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assembly order completed! Inventory updated.')));
                        // UI should update due to controller notifying listeners
                      } else if (mounted && controller.errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${controller.errorMessage}')));
                      }
                    },
                    child: const Text('Mark as Completed & Update Inventory'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
