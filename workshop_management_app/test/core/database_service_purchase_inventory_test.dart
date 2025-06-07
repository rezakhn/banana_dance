import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // For in-memory testing on host
import 'package:workshop_management_app/core/database_service.dart';
import 'package:workshop_management_app/modules/purchases/models/supplier.dart';
import 'package:workshop_management_app/modules/purchases/models/purchase_invoice.dart';
import 'package:workshop_management_app/modules/inventory/models/inventory_item.dart';

// Initialize FFI for sqflite if running on host (non-Flutter environment)
void sqfliteTestInit() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

void main() {
  // Call this at the beginning of your test main function
  sqfliteTestInit();

  late DatabaseService dbService;
  late Database db; // For direct checks

  setUp(() async {
    // Open an in-memory database for each test
    dbService = DatabaseService();
    // Ensure a fresh DB for each test by using a unique path or deleting if exists
    // For in-memory, just re-instantiating DatabaseService should get a fresh one if it closes DB properly
    // Or, explicitly open an in-memory database
    db = await openDatabase(inMemoryDatabasePath, version: 1,
        onCreate: (db, version) async {
      // Manually call _createDB from DatabaseService to set up schema
      // This is a bit of a workaround. Ideally, DatabaseService would allow passing a DB factory or path.
      // For now, we replicate the _createDB logic or make it accessible for tests.
      // Let's assume DatabaseService()._createDB is callable or schema is known.
      // Replicating create table statements for clarity in test:
      await db.execute('''
        CREATE TABLE suppliers(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, contact_info TEXT)
      ''');
      await db.execute('''
        CREATE TABLE purchase_invoices(id INTEGER PRIMARY KEY AUTOINCREMENT, supplier_id INTEGER NOT NULL, date TEXT NOT NULL, total_amount REAL NOT NULL, FOREIGN KEY (supplier_id) REFERENCES suppliers (id) ON DELETE RESTRICT)
      ''');
      await db.execute('''
        CREATE TABLE purchase_items(id INTEGER PRIMARY KEY AUTOINCREMENT, invoice_id INTEGER NOT NULL, item_name TEXT NOT NULL, quantity REAL NOT NULL, unit_price REAL NOT NULL, total_price REAL NOT NULL, FOREIGN KEY (invoice_id) REFERENCES purchase_invoices (id) ON DELETE CASCADE)
      ''');
      await db.execute('''
        CREATE TABLE inventory(item_name TEXT PRIMARY KEY, quantity REAL NOT NULL DEFAULT 0, threshold REAL NOT NULL DEFAULT 0)
      ''');
       // Add other tables if they become relevant for these tests (e.g. employees, work_logs if some cross-dependency appears)
    });
    // Replace the DatabaseService's internal database with this in-memory one.
    // This requires DatabaseService to be designed to allow this, e.g., by a setter or test-specific constructor.
    // Since current DatabaseService creates its own DB, we'll re-initialize dbService and it will use the factory.
    dbService = DatabaseService(); // This will now use the in-memory factory

    // Pre-insert a supplier for use in tests
    await dbService.insertSupplier(Supplier(name: 'Test Supplier For Inventory', contactInfo: '123-inv'));
  });

  tearDown(() async {
    await dbService.close(); // Close the in-memory database
  });

  Future<InventoryItem?> getInventoryDirectly(String itemName) async {
    final List<Map<String, dynamic>> maps = await dbService.database.then((db) => db.query('inventory', where: 'item_name = ?', whereArgs: [itemName]));
    if (maps.isNotEmpty) {
      return InventoryItem.fromMap(maps.first);
    }
    return null;
  }

  final supplier = Supplier(id: 1, name: 'Test Supplier For Inventory', contactInfo: '123-inv');


  test('insertPurchaseInvoice correctly increases inventory', () async {
    final invoice = PurchaseInvoice(
      supplierId: supplier.id!, // Assuming supplier with ID 1 exists
      date: DateTime.now(),
      items: [
        PurchaseItem(itemName: 'Apples', quantity: 10, unitPrice: 1.0),
        PurchaseItem(itemName: 'Bananas', quantity: 5, unitPrice: 0.5),
      ],
    );

    await dbService.insertPurchaseInvoice(invoice);

    final apples = await getInventoryDirectly('Apples');
    expect(apples, isNotNull);
    expect(apples!.quantity, 10);

    final bananas = await getInventoryDirectly('Bananas');
    expect(bananas, isNotNull);
    expect(bananas!.quantity, 5);

    // Purchase again to check accumulation
    final invoice2 = PurchaseInvoice(
      supplierId: supplier.id!,
      date: DateTime.now(),
      items: [
        PurchaseItem(itemName: 'Apples', quantity: 7, unitPrice: 1.0),
      ],
    );
    await dbService.insertPurchaseInvoice(invoice2);
    final applesAfter = await getInventoryDirectly('Apples');
    expect(applesAfter!.quantity, 17); // 10 + 7
  });

  test('updatePurchaseInvoice correctly adjusts inventory', () async {
    // Initial purchase
    final initialInvoice = PurchaseInvoice(
      supplierId: supplier.id!,
      date: DateTime.now(),
      items: [
        PurchaseItem(itemName: 'GadgetA', quantity: 3, unitPrice: 100), // GadgetA: 3
        PurchaseItem(itemName: 'WidgetB', quantity: 2, unitPrice: 50),  // WidgetB: 2
      ],
    );
    final invoiceId = await dbService.insertPurchaseInvoice(initialInvoice);

    // Update: Change GadgetA qty, remove WidgetB, add GizmoC
    final updatedInvoice = PurchaseInvoice(
      id: invoiceId, // Essential for update
      supplierId: supplier.id!,
      date: DateTime.now(),
      items: [
        PurchaseItem(itemName: 'GadgetA', quantity: 5, unitPrice: 100), // GadgetA: 3 -> 5 (net +2)
        PurchaseItem(itemName: 'GizmoC', quantity: 1, unitPrice: 200),  // GizmoC: new +1
      ],
    );
    await dbService.updatePurchaseInvoice(updatedInvoice);

    final gadgetA = await getInventoryDirectly('GadgetA');
    expect(gadgetA, isNotNull);
    expect(gadgetA!.quantity, 5); // Should be 5 (was 3, updated to 5)

    final widgetB = await getInventoryDirectly('WidgetB');
    expect(widgetB, isNotNull); // It was created, then its quantity should be reverted
    expect(widgetB!.quantity, 0); // Was 2, removed from invoice, so 2-2=0

    final gizmoC = await getInventoryDirectly('GizmoC');
    expect(gizmoC, isNotNull);
    expect(gizmoC!.quantity, 1); // New item
  });

  test('updatePurchaseInvoice correctly handles item quantity decrease', () async {
    final initialInvoice = PurchaseInvoice(
      supplierId: supplier.id!,
      date: DateTime.now(),
      items: [PurchaseItem(itemName: 'CoolItem', quantity: 10, unitPrice: 10)],
    );
    final invoiceId = await dbService.insertPurchaseInvoice(initialInvoice);
    var coolItem = await getInventoryDirectly('CoolItem');
    expect(coolItem!.quantity, 10);

    final updatedInvoice = PurchaseInvoice(
      id: invoiceId,
      supplierId: supplier.id!,
      date: DateTime.now(),
      items: [PurchaseItem(itemName: 'CoolItem', quantity: 4, unitPrice: 10)], // 10 -> 4 (net -6)
    );
    await dbService.updatePurchaseInvoice(updatedInvoice);
    coolItem = await getInventoryDirectly('CoolItem');
    expect(coolItem!.quantity, 4);
  });


  test('deletePurchaseInvoice correctly decreases inventory', () async {
    final invoice = PurchaseInvoice(
      supplierId: supplier.id!,
      date: DateTime.now(),
      items: [
        PurchaseItem(itemName: 'Oranges', quantity: 20, unitPrice: 0.8),
        PurchaseItem(itemName: 'Pears', quantity: 15, unitPrice: 0.9),
      ],
    );
    final invoiceId = await dbService.insertPurchaseInvoice(invoice);

    // Verify initial inventory
    var oranges = await getInventoryDirectly('Oranges');
    expect(oranges!.quantity, 20);
    var pears = await getInventoryDirectly('Pears');
    expect(pears!.quantity, 15);

    await dbService.deletePurchaseInvoice(invoiceId);

    oranges = await getInventoryDirectly('Oranges');
    expect(oranges, isNotNull); // Item should still exist in inventory table
    expect(oranges!.quantity, 0); // Quantity reverted

    pears = await getInventoryDirectly('Pears');
    expect(pears, isNotNull);
    expect(pears!.quantity, 0);
  });

  test('Inventory updates correctly with multiple invoices and items', () async {
    final invoiceA = PurchaseInvoice(supplierId: supplier.id!, date: DateTime.now(), items: [
      PurchaseItem(itemName: 'ItemOne', quantity: 5, unitPrice: 1),
      PurchaseItem(itemName: 'ItemTwo', quantity: 10, unitPrice: 2),
    ]);
    await dbService.insertPurchaseInvoice(invoiceA);

    final invoiceB = PurchaseInvoice(supplierId: supplier.id!, date: DateTime.now(), items: [
      PurchaseItem(itemName: 'ItemOne', quantity: 3, unitPrice: 1), // More ItemOne
      PurchaseItem(itemName: 'ItemThree', quantity: 7, unitPrice: 3),
    ]);
    final invoiceBId = await dbService.insertPurchaseInvoice(invoiceB);

    var itemOne = await getInventoryDirectly('ItemOne');
    expect(itemOne!.quantity, 8); // 5 + 3

    var itemTwo = await getInventoryDirectly('ItemTwo');
    expect(itemTwo!.quantity, 10);

    var itemThree = await getInventoryDirectly('ItemThree');
    expect(itemThree!.quantity, 7);

    // Update invoice B - remove ItemOne, change ItemThree quantity
    final updatedInvoiceB = PurchaseInvoice(id: invoiceBId, supplierId: supplier.id!, date: DateTime.now(), items: [
      PurchaseItem(itemName: 'ItemThree', quantity: 4, unitPrice: 3), // 7 -> 4 (net -3 for ItemThree from this invoice)
    ]);
    await dbService.updatePurchaseInvoice(updatedInvoiceB);

    itemOne = await getInventoryDirectly('ItemOne');
    // ItemOne was 5 from invoiceA, and 3 from invoiceB. InvoiceB removed its 3. So 5 should remain.
    expect(itemOne!.quantity, 5);

    itemThree = await getInventoryDirectly('ItemThree');
    // ItemThree was 7 from invoiceB. Updated to 4. So 4 should remain.
    expect(itemThree!.quantity, 4);
  });

}
