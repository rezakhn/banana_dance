import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_management_app/modules/orders/models/customer.dart';
import 'package:workshop_management_app/modules/orders/widgets/customer_card.dart';

void main() {
  // ... tests similar to SupplierCard tests ...
  testWidgets('CustomerCard displays name and contact', (WidgetTester tester) async {
    final customer = Customer(id: 1, name: 'John Doe', contactInfo: 'john@example.com');
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: CustomerCard(customer: customer))));
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('john@example.com'), findsOneWidget);
  });
}
