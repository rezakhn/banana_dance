import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payment.dart';

class PaymentListTile extends StatelessWidget {
  final Payment payment;
  final VoidCallback? onDelete;

  const PaymentListTile({
    Key? key,
    required this.payment,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('${payment.amount.toStringAsFixed(2)} paid on ${DateFormat.yMMMd().format(payment.paymentDate)}'),
      subtitle: payment.paymentMethod != null && payment.paymentMethod!.isNotEmpty
                  ? Text('Method: ${payment.paymentMethod}')
                  : null,
      trailing: onDelete != null ? IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
        tooltip: 'Delete Payment',
        onPressed: onDelete,
      ) : null,
      dense: true,
    );
  }
}
