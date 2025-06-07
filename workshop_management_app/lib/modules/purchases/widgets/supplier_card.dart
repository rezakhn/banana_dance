import 'package:flutter/material.dart';
import '../models/supplier.dart';

class SupplierCard extends StatelessWidget {
  final Supplier supplier;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const SupplierCard({
    Key? key,
    required this.supplier,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        title: Text(supplier.name),
        subtitle: Text(supplier.contactInfo.isNotEmpty ? supplier.contactInfo : 'No contact info'),
        trailing: onDelete != null ? IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          tooltip: 'Delete Supplier',
          onPressed: onDelete,
        ) : null,
        onTap: onTap,
      ),
    );
  }
}
