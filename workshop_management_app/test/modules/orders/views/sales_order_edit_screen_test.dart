import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workshop_management_app/modules/orders/controllers/order_controller.dart';
import 'package:workshop_management_app/modules/parts/controllers/part_controller.dart'; // If needed for product list
import 'package:workshop_management_app/modules/orders/views/sales_order_edit_screen.dart';

void main() {
   Widget buildTestableWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OrderController()),
        ChangeNotifierProvider(create: (_) => PartController()), // For available products
      ],
      child: MaterialApp(home: SalesOrderEditScreen()),
    );
  }
  testWidgets('SalesOrderEditScreen shows customer dropdown and date pickers', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle(); // For async calls in initState like fetching customers/products
    expect(find.widgetWithText(DropdownButtonFormField<int>, 'Select Customer'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Order Date'), findsOneWidget);
    // More tests for adding items, payments, etc.
  });
}
