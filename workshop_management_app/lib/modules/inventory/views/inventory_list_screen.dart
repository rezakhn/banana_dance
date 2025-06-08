import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workshop_management_app/shared/widgets/main_layout_scaffold.dart';
import '../controllers/inventory_controller.dart';
import '../models/inventory_item.dart';
import '../widgets/inventory_item_card.dart';

enum InventoryFilter { all, lowStock }

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({Key? key}) : super(key: key);

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  InventoryFilter _currentFilter = InventoryFilter.all;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryController>(context, listen: false).fetchInventoryItems();
    });
  }

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
    final Widget screenBody = Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search by item name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: Consumer<InventoryController>(
              builder: (context, controller, child) {
                if (controller.isLoading && controller.inventoryItems.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.errorMessage != null && controller.inventoryItems.isEmpty) {
                  return Center(child: Text('Error: ${controller.errorMessage}'));
                }

                List<InventoryItem> itemsToDisplay = controller.inventoryItems;
                if (_currentFilter == InventoryFilter.lowStock) {
                  itemsToDisplay = controller.lowStockItems;
                }

                if (_searchQuery.isNotEmpty) {
                    itemsToDisplay = itemsToDisplay.where((item) {
                        return item.itemName.toLowerCase().contains(_searchQuery);
                    }).toList();
                }

                if (itemsToDisplay.isEmpty) {
                  return Center(
                    child: Text(_currentFilter == InventoryFilter.lowStock
                                ? 'No items are currently low on stock.'
                                : _searchQuery.isNotEmpty
                                    ? 'No items match your search.'
                                    : 'Inventory is empty or no items match filter.'),
                  );
                }

                return ListView.builder(
                  itemCount: itemsToDisplay.length,
                  itemBuilder: (context, index) {
                    final item = itemsToDisplay[index];
                    return InventoryItemCard(
                      item: item,
                      onEditThreshold: () => _showEditThresholdDialog(context, item),
                    );
                  },
                );
              },
            ),
          ),
        ],
      );

    return MainLayoutScaffold(
      title: 'Inventory Status',
      appBarActions: [
        PopupMenuButton<InventoryFilter>(
          initialValue: _currentFilter,
          onSelected: (InventoryFilter filter) {
            setState(() {
              _currentFilter = filter;
            });
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<InventoryFilter>>[
            const PopupMenuItem<InventoryFilter>(
              value: InventoryFilter.all,
              child: Text('Show All Items'),
            ),
            const PopupMenuItem<InventoryFilter>(
              value: InventoryFilter.lowStock,
              child: Text('Show Low Stock Only'),
            ),
          ],
          icon: const Icon(Icons.filter_list),
        ),
      ],
      body: screenBody,
    );
  }
}
