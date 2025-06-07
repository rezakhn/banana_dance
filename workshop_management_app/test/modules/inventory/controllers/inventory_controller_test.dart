import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:workshop_management_app/core/database_service.dart';
import 'package:workshop_management_app/modules/inventory/controllers/inventory_controller.dart';
import 'package:workshop_management_app/modules/inventory/models/inventory_item.dart';

// Manual mock for DatabaseService
class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  late InventoryController inventoryController;
  late MockDatabaseService mockDatabaseService;

  // For true unit tests, InventoryController should allow DatabaseService injection.
  // These tests will be integration-style due to current controller design.
  setUp(() {
    mockDatabaseService = MockDatabaseService(); // Mock not directly used by controller unless refactored
    inventoryController = InventoryController(); // Uses real DatabaseService
  });

  final itemA_normal = InventoryItem(itemName: 'Item A', quantity: 10, threshold: 5);
  final itemB_low = InventoryItem(itemName: 'Item B', quantity: 3, threshold: 5);
  final itemC_normal_zero_thresh = InventoryItem(itemName: 'Item C', quantity: 5, threshold: 0);
  final itemD_low_high_thresh = InventoryItem(itemName: 'Item D', quantity: 9, threshold: 10);
  final allItems = [itemA_normal, itemB_low, itemC_normal_zero_thresh, itemD_low_high_thresh];

  group('InventoryController Tests', () {
    // These tests will interact with the actual database.
    // Ensure DB is in a known state or cleared before these tests.
    // For proper unit tests, DatabaseService would be mocked and injected.

    setUp(() async {
      // Clear and seed database for each test in this group for predictability
      final db = DatabaseService();
      final currentItems = await db.getAllInventoryItems();
      for (var item in currentItems) {
        // A bit hacky: set quantity to 0 then let upsert fix it or add delete method
        await db.manuallyAdjustInventoryItemQuantity(item.itemName, 0);
        // Ideally, a deleteInventoryItem method would be better.
      }
      // A more direct way to clear:
      // await (await db.database).delete('inventory');

      for (var item in allItems) {
        await db.manuallyAdjustInventoryItemQuantity(item.itemName, item.quantity, newThreshold: item.threshold);
      }
    });

    tearDownAll(() async {
        // Clean up DB after all tests in this group
        final db = DatabaseService();
        final currentItems = await db.getAllInventoryItems();
        for (var item in currentItems) {
            await db.manuallyAdjustInventoryItemQuantity(item.itemName, 0, newThreshold: 0); // Reset quantities and thresholds
        }
    });


    test('fetchInventoryItems populates inventoryItems and lowStockItems', () async {
      await inventoryController.fetchInventoryItems();

      expect(inventoryController.isLoading, false);
      expect(inventoryController.inventoryItems.length, greaterThanOrEqualTo(allItems.length)); // Check if seeded items are there
      expect(inventoryController.inventoryItems.any((i) => i.itemName == 'Item A'), isTrue);

      expect(inventoryController.lowStockItems.any((i) => i.itemName == 'Item B'), isTrue);
      expect(inventoryController.lowStockItems.any((i) => i.itemName == 'Item D'), isTrue);
      expect(inventoryController.lowStockItems.length, 2);
    });

    test('_filterLowStockItems correctly filters', () async {
      // Test this internal logic directly (by setting items manually)
      // inventoryController.inventoryItems.clear(); // Use the list inside controller
      // inventoryController.inventoryItems.addAll(allItems);
      // inventoryController.lowStockItems.clear(); // Clear previous

      await inventoryController.fetchInventoryItems(); // This calls _filterLowStockItems internally after fetch

      expect(inventoryController.lowStockItems.length, 2);
      expect(inventoryController.lowStockItems.any((item) => item.itemName == 'Item B'), isTrue);
      expect(inventoryController.lowStockItems.any((item) => item.itemName == 'Item D'), isTrue);
      expect(inventoryController.lowStockItems.any((item) => item.itemName == 'Item A'), isFalse);
    });

    test('updateItemThreshold updates threshold and re-filters low stock items', () async {
      await inventoryController.fetchInventoryItems(); // Initial fetch & filter
      expect(inventoryController.lowStockItems.any((i) => i.itemName == 'Item A'), isFalse);

      // Update threshold of Item A to make it low stock (10 qty, old thresh 5, new thresh 12)
      bool success = await inventoryController.updateItemThreshold('Item A', 12);
      expect(success, true);

      // Verify Item A is now in lowStockItems
      expect(inventoryController.lowStockItems.any((i) => i.itemName == 'Item A'), isTrue);
      final updatedItemA = inventoryController.inventoryItems.firstWhere((i) => i.itemName == 'Item A');
      expect(updatedItemA.threshold, 12);
    });
  });
}

// Helper extension for DatabaseService for tests, if needed for setup/teardown
// This allows calling a method that might not be on the main class or is specific to testing
extension DatabaseServiceTestHelperInventory on DatabaseService {
  Future<void> upsertInventoryItem(InventoryItem item) async { // Renamed to avoid conflict if already defined
    final db = await database;
    await db.insert('inventory', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
