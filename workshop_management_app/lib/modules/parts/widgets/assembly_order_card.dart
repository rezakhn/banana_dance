import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/assembly_order.dart';

class AssemblyOrderCard extends StatelessWidget {
  final AssemblyOrder order;
  final String assemblyName; // To display the name of the part being assembled
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onLongPress;


  const AssemblyOrderCard({
    Key? key,
    required this.order,
    required this.assemblyName,
    this.onTap,
    this.onDelete,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color statusColor = Colors.orange;
    if (order.status == 'Completed') {
      statusColor = Colors.green;
    } else if (order.status == 'In Progress') {
      statusColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        title: Text('Assemble: $assemblyName (Order ID: ${order.id})'),
        subtitle: Text(
          'Qty: ${order.quantityToProduce} | Date: ${DateFormat.yMMMd().format(order.date)}\nStatus: ${order.status}',
          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
        ),
        isThreeLine: true,
        trailing: onDelete != null && order.status != 'Completed' ? IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          tooltip: 'Delete Order',
          onPressed: onDelete,
        ) : null,
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
