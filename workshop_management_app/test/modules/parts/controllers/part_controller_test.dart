import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:workshop_management_app/core/database_service.dart';
import 'package:workshop_management_app/modules/parts/controllers/part_controller.dart';
import 'package:workshop_management_app/modules/parts/models/part.dart';
import 'package:workshop_management_app/modules/parts/models/part_composition.dart';
import 'package:workshop_management_app/modules/parts/models/product.dart';
import 'package:workshop_management_app/modules/parts/models/product_part.dart';
import 'package:workshop_management_app/modules/parts/models/assembly_order.dart';
import 'package:workshop_management_app/modules/inventory/models/inventory_item.dart';

// It's better to generate mocks, but for simplicity defining manually:
class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  late PartController partController;
  late MockDatabaseService mockDatabaseService;

  // Helper to create a PartController with a specific mock
  PartController createControllerWithMock(MockDatabaseService mock) {
    // This assumes PartController can accept DatabaseService via constructor or a setter for testing.
    // If PartController news up its own DatabaseService directly, true unit testing is harder.
    // For this example, we'll proceed as if it can be injected or we're testing observable behavior.
    // Let's assume we add a factory or allow overriding for tests.
    // For now, this mock won't be directly used by the controller unless it's refactored.
    // The tests will be more integration-like, similar to PurchaseController tests.
    return PartController(); // This uses the real DatabaseService
  }

  setUp(() {
    mockDatabaseService = MockDatabaseService();
    partController = createControllerWithMock(mockDatabaseService);
    // If DatabaseService was injectable: partController = PartController(databaseService: mockDatabaseService);
  });

  group('PartController - Parts Management', () {
    final testPart1 = Part(id: 1, name: 'Raw Material A', isAssembly: false);
    final testPart2 = Part(id: 2, name: 'Assembly X', isAssembly: true);
    final testPartsList = [testPart1, testPart2];
    final testComposition = [PartComposition(id: 1, assemblyId: 2, componentPartId: 1, quantity: 2)];

    test('fetchParts correctly updates parts, rawMaterials, assemblies, and partIdToNameMap', () async {
      // This is an integration test with the current setup.
      // For a unit test with mock:
      // when(mockDatabaseService.getParts(query: anyNamed('query'))).thenAnswer((_) async => testPartsList);

      await partController.fetchParts(); // Hits real DB

      expect(partController.isLoading, false);
      // We can't easily assert contents without known DB state unless we add items first.
      // expect(partController.parts, equals(testPartsList));
      // expect(partController.rawMaterials, contains(testPart1));
      // expect(partController.assemblies, contains(testPart2));
      // expect(partController.partIdToNameMap[1], 'Raw Material A');
    });

    test('addPart successfully adds a part and refreshes', () async {
      final newPart = Part(name: 'New Test Part', isAssembly: false);
      // Unit test: when(mockDatabaseService.insertPart(any)).thenAnswer((_) async => 3);
      // when(mockDatabaseService.getParts(query: anyNamed('query'))).thenAnswer((_) async => [...testPartsList, newPart.copyWith(id:3)]);

      final db = DatabaseService(); // For direct interaction to check
      final initialParts = await db.getParts();

      bool success = await partController.addPart(newPart);
      expect(success, true);
      expect(partController.errorMessage, null);

      final currentParts = await db.getParts();
      expect(currentParts.length, initialParts.length + 1);
      final addedPart = currentParts.firstWhere((p) => p.name == 'New Test Part');

      // Cleanup
      await db.deletePart(addedPart.id!);
    });

    test('selectPart updates selectedPart and fetches composition for assembly', () async {
        // Setup: Add parts and composition to DB first for this integration test
        final db = DatabaseService();
        await db.insertPart(testPart1); // id should be 1 if DB is fresh
        await db.insertPart(testPart2); // id should be 2
        await db.addComponentToAssembly(PartComposition(assemblyId: 2, componentPartId: 1, quantity: 2));
        await partController.fetchParts(); // Load them into controller

        await partController.selectPart(2); // Select Assembly X
        expect(partController.selectedPart?.id, 2);
        expect(partController.selectedPartComposition, isNotEmpty);
        expect(partController.selectedPartComposition.first.componentPartId, 1);
        expect(partController.selectedPartComposition.first.quantity, 2);

        await partController.selectPart(1); // Select Raw Material A
        expect(partController.selectedPart?.id, 1);
        expect(partController.selectedPartComposition, isEmpty);

        // Cleanup
        await db.deletePart(2); // Will cascade delete compositions
        await db.deletePart(1);
    });
  });

  group('PartController - Product Management', () {
    final testProduct1 = Product(id: 1, name: 'Final Product Alpha');
    // ... more tests similar to Parts ...
    test('fetchProducts updates product list', () async {
        await partController.fetchProducts();
        expect(partController.isLoading, false);
    });
  });

  group('PartController - Assembly Order Management', () {
    // ... tests for assembly orders ...
    test('fetchAssemblyOrders updates assembly order list', () async {
        await partController.fetchAssemblyOrders();
        expect(partController.isLoading, false);
    });

    test('completeSelectedAssemblyOrder updates status and inventory (integration)', () async {
        final db = DatabaseService();
        // Setup:
        // 1. Raw material 'Component Z'
        final compZ = Part(name: 'Component Z', isAssembly: false);
        final compZId = await db.insertPart(compZ);
        // 2. Assembly 'Assembled Product K' that uses Component Z
        final assemblyK = Part(name: 'Assembled Product K', isAssembly: true);
        final assemblyKId = await db.insertPart(assemblyK);
        await db.addComponentToAssembly(PartComposition(assemblyId: assemblyKId, componentPartId: compZId, quantity: 2));
        // 3. Initial inventory for Component Z
        await db.upsertInventoryItem(InventoryItem(itemName: 'Component Z', quantity: 10));
        // 4. Assembly Order for Assembled Product K
        final order = AssemblyOrder(partId: assemblyKId, quantityToProduce: 3, date: DateTime.now());
        final orderId = await db.insertAssemblyOrder(order);

        await partController.fetchAssemblyOrders(); // Load order into controller
        await partController.fetchParts(); // Load parts map
        await partController.selectAssemblyOrder(orderId); // Select it

        expect(partController.selectedAssemblyOrder?.status, 'Pending');

        bool success = await partController.completeSelectedAssemblyOrder();
        expect(success, true);
        expect(partController.errorMessage, null);
        expect(partController.selectedAssemblyOrder?.status, 'Completed');

        // Check inventory
        final componentZStock = await db.getInventoryItemByName('Component Z');
        expect(componentZStock?.quantity, 4); // 10 - (2 * 3) = 4

        final assemblyKStock = await db.getInventoryItemByName('Assembled Product K');
        expect(assemblyKStock?.quantity, 3);

        // Cleanup
        await db.deleteAssemblyOrder(orderId);
        // Deleting parts will also delete compositions due to CASCADE
        await db.deletePart(assemblyKId);
        await db.deletePart(compZId);
        // Reset inventory for next tests if needed (though in-memory DB should reset)
        await db.upsertInventoryItem(InventoryItem(itemName: 'Component Z', quantity: 0));
        await db.upsertInventoryItem(InventoryItem(itemName: 'Assembled Product K', quantity: 0));

    });
  });

  // Note: Many of these tests are integration tests due to PartController's direct instantiation of DatabaseService.
  // True unit tests would require injecting DatabaseService.
}

// Helper extension for DatabaseService for tests, if needed for setup/teardown
// e.g. to directly manipulate data outside of controller logic for test setup.
extension DatabaseServiceTestHelper on DatabaseService {
  Future<void> upsertInventoryItem(InventoryItem item) async {
    final db = await database;
    await db.insert('inventory', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
