import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/inventory_controller.dart';
import '../models/inventory_item.dart';
import '../widgets/inventory_item_card.dart'; // Re-use the card

class LowStockReportScreen extends StatefulWidget {
  const LowStockReportScreen({Key? key}) : super(key: key);

  @override
  State<LowStockReportScreen> createState() => _LowStockReportScreenState();
}

class _LowStockReportScreenState extends State<LowStockReportScreen> {
  @override
  void initState() {
    super.initState();
    // Data should already be fetched by InventoryListScreen or on controller init.
    // If not, or if a fresh fetch is desired for the report:
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Provider.of<InventoryController>(context, listen: false).fetchInventoryItems();
    // });
  }

  // Placeholder for editing threshold, same as in InventoryListScreen
  void _showEditThresholdDialog(BuildContext context, InventoryItem item) {
    final controller = Provider.of<InventoryController>(context, listen: false);
    final thresholdController = TextEditingController(text: item.threshold.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Edit Threshold for ${item.itemName}'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: thresholdController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'New Threshold'),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Threshold cannot be empty.';
                if (double.tryParse(value) == null) return 'Invalid number.';
                if (double.parse(value) < 0) return 'Threshold cannot be negative.';
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newThreshold = double.parse(thresholdController.text);
                  bool success = await controller.updateItemThreshold(item.itemName, newThreshold);
                  Navigator.of(dialogContext).pop();
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Threshold for ${item.itemName} updated.')),
                    );
                  } else if (!success && mounted && controller.errorMessage != null) {
                     ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${controller.errorMessage}')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Low Stock Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print/Export Report (Placeholder)',
            onPressed: () {
              // TODO: Implement actual print/export functionality (e.g., PDF)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Print/Export functionality not yet implemented.')),
              );
            },
          ),
        ],
      ),
      body: Consumer<InventoryController>(
        builder: (context, controller, child) {
          if (controller.isLoading && controller.lowStockItems.isEmpty && controller.inventoryItems.isEmpty) {
            // Show loading only if everything is empty and loading, otherwise show potentially stale data.
            return const Center(child: CircularProgressIndicator());
          }
          // Ensure items are fetched if not already
          if (controller.inventoryItems.isEmpty && !controller.isLoading && controller.errorMessage == null) {
            controller.fetchInventoryItems(); // Trigger fetch if list is empty
            return const Center(child: Text("Fetching inventory..."));
          }

          if (controller.errorMessage != null) {
            return Center(child: Text('Error: ${controller.errorMessage}'));
          }

          final lowStockItems = controller.lowStockItems;

          if (lowStockItems.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No items are currently below their alert threshold. Well done!',
                  style: TextStyle(fontSize: 16, color: Colors.green),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '${lowStockItems.length} item(s) are currently low on stock:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: lowStockItems.length,
                  itemBuilder: (context, index) {
                    final item = lowStockItems[index];
                    return InventoryItemCard(
                      item: item,
                      onEditThreshold: () => _showEditThresholdDialog(context, item),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
