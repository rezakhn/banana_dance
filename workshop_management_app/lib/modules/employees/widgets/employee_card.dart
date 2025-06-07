import 'package:flutter/material.dart';
import '../models/employee.dart';

class EmployeeCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback? onTap;
  final VoidCallback? onEdit; // Optional: if edit button is part of the card
  final VoidCallback? onDelete; // Optional: if delete button is part of the card
  final VoidCallback? onLongPress; // Optional: for other actions like viewing logs

  const EmployeeCard({
    Key? key,
    required this.employee,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        title: Text(employee.name),
        subtitle: Text('Pay Type: ${employee.payType}, OT Rate: ${employee.overtimeRate}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                tooltip: 'Edit Employee',
                onPressed: onEdit,
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                tooltip: 'Delete Employee',
                onPressed: onDelete,
              ),
          ],
        ),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
