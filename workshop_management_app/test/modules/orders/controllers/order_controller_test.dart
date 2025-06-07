import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:workshop_management_app/core/database_service.dart';
import 'package:workshop_management_app/modules/orders/controllers/order_controller.dart';
import 'package:workshop_management_app/modules/orders/models/customer.dart';
import 'package:workshop_management_app/modules/orders/models/sales_order.dart';
import 'package:workshop_management_app/modules/orders/models/order_item.dart';
import 'package:workshop_management_app/modules/orders/models/payment.dart';
import 'package:workshop_management_app/modules/parts/models/product.dart';
import 'package:workshop_management_app/modules/parts/models/part.dart';
import 'package:workshop_management_app/modules/parts/models/product_part.dart';
import 'package:workshop_management_app/modules/inventory/models/inventory_item.dart';

// Manual mock for DatabaseService (replace with generated mock if using build_runner)
class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  late OrderController orderController;
  late MockDatabaseService mockDatabaseService;

  // As OrderController news up its own DatabaseService, these tests are more integration-focused.
  // For true unit tests, DatabaseService should be injectable.
  // We will test controller logic where possible and state changes.
  setUp(() {
    mockDatabaseService = MockDatabaseService(); // This mock isn't used by controller directly
    orderController = OrderController(); // Uses real DatabaseService
  });

  group('OrderController - Customer Management', () {
    final testCustomer = Customer(id: 1, name: 'Test Cust', contactInfo: '123-456');

    test('fetchCustomers updates list and loading state', () async {
      // Integration style: relies on real DB
      await orderController.fetchCustomers();
      expect(orderController.isLoading, false);
      // Cannot assert specific content without known DB state or seeding.
    });

    test('addCustomer successfully adds and refreshes', () async {
      final newCust = Customer(name: 'New Customer Inc.');
      final db = DatabaseService();
      final initialCount = (await db.getCustomers()).length;

      bool success = await orderController.addCustomer(newCust);
      expect(success, true);
      expect(orderController.errorMessage, null);
      expect((await db.getCustomers()).length, initialCount + 1);

      // Cleanup
      final added = (await db.getCustomers()).firstWhere((c) => c.name == 'New Customer Inc.');
      await db.deleteCustomer(added.id!);
    });
  });

  group('OrderController - Sales Order Management', () {
    // Requires setup of customers, products for meaningful tests
    late Customer testCust;
    late Product testProdA;
    late Product testProdB;
    final db = DatabaseService(); // For setup/teardown

    setUp(() async {
      testCust = Customer(name: 'Order Test Cust');
      final custId = await db.insertCustomer(testCust);
      testCust = Customer(id: custId, name: testCust.name, contactInfo: testCust.contactInfo);

      testProdA = Product(name: 'Product A for Order');
      final prodAId = await db.insertProduct(testProdA);
      testProdA = Product(id: prodAId, name: testProdA.name);

      testProdB = Product(name: 'Product B for Order');
      final prodBId = await db.insertProduct(testProdB);
      testProdB = Product(id: prodBId, name: testProdB.name);

      // Assume Product A is made of Part X (a component)
      final partX = Part(name: 'Part X for Prod A', isAssembly: false);
      final partXId = await db.insertPart(partX);
      await db.setProductParts(prodAId, [ProductPart(productId: prodAId, partId: partXId, quantity: 1)]);
      await db.upsertInventoryItem(InventoryItem(itemName: 'Part X for Prod A', quantity: 10));


      await orderController.fetchAvailableProducts(); // Load products into controller
      await orderController.fetchCustomers(); // Load customers
    });

    tearDown(() async {
        // Clean up sales orders, then products, then customers, then parts, then inventory
        // Simplified: this should be more robust in a real test suite
        final orders = await db.getSalesOrders();
        for (var o in orders) { await db.deleteSalesOrder(o.id!); }
        await db.deleteProduct(testProdA.id!);
        await db.deleteProduct(testProdB.id!);
        await db.deleteCustomer(testCust.id!);
        final partXQuery = await db.getParts(query: 'Part X for Prod A');
        if (partXQuery.isNotEmpty) {
            await db.deletePart(partXQuery.first.id!);
        }
        await db.upsertInventoryItem(InventoryItem(itemName: 'Part X for Prod A', quantity: 0));
    });


    test('addSalesOrder successfully adds an order and refreshes', () async {
      final newOrder = SalesOrder(
        customerId: testCust.id!,
        orderDate: DateTime.now(),
        items: [
          OrderItem(orderId: 0, productId: testProdA.id!, quantity: 2, priceAtSale: 10.0),
          OrderItem(orderId: 0, productId: testProdB.id!, quantity: 1, priceAtSale: 25.0),
        ]
      );
      final initialOrderCount = (await db.getSalesOrders()).length;

      bool success = await orderController.addSalesOrder(newOrder);
      expect(success, true);
      expect(orderController.errorMessage, null);
      expect((await db.getSalesOrders()).length, initialOrderCount + 1);
    });

    test('checkStockForSelectedOrder correctly identifies shortages', () async {
      // Product A needs 1 Part X. Inventory of Part X is 10.
      final order = SalesOrder(
        customerId: testCust.id!,
        orderDate: DateTime.now(),
        items: [OrderItem(orderId: 0, productId: testProdA.id!, quantity: 12, priceAtSale: 10)] // Need 12 Part X
      );
      final orderId = await db.insertSalesOrder(order);

      await orderController.selectSalesOrder(orderId); // This loads the order
      await orderController.checkStockForSelectedOrder();

      expect(orderController.itemShortages.isNotEmpty, true);
      expect(orderController.itemShortages['Part X for Prod A'], 2); // 12 needed - 10 available = 2 short
    });

    test('completeSelectedSalesOrder updates status and inventory', () async {
      // Product A needs 1 Part X. Inventory of Part X is 10.
      final order = SalesOrder(
        customerId: testCust.id!,
        orderDate: DateTime.now(),
        items: [OrderItem(orderId: 0, productId: testProdA.id!, quantity: 3, priceAtSale: 10)] // Need 3 Part X
      );
      final orderId = await db.insertSalesOrder(order);

      await orderController.selectSalesOrder(orderId);
      bool success = await orderController.completeSelectedSalesOrder(orderId, false);

      expect(success, true);
      expect(orderController.selectedSalesOrder?.status, 'Completed');

      final partXStock = await db.getInventoryItemByName('Part X for Prod A');
      expect(partXStock?.quantity, 7); // 10 - 3 = 7
    });
  });
}

// Helper extension for DatabaseService for tests, if needed for setup/teardown
// This allows calling a method that might not be on the main class or is specific to testing
extension DatabaseServiceTestHelperOrder on DatabaseService {
  Future<void> upsertInventoryItem(InventoryItem item) async {
    final db = await database;
    await db.insert('inventory', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
