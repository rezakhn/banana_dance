import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workshop_management_app/modules/inventory/controllers/inventory_controller.dart';
import 'package:workshop_management_app/modules/inventory/views/low_stock_report_screen.dart';
import 'package:workshop_management_app/modules/inventory/models/inventory_item.dart';
import 'package:workshop_management_app/modules/inventory/widgets/inventory_item_card.dart';

// Re-use MockInventoryController from inventory_list_screen_test or define here
class MockInventoryControllerForReport extends ChangeNotifier implements InventoryController {
  List<InventoryItem> _items = [];
  List<InventoryItem> _lowStock = [];
  bool _loading = false; String? _error;
  @override List<InventoryItem> get inventoryItems => _items;
  @override List<InventoryItem> get lowStockItems => _lowStock;
  @override bool get isLoading => _loading; @override String? get errorMessage => _error;
  @override Future<void> fetchInventoryItems({String? query}) async {}
  @override Future<bool> updateItemThreshold(String itemName, double newThreshold) async {return true;}
  @override void selectInventoryItem(InventoryItem? item) {}
  @override Future<InventoryItem?> getInventoryItemDetails(String itemName) async {return null;}
  void setTestItems(List<InventoryItem> items) { _items = items; _lowStock = items.where((i) => i.quantity < i.threshold).toList(); notifyListeners(); }
}


void main() {
  late MockInventoryControllerForReport mockController;
  setUp(() => mockController = MockInventoryControllerForReport());

  Widget buildTestableWidget() => ChangeNotifierProvider<InventoryController>.value(
        value: mockController,
        child: MaterialApp(home: LowStockReportScreen()),
      );

  testWidgets('LowStockReportScreen displays only low stock items', (WidgetTester tester) async {
    final itemNormal = InventoryItem(itemName: 'Normal', quantity: 10, threshold: 5);
    final itemLow = InventoryItem(itemName: 'LowItem', quantity: 2, threshold: 5);
    mockController.setTestItems([itemNormal, itemLow]);

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    expect(find.byType(InventoryItemCard), findsOneWidget);
    expect(find.text('LowItem'), findsOneWidget);
    expect(find.text('Normal'), findsNothing);
    expect(find.textContaining('1 item(s) are currently low on stock:'), findsOneWidget);
  });
}
