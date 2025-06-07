import 'package:flutter/material.dart';
import '../models/customer.dart';

class CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const CustomerCard({
    Key? key,
    required this.customer,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        title: Text(customer.name),
        subtitle: Text(customer.contactInfo.isNotEmpty ? customer.contactInfo : 'No contact info'),
        trailing: onDelete != null ? IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          tooltip: 'Delete Customer',
          onPressed: onDelete,
        ) : null,
        onTap: onTap,
      ),
    );
  }
}
