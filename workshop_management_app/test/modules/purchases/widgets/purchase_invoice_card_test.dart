import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:workshop_management_app/modules/purchases/models/purchase_invoice.dart';
import 'package:workshop_management_app/modules/purchases/widgets/purchase_invoice_card.dart';

void main() {
  final testDate = DateTime(2023, 10, 26);
  final testInvoice = PurchaseInvoice(
    id: 101,
    supplierId: 1, // Not used directly by card, supplierName is passed
    date: testDate,
    items: [
      PurchaseItem(itemName: 'Item X', quantity: 2, unitPrice: 50), // 100
      PurchaseItem(itemName: 'Item Y', quantity: 1, unitPrice: 25), // 25
    ],
  );
  testInvoice.calculateTotalAmount(); // Total should be 125.0

  Widget buildTestableWidget(PurchaseInvoice invoice, {String supplierName = 'Default Supplier', VoidCallback? onTap, VoidCallback? onDelete}) {
    return MaterialApp(
      home: Scaffold(
        body: PurchaseInvoiceCard(
          invoice: invoice,
          supplierName: supplierName,
          onTap: onTap,
          onDelete: onDelete,
        ),
      ),
    );
  }

  testWidgets('PurchaseInvoiceCard displays invoice ID, supplier name, date, items count and total', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget(testInvoice, supplierName: 'Specific Supplier'));

    expect(find.textContaining('Invoice ID: 101'), findsOneWidget);
    expect(find.textContaining('Specific Supplier'), findsOneWidget);
    expect(find.textContaining('Date: ${DateFormat.yMMMd().format(testDate)}'), findsOneWidget);
    expect(find.textContaining('Items: 2'), findsOneWidget);
    expect(find.textContaining('Total: 125.00'), findsOneWidget);
  });

  testWidgets('PurchaseInvoiceCard calls onTap when tapped', (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(buildTestableWidget(testInvoice, onTap: () {
      tapped = true;
    }));

    await tester.tap(find.byType(PurchaseInvoiceCard));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('PurchaseInvoiceCard calls onDelete when delete icon is tapped', (WidgetTester tester) async {
    bool deleted = false;
    await tester.pumpWidget(buildTestableWidget(testInvoice, onDelete: () {
      deleted = true;
    }));

    expect(find.byIcon(Icons.delete), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pump();

    expect(deleted, isTrue);
  });

  testWidgets('PurchaseInvoiceCard does not show delete icon if onDelete is null', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget(testInvoice, onDelete: null));
    expect(find.byIcon(Icons.delete), findsNothing);
  });
}
