import 'package:flutter/material.dart';
import '../models/inventory_item.dart';

class InventoryItemCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback? onEditThreshold;

  const InventoryItemCard({
    Key? key,
    required this.item,
    this.onEditThreshold,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isLowStock = item.quantity < item.threshold;
    final Color? tileColor = isLowStock ? Colors.red.withOpacity(0.1) : null;
    final Color? textColor = isLowStock ? Colors.red.shade700 : null;
    final FontWeight titleFontWeight = isLowStock ? FontWeight.bold : FontWeight.normal;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      color: tileColor, // Apply subtle background if low stock
      child: ListTile(
        title: Text(
          item.itemName,
          style: TextStyle(color: textColor, fontWeight: titleFontWeight),
        ),
        subtitle: Text(
          'In Stock: ${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 2)} (Threshold: ${item.threshold.toStringAsFixed(item.threshold % 1 == 0 ? 0 : 2)})',
          style: TextStyle(color: textColor),
        ),
        trailing: onEditThreshold != null ? IconButton(
          icon: Icon(Icons.edit_notifications_outlined, color: Theme.of(context).primaryColor), // More specific icon
          tooltip: 'Edit Alert Threshold',
          onPressed: onEditThreshold,
        ) : null,
      ),
    );
  }
}
