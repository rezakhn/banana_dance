import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_management_app/modules/purchases/models/supplier.dart';
import 'package:workshop_management_app/modules/purchases/widgets/supplier_card.dart';

void main() {
  final testSupplier = Supplier(id: 1, name: 'Test Supplier Alpha', contactInfo: 'alpha@example.com');
  final testSupplierNoContact = Supplier(id: 2, name: 'Test Supplier Beta');

  Widget buildTestableWidget(Supplier supplier, {VoidCallback? onTap, VoidCallback? onDelete}) {
    return MaterialApp(
      home: Scaffold(
        body: SupplierCard(
          supplier: supplier,
          onTap: onTap,
          onDelete: onDelete,
        ),
      ),
    );
  }

  testWidgets('SupplierCard displays name and contact info', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget(testSupplier));

    expect(find.text('Test Supplier Alpha'), findsOneWidget);
    expect(find.text('alpha@example.com'), findsOneWidget);
  });

  testWidgets('SupplierCard displays default text for no contact info', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget(testSupplierNoContact));

    expect(find.text('Test Supplier Beta'), findsOneWidget);
    expect(find.text('No contact info'), findsOneWidget);
  });

  testWidgets('SupplierCard calls onTap when tapped', (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(buildTestableWidget(testSupplier, onTap: () {
      tapped = true;
    }));

    await tester.tap(find.byType(SupplierCard));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('SupplierCard calls onDelete when delete icon is tapped', (WidgetTester tester) async {
    bool deleted = false;
    await tester.pumpWidget(buildTestableWidget(testSupplier, onDelete: () {
      deleted = true;
    }));

    // Ensure the delete icon is present
    expect(find.byIcon(Icons.delete), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pump();

    expect(deleted, isTrue);
  });

  testWidgets('SupplierCard does not show delete icon if onDelete is null', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget(testSupplier, onDelete: null));
    expect(find.byIcon(Icons.delete), findsNothing);
  });
}
