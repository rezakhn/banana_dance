import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_management_app/modules/inventory/models/inventory_item.dart';
import 'package:workshop_management_app/modules/inventory/widgets/inventory_item_card.dart';

void main() {
  final normalItem = InventoryItem(itemName: 'Normal Item', quantity: 10, threshold: 5);
  final lowStockItem = InventoryItem(itemName: 'Low Stock Item', quantity: 2, threshold: 5);

  Widget buildTestableWidget(InventoryItem item, {VoidCallback? onEditThreshold}) {
    return MaterialApp(home: Scaffold(body: InventoryItemCard(item: item, onEditThreshold: onEditThreshold)));
  }

  testWidgets('InventoryItemCard displays name, quantity, and threshold', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget(normalItem));
    expect(find.text('Normal Item'), findsOneWidget);
    expect(find.textContaining('In Stock: 10 (Threshold: 5)'), findsOneWidget);
  });

  testWidgets('InventoryItemCard highlights low stock item', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget(lowStockItem));
    // Check for red text color or bold font weight (specifics depend on card's implementation)
    final title = tester.widget<Text>(find.text('Low Stock Item'));
    expect(title.style?.color, Colors.red.shade700);
    expect(title.style?.fontWeight, FontWeight.bold);

    final card = tester.widget<Card>(find.byType(Card));
    expect(card.color, Colors.red.withOpacity(0.1));
  });

  testWidgets('InventoryItemCard calls onEditThreshold', (WidgetTester tester) async {
    bool called = false;
    await tester.pumpWidget(buildTestableWidget(normalItem, onEditThreshold: () => called = true));
    expect(find.byIcon(Icons.edit_notifications_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.edit_notifications_outlined));
    expect(called, isTrue);
  });
}
