import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sales_order.dart';

class SalesOrderCard extends StatelessWidget {
  final SalesOrder order;
  final String customerName; // To display customer name directly
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const SalesOrderCard({
    Key? key,
    required this.order,
    required this.customerName,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color statusColor = Colors.orange; // Default for Pending/Other
    if (order.status == 'Completed') statusColor = Colors.green;
    if (order.status == 'Cancelled') statusColor = Colors.red;
    if (order.status == 'Confirmed' || order.status == 'Awaiting Payment' || order.status == 'Awaiting Delivery') statusColor = Colors.blue;


    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        title: Text('Order #${order.id} - $customerName'),
        subtitle: Text(
          'Date: ${DateFormat.yMMMd().format(order.orderDate)} - Items: ${order.items.length}\nTotal: ${order.totalAmount.toStringAsFixed(2)} - Status: ${order.status}',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        isThreeLine: true, // To accommodate two lines in subtitle
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(order.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
            if (onDelete != null && order.status != 'Completed' && order.status != 'Cancelled') // Can't delete completed/cancelled orders from list view easily
              SizedBox(
                height: 24, // Limit height of IconButton for better alignment
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  tooltip: 'Delete Order',
                  onPressed: onDelete,
                ),
              )
            else SizedBox(height: 24), // Placeholder for alignment
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
