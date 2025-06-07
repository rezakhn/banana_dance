import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:workshop_management_app/core/database_service.dart';
import 'package:workshop_management_app/modules/purchases/controllers/purchase_controller.dart';
import 'package:workshop_management_app/modules/purchases/models/supplier.dart';
import 'package:workshop_management_app/modules/purchases/models/purchase_invoice.dart';
import 'package:workshop_management_app/modules/inventory/models/inventory_item.dart'; // Added for cleanup

// Create a mock class for DatabaseService
// If using @GenerateMocks, would run build_runner. For manual, define like this:
class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  late PurchaseController purchaseController;
  // late MockDatabaseService mockDatabaseService; // Will use real DB due to controller design

  setUp(() {
    // mockDatabaseService = MockDatabaseService();
    // Ideally, inject mockDatabaseService into PurchaseController
    purchaseController = PurchaseController();
  });

  group('PurchaseController - Suppliers', () {
    final testSupplier1 = Supplier(id:1, name: 'Test Supplier Alpha', contactInfo: '123-alpha');

    // Test requires a clean database or specific setup/teardown for each test
    // as it interacts with the real database.

    // Clean up any potential leftover suppliers before and after tests in this group
    // This is a simplified cleanup. A real test suite might reset the DB.
    tearDownAll(() async {
      final db = DatabaseService();
      var suppliers = await db.getSuppliers(query: 'Test Supplier Alpha');
      for (var s in suppliers) { await db.deleteSupplier(s.id!); }
       suppliers = await db.getSuppliers(query: 'New Added Supplier');
      for (var s in suppliers) { await db.deleteSupplier(s.id!); }
    });


    test('fetchSuppliers updates suppliers list (integration)', () async {
      // Add a supplier to ensure fetch has something to find
      final tempSupplier = Supplier(name: 'FetchMe Supplier', contactInfo: 'fetch-contact');
      final db = DatabaseService();
      final id = await db.insertSupplier(tempSupplier);

      await purchaseController.fetchSuppliers();

      expect(purchaseController.isLoading, false);
      expect(purchaseController.suppliers.any((s) => s.name == 'FetchMe Supplier'), isTrue, reason: "Fetched suppliers should contain 'FetchMe Supplier'");
      expect(purchaseController.errorMessage, null);

      await db.deleteSupplier(id); // Clean up
    });

    test('addSupplier success scenario (integration)', () async {
      final newSupplier = Supplier(name: 'New Added Supplier', contactInfo: '789-new');
      final db = DatabaseService(); // For verification and cleanup

      final initialSuppliers = await db.getSuppliers();
      final initialCount = initialSuppliers.length;

      bool result = await purchaseController.addSupplier(newSupplier);

      expect(result, true, reason: "addSupplier should return true on success");
      expect(purchaseController.isLoading, false, reason: "isLoading should be false after addSupplier");
      expect(purchaseController.errorMessage, null, reason: "errorMessage should be null on success");

      final suppliersAfterAdd = await db.getSuppliers();
      expect(suppliersAfterAdd.length, initialCount + 1, reason: "Supplier count should increment by 1");
      expect(suppliersAfterAdd.any((s) => s.name == 'New Added Supplier'), true, reason: "The new supplier should be in the database");

      // Clean up: delete the added supplier
      final addedDbSupplier = suppliersAfterAdd.firstWhere((s) => s.name == 'New Added Supplier');
      await db.deleteSupplier(addedDbSupplier.id!);
    });

    test('selectSupplier updates selectedSupplier', () {
      purchaseController.selectSupplier(testSupplier1);
      expect(purchaseController.selectedSupplier?.id, testSupplier1.id);
      expect(purchaseController.selectedSupplier?.name, testSupplier1.name);

      purchaseController.selectSupplier(null);
      expect(purchaseController.selectedSupplier, null);
    });
  });

  group('PurchaseController - Purchase Invoices (Integration)', () {
    late Supplier testSupplier;
    final dbService = DatabaseService();

    setUpAll(() async {
      // Ensure a supplier exists for these tests
      final existingSupplier = await dbService.getSuppliers(query: 'Invoice Test Supplier Main');
      if (existingSupplier.isNotEmpty) {
        testSupplier = existingSupplier.first;
      } else {
         testSupplier = Supplier(name: 'Invoice Test Supplier Main', contactInfo: 'inv-contact-main');
         final id = await dbService.insertSupplier(testSupplier);
         testSupplier = Supplier(id: id, name: testSupplier.name, contactInfo: testSupplier.contactInfo);
      }
    });

    tearDownAll(() async {
      // Clean up the main test supplier and any related invoices/inventory.
      // This is complex due to interdependencies.
      // For now, specific tests will clean up their own created data.
      // A full DB reset between test runs or groups is better.
      final invoices = await dbService.getPurchaseInvoices(supplierId: testSupplier.id);
      for (var inv in invoices) {
        final tempInv = await dbService.getPurchaseInvoiceById(inv.id!);
        if (tempInv != null) {
          for (var item in tempInv.items) {
            // Revert inventory - this assumes _updateInventoryItemQuantityInternal handles negative correctly
            // or we have a dedicated revert/set method.
            // For simplicity, we might just delete the inventory item if it was unique to this test.
            // This part highlights the need for robust test data management.
            final invItem = await dbService.getInventoryItemByName(item.itemName);
            if(invItem != null && invItem.quantity == item.quantity) { // Attempt to only delete if it matches this test's addition
               await dbService.deleteInventoryItemForTest(item.itemName); // Assumed method for test cleanup
            }
          }
        }
        await dbService.deletePurchaseInvoice(inv.id!);
      }
      await dbService.deleteSupplier(testSupplier.id!);
    });

    // Helper method for tests that need to delete inventory items
    // This should ideally be part of DatabaseService or a test utility.
    // Adding it here to make tests runnable, but it's not a clean solution.
    dbService.deleteInventoryItemForTest = (String itemName) async {
        final db = await dbService.database;
        await db.delete('inventory', where: 'item_name = ?', whereArgs: [itemName]);
    };


    test('fetchPurchaseInvoices updates invoices list (integration)', () async {
      final testItem = PurchaseItem(itemName: 'FetchItem', quantity: 1, unitPrice: 1);
      final tempInvoice = PurchaseInvoice(supplierId: testSupplier.id!, date: DateTime.now(), items: [testItem]);
      tempInvoice.calculateTotalAmount();
      final invoiceId = await dbService.insertPurchaseInvoice(tempInvoice);

      await purchaseController.fetchPurchaseInvoices();

      expect(purchaseController.isLoading, false);
      expect(purchaseController.purchaseInvoices.any((inv) => inv.id == invoiceId), isTrue);
      expect(purchaseController.errorMessage, null);

      await dbService.deletePurchaseInvoice(invoiceId); // Cleans up invoice and related inventory via DB service logic
    });

    test('addPurchaseInvoice success scenario (integration)', () async {
      final newItemName = 'AddedItemForInvoiceTest';
      final newInvoice = PurchaseInvoice(supplierId: testSupplier.id!, date: DateTime.now(), items: [
        PurchaseItem(itemName: newItemName, quantity: 5, unitPrice: 2.5)
      ]);
      newInvoice.calculateTotalAmount(); // total = 12.5

      final initialInvoices = await dbService.getPurchaseInvoices();
      final initialInvoiceCount = initialInvoices.length;

      InventoryItem? itemBefore = await dbService.getInventoryItemByName(newItemName);
      final initialItemQty = itemBefore?.quantity ?? 0;

      bool result = await purchaseController.addPurchaseInvoice(newInvoice);

      expect(result, true);
      expect(purchaseController.isLoading, false);
      expect(purchaseController.errorMessage, null);

      final invoicesAfterAdd = await dbService.getPurchaseInvoices();
      expect(invoicesAfterAdd.length, initialInvoiceCount + 1);

      final addedInv = invoicesAfterAdd.firstWhere((inv) => inv.items.any((item) => item.itemName == newItemName));
      expect(addedInv.totalAmount, 12.5);

      InventoryItem? itemAfter = await dbService.getInventoryItemByName(newItemName);
      expect(itemAfter, isNotNull);
      expect(itemAfter!.quantity, initialItemQty + 5);

      // Clean up
      await dbService.deletePurchaseInvoice(addedInv.id!); // This should also revert inventory
      // Verify inventory reverted
      InventoryItem? itemAfterDelete = await dbService.getInventoryItemByName(newItemName);
      if (initialItemQty == 0) { // If item didn't exist before, it should be gone or quantity 0
          expect(itemAfterDelete == null || itemAfterDelete.quantity == 0, isTrue);
           if(itemAfterDelete != null && itemAfterDelete.quantity == 0){ // cleanup if it exists with 0
             await dbService.deleteInventoryItemForTest(newItemName);
           }
      } else {
          expect(itemAfterDelete?.quantity, initialItemQty);
      }
    });
  });
}

// Temporary extension for test cleanup, not for production DatabaseService
extension DatabaseServiceTestExtension on DatabaseService {
  Future<void> deleteInventoryItemForTest(String itemName) async {
    final db = await database;
    await db.delete('inventory', where: 'item_name = ?', whereArgs: [itemName]);
  }
   Future<void> upsertInventoryItem(InventoryItem item) async { // Required by one of the tests
    final db = await database;
    await db.insert('inventory', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
