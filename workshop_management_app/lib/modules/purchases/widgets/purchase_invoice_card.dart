import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/purchase_invoice.dart';

class PurchaseInvoiceCard extends StatelessWidget {
  final PurchaseInvoice invoice;
  final String supplierName; // Display supplier name directly
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const PurchaseInvoiceCard({
    Key? key,
    required this.invoice,
    required this.supplierName,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        title: Text('Invoice ID: ${invoice.id} - ${supplierName}'),
        subtitle: Text('Date: ${DateFormat.yMMMd().format(invoice.date)} - Items: ${invoice.items.length} - Total: ${invoice.totalAmount.toStringAsFixed(2)}'),
        trailing: onDelete != null ? IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          tooltip: 'Delete Invoice',
          onPressed: onDelete,
        ) : null,
        onTap: onTap,
      ),
    );
  }
}
