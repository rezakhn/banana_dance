import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:workshop_management_app/modules/orders/models/sales_order.dart';
import 'package:workshop_management_app/modules/orders/widgets/sales_order_card.dart';

void main() {
  // ... tests similar to PurchaseInvoiceCard ...
  testWidgets('SalesOrderCard displays details', (WidgetTester tester) async {
    final order = SalesOrder(id: 1, customerId: 1, orderDate: DateTime.now(), totalAmount: 100, status: 'Pending', items: []);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SalesOrderCard(order: order, customerName: 'Jane Doe'))));
    expect(find.textContaining('Order #1 - Jane Doe'), findsOneWidget);
    expect(find.textContaining('Total: 100.00'), findsOneWidget);
    expect(find.textContaining('Status: Pending'), findsOneWidget);
  });
}
