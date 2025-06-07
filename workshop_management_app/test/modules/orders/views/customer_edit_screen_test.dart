import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workshop_management_app/modules/orders/controllers/order_controller.dart';
import 'package:workshop_management_app/modules/orders/views/customer_edit_screen.dart';

void main() {
  Widget buildTestableWidget() => ChangeNotifierProvider(
        create: (_) => OrderController(),
        child: MaterialApp(home: CustomerEditScreen()),
      );
  testWidgets('CustomerEditScreen shows name and contact fields', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget());
    expect(find.widgetWithText(TextFormField, 'Customer Name'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Contact Info'), findsOneWidget);
  });
}
