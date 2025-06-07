import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:workshop_management_app/modules/orders/models/payment.dart';
import 'package:workshop_management_app/modules/orders/widgets/payment_list_tile.dart';

void main() {
  testWidgets('PaymentListTile displays amount, date, and method', (WidgetTester tester) async {
    final payment = Payment(id: 1, orderId: 1, amount: 50.75, paymentDate: DateTime(2023,11,15), paymentMethod: 'Card');
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: PaymentListTile(payment: payment))));
    expect(find.textContaining('50.75 paid on Nov 15, 2023'), findsOneWidget);
    expect(find.text('Method: Card'), findsOneWidget);
  });
}
