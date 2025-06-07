import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workshop_management_app/modules/inventory/controllers/inventory_controller.dart';
import 'package:workshop_management_app/modules/inventory/views/inventory_list_screen.dart';
import 'package:workshop_management_app/modules/inventory/models/inventory_item.dart';
import 'package:workshop_management_app/modules/inventory/widgets/inventory_item_card.dart';

// Mock controller for specific scenarios
class MockInventoryController extends ChangeNotifier implements InventoryController {
  List<InventoryItem> _items = [];
  List<InventoryItem> _lowStock = [];
  bool _loading = false;
  String? _error;

  @override List<InventoryItem> get inventoryItems => _items;
  @override List<InventoryItem> get lowStockItems => _lowStock;
  @override bool get isLoading => _loading;
  @override String? get errorMessage => _error;

  // Other methods would need mocks if called by UI directly and we want to test those interactions.
  // For this test, we focus on what the UI consumes.
  @override Future<void> fetchInventoryItems({String? query}) async { /* Mock behavior */ }
  @override Future<bool> updateItemThreshold(String itemName, double newThreshold) async {return true;}
  // Add other method overrides if needed by UI interaction tests
  @override void selectInventoryItem(InventoryItem? item) {}
  @override Future<InventoryItem?> getInventoryItemDetails(String itemName) async {return null;}


  // Test setup methods
  void setTestItems(List<InventoryItem> items) { _items = items; _lowStock = items.where((i) => i.quantity < i.threshold).toList(); notifyListeners(); }
  void setLoading(bool val) { _loading = val; notifyListeners(); }
  void setError(String? err) { _error = err; notifyListeners(); }
}


void main() {
  late MockInventoryController mockController;

  setUp(() {
    mockController = MockInventoryController();
  });

  Widget buildTestableWidget() {
    return ChangeNotifierProvider<InventoryController>.value(
      value: mockController,
      child: MaterialApp(home: InventoryListScreen()),
    );
  }

  final itemA = InventoryItem(itemName: 'Item A', quantity: 10, threshold: 5);
  final itemB_low = InventoryItem(itemName: 'Item B', quantity: 3, threshold: 5);

  testWidgets('InventoryListScreen displays items from controller', (WidgetTester tester) async {
    mockController.setTestItems([itemA, itemB_low]);
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle(); // For any controller notifications

    expect(find.byType(InventoryItemCard), findsNWidgets(2));
    expect(find.text('Item A'), findsOneWidget);
    expect(find.text('Item B'), findsOneWidget);
  });

  testWidgets('InventoryListScreen filter for Low Stock works', (WidgetTester tester) async {
    mockController.setTestItems([itemA, itemB_low]);
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Initial: shows 2 items
    expect(find.byType(InventoryItemCard), findsNWidgets(2));

    // Tap filter button
    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle(); // For menu to appear

    // Tap "Show Low Stock Only"
    await tester.tap(find.text('Show Low Stock Only'));
    await tester.pumpAndSettle(); // For UI to update based on filter

    // Now should only show Item B (the low stock one)
    expect(find.byType(InventoryItemCard), findsOneWidget);
    expect(find.text('Item B'), findsOneWidget);
    expect(find.text('Item A'), findsNothing);
  });

  testWidgets('InventoryListScreen search functionality filters items', (WidgetTester tester) async {
    mockController.setTestItems([itemA, itemB_low, InventoryItem(itemName: 'Another One', quantity: 1, threshold: 2)]);
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    expect(find.byType(InventoryItemCard), findsNWidgets(3));

    await tester.enterText(find.byType(TextField), 'Item'); // Search for "Item"
    await tester.pumpAndSettle();

    expect(find.byType(InventoryItemCard), findsNWidgets(2)); // Item A, Item B
    expect(find.text('Another One'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Another');
    await tester.pumpAndSettle();
    expect(find.byType(InventoryItemCard), findsOneWidget); // Another One
  });

  testWidgets('InventoryListScreen shows edit threshold dialog', (WidgetTester tester) async {
    mockController.setTestItems([itemA]);
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_notifications_outlined));
    await tester.pumpAndSettle(); // Dialog appears

    expect(find.widgetWithText(AlertDialog, 'Edit Threshold for Item A'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'New Threshold'), findsOneWidget);
  });
}
