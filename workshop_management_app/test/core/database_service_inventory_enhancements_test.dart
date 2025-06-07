import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:workshop_management_app/core/database_service.dart';
import 'package:workshop_management_app/modules/inventory/models/inventory_item.dart';

void sqfliteTestInit() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

void main() {
  sqfliteTestInit();
  late DatabaseService dbService;

  setUp(() async {
    dbService = DatabaseService();
    // Use in-memory database, ensure schema is created
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath, options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await db.execute('PRAGMA foreign_keys = ON'); // Important
        await db.execute("CREATE TABLE inventory(item_name TEXT PRIMARY KEY, quantity REAL NOT NULL DEFAULT 0, threshold REAL NOT NULL DEFAULT 0)");
        // Add other tables from the main _createDB if they become relevant for these tests by foreign key or other dependencies.
        // For this test, only inventory is strictly needed, but including others won't hurt if schema is consistent.
        await db.execute("CREATE TABLE employees(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, pay_type TEXT NOT NULL CHECK(pay_type IN ('daily', 'hourly')), daily_rate REAL, hourly_rate REAL, overtime_rate REAL NOT NULL)");
        await db.execute("CREATE TABLE work_logs(id INTEGER PRIMARY KEY AUTOINCREMENT, employee_id INTEGER NOT NULL, date TEXT NOT NULL, hours_worked REAL, worked_day INTEGER, overtime_hours REAL, FOREIGN KEY (employee_id) REFERENCES employees (id) ON DELETE CASCADE)");
        await db.execute("CREATE TABLE suppliers(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, contact_info TEXT)");
        await db.execute("CREATE TABLE purchase_invoices(id INTEGER PRIMARY KEY AUTOINCREMENT, supplier_id INTEGER NOT NULL, date TEXT NOT NULL, total_amount REAL NOT NULL, FOREIGN KEY (supplier_id) REFERENCES suppliers (id) ON DELETE RESTRICT)");
        await db.execute("CREATE TABLE purchase_items(id INTEGER PRIMARY KEY AUTOINCREMENT, invoice_id INTEGER NOT NULL, item_name TEXT NOT NULL, quantity REAL NOT NULL, unit_price REAL NOT NULL, total_price REAL NOT NULL, FOREIGN KEY (invoice_id) REFERENCES purchase_invoices (id) ON DELETE CASCADE)");
        await db.execute("CREATE TABLE parts(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, is_assembly INTEGER NOT NULL DEFAULT 0 CHECK(is_assembly IN (0,1)))");
        await db.execute("CREATE TABLE part_compositions(id INTEGER PRIMARY KEY AUTOINCREMENT, assembly_id INTEGER NOT NULL, component_part_id INTEGER NOT NULL, quantity REAL NOT NULL, FOREIGN KEY (assembly_id) REFERENCES parts (id) ON DELETE CASCADE, FOREIGN KEY (component_part_id) REFERENCES parts (id) ON DELETE RESTRICT)");
        await db.execute("CREATE TABLE products(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE)");
        await db.execute("CREATE TABLE product_parts(id INTEGER PRIMARY KEY AUTOINCREMENT, product_id INTEGER NOT NULL, part_id INTEGER NOT NULL, quantity REAL NOT NULL, FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE, FOREIGN KEY (part_id) REFERENCES parts (id) ON DELETE RESTRICT)");
        await db.execute("CREATE TABLE assembly_orders(id INTEGER PRIMARY KEY AUTOINCREMENT, part_id INTEGER NOT NULL, quantity_to_produce REAL NOT NULL, date TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'Pending', FOREIGN KEY (part_id) REFERENCES parts (id) ON DELETE RESTRICT)");
        await db.execute("CREATE TABLE customers(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, contact_info TEXT)");
        await db.execute("CREATE TABLE sales_orders(id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER NOT NULL, order_date TEXT NOT NULL, delivery_date TEXT, total_amount REAL NOT NULL DEFAULT 0, status TEXT NOT NULL DEFAULT 'Pending', FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE RESTRICT)");
        await db.execute("CREATE TABLE order_items(id INTEGER PRIMARY KEY AUTOINCREMENT, order_id INTEGER NOT NULL, product_id INTEGER NOT NULL, quantity REAL NOT NULL, price_at_sale REAL NOT NULL, FOREIGN KEY (order_id) REFERENCES sales_orders (id) ON DELETE CASCADE, FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT)");
        await db.execute("CREATE TABLE payments(id INTEGER PRIMARY KEY AUTOINCREMENT, order_id INTEGER NOT NULL, amount REAL NOT NULL, payment_date TEXT NOT NULL, payment_method TEXT, FOREIGN KEY (order_id) REFERENCES sales_orders (id) ON DELETE CASCADE)");
      }
    ));
    await dbService.database; // Initialize service with this in-memory DB
  });

  tearDown(() async {
    await dbService.close();
  });

  // Helper to use the extension method if DatabaseService instance is needed.
  Future<void> upsertInventoryItem(DatabaseService service, InventoryItem item) async {
    final db = await service.database;
    await db.insert('inventory', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }


  test('getAllInventoryItems fetches all items, optionally filtered', async () {
    await upsertInventoryItem(dbService, InventoryItem(itemName: 'Apple', quantity: 10, threshold: 2));
    await upsertInventoryItem(dbService, InventoryItem(itemName: 'Banana', quantity: 5, threshold: 3));
    await upsertInventoryItem(dbService, InventoryItem(itemName: 'Apricot', quantity: 8, threshold: 4));

    var allItems = await dbService.getAllInventoryItems();
    expect(allItems.length, 3);

    var filteredItems = await dbService.getAllInventoryItems(query: 'Ap');
    expect(filteredItems.length, 2); // Apple, Apricot
    expect(filteredItems.any((i) => i.itemName == 'Apple'), isTrue);
    expect(filteredItems.any((i) => i.itemName == 'Apricot'), isTrue);
  });

  test('updateInventoryItemThreshold updates only the threshold', async () {
    await upsertInventoryItem(dbService, InventoryItem(itemName: 'TestItem', quantity: 50, threshold: 10));

    int changes = await dbService.updateInventoryItemThreshold('TestItem', 15);
    expect(changes, 1);

    final item = await dbService.getInventoryItemByName('TestItem');
    expect(item?.threshold, 15);
    expect(item?.quantity, 50); // Quantity should remain unchanged

    int noChanges = await dbService.updateInventoryItemThreshold('NonExistentItem', 5);
    expect(noChanges, 0);

  });

  test('manuallyAdjustInventoryItemQuantity upserts quantity and optionally threshold', async () {
    // Test update existing
    await upsertInventoryItem(dbService, InventoryItem(itemName: 'ManualItem', quantity: 20, threshold: 5));
    await dbService.manuallyAdjustInventoryItemQuantity('ManualItem', 25, newThreshold: 7);
    var item = await dbService.getInventoryItemByName('ManualItem');
    expect(item?.quantity, 25);
    expect(item?.threshold, 7);

    // Test insert new
    await dbService.manuallyAdjustInventoryItemQuantity('NewManual', 30, newThreshold: 3);
    item = await dbService.getInventoryItemByName('NewManual');
    expect(item?.quantity, 30);
    expect(item?.threshold, 3);

    // Test insert new without new threshold (should default to 0)
    await dbService.manuallyAdjustInventoryItemQuantity('NewManualNoThresh', 5);
    item = await dbService.getInventoryItemByName('NewManualNoThresh');
    expect(item?.quantity, 5);
    expect(item?.threshold, 0);
  });
}
