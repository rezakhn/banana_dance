import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workshop_management_app/modules/purchases/controllers/purchase_controller.dart';
import 'package:workshop_management_app/modules/purchases/views/supplier_edit_screen.dart';
import 'package:workshop_management_app/modules/purchases/models/supplier.dart';
// No direct mocking of DatabaseService here, but PurchaseController needs to be provided.

void main() {
  // Helper to build the SupplierEditScreen with necessary providers
  Widget buildTestableWidget({Supplier? supplier}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PurchaseController()),
      ],
      child: MaterialApp(
        home: SupplierEditScreen(supplier: supplier),
      ),
    );
  }

  group('SupplierEditScreen Tests', () {
    testWidgets('Displays form fields for adding a new supplier', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());

      expect(find.widgetWithText(TextFormField, 'Supplier Name'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Contact Info (Phone, Email, etc.)'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Add Supplier'), findsOneWidget);
    });

    testWidgets('Displays existing supplier data for editing', (WidgetTester tester) async {
      final existingSupplier = Supplier(id: 1, name: 'Old Supplier', contactInfo: 'old@contact.com');
      await tester.pumpWidget(buildTestableWidget(supplier: existingSupplier));

      expect(find.text('Old Supplier'), findsOneWidget); // InitialValue in TextFormField
      expect(find.text('old@contact.com'), findsOneWidget); // InitialValue
      expect(find.widgetWithText(ElevatedButton, 'Save Changes'), findsOneWidget);
    });

    testWidgets('Shows validation error if supplier name is empty', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());

      // Find the ElevatedButton and tap it to trigger validation
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Supplier'));
      await tester.pump(); // Rebuild the widget after state change (validation messages appear)

      expect(find.text('Please enter a supplier name'), findsOneWidget);
    });

    testWidgets('Contact info can be empty', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());

      await tester.enterText(find.widgetWithText(TextFormField, 'Supplier Name'), 'Test Supplier');
      // Leave contact info empty
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Supplier'));
      await tester.pump();

      // No validation error expected for contact info specifically for emptiness
      // The actual submission would proceed (or fail at controller/db level if other constraints apply)
      // For this widget test, we are primarily concerned with the "Please enter a supplier name" not appearing if name is filled.
      expect(find.text('Please enter a supplier name'), findsNothing);
    });

    // Testing actual submission logic would require mocking PurchaseController's methods
    // or having a more elaborate setup. For now, focus on UI and local validation.
  });
}
