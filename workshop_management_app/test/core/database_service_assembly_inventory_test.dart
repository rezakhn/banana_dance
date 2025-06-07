import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:workshop_management_app/core/database_service.dart';
import 'package:workshop_management_app/modules/parts/models/part.dart';
import 'package:workshop_management_app/modules/parts/models/part_composition.dart';
import 'package:workshop_management_app/modules/parts/models/assembly_order.dart';
import 'package:workshop_management_app/modules/inventory/models/inventory_item.dart';

void sqfliteTestInit() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

void main() {
  sqfliteTestInit();
  late DatabaseService dbService;

  setUp(() async {
    dbService = DatabaseService(); // Uses FFI factory for in-memory
    // Manually create schema for each test run with in-memory DB
    // This requires DatabaseService._createDB to be accessible or schema replicated.
    // For simplicity, we assume it's handled by DatabaseService's _initDB if it uses inMemoryDatabasePath for tests.
    // Or, we use a fresh in-memory DB and create tables manually here.
    Database db = await openDatabase(inMemoryDatabasePath, version: 1, onCreate: (db, version) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await db.execute("CREATE TABLE parts(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, is_assembly INTEGER NOT NULL DEFAULT 0)");
        await db.execute("CREATE TABLE part_compositions(id INTEGER PRIMARY KEY AUTOINCREMENT, assembly_id INTEGER NOT NULL, component_part_id INTEGER NOT NULL, quantity REAL NOT NULL, FOREIGN KEY (assembly_id) REFERENCES parts (id) ON DELETE CASCADE, FOREIGN KEY (component_part_id) REFERENCES parts (id) ON DELETE RESTRICT)");
        await db.execute("CREATE TABLE inventory(item_name TEXT PRIMARY KEY, quantity REAL NOT NULL DEFAULT 0, threshold REAL NOT NULL DEFAULT 0)");
        await db.execute("CREATE TABLE assembly_orders(id INTEGER PRIMARY KEY AUTOINCREMENT, part_id INTEGER NOT NULL, quantity_to_produce REAL NOT NULL, date TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'Pending', FOREIGN KEY (part_id) REFERENCES parts (id))");
        // Add other tables from the main _createDB if they become relevant for these tests by foreign key or other dependencies.
        // For example, if products or purchase_items were directly involved in assembly inventory logic (they are not currently).
         await db.execute('''
            CREATE TABLE employees(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, pay_type TEXT NOT NULL CHECK(pay_type IN ('daily', 'hourly')), daily_rate REAL, hourly_rate REAL, overtime_rate REAL NOT NULL)
         ''');
         await db.execute('''
            CREATE TABLE work_logs(id INTEGER PRIMARY KEY AUTOINCREMENT, employee_id INTEGER NOT NULL, date TEXT NOT NULL, hours_worked REAL, worked_day INTEGER, overtime_hours REAL, FOREIGN KEY (employee_id) REFERENCES employees (id) ON DELETE CASCADE)
         ''');
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
            CREATE TABLE products(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE)
        ''');
        await db.execute('''
            CREATE TABLE product_parts(id INTEGER PRIMARY KEY AUTOINCREMENT, product_id INTEGER NOT NULL, part_id INTEGER NOT NULL, quantity REAL NOT NULL, FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE, FOREIGN KEY (part_id) REFERENCES parts (id) ON DELETE RESTRICT)
        ''');


    });
    // This is a common pattern: ensure the dbService uses this specific in-memory db instance.
    // This test suite relies on DatabaseService internally using the FFI factory for in-memory dbs for tests.
    // Or dbService.database = Future.value(db); if dbService could be configured this way.
    // For now, assume DatabaseService() on host uses FFI by default after sqfliteTestInit().
    await dbService.database; // Ensure DB is initialized
  });

  tearDown(() async {
    await dbService.close();
  });

  Future<InventoryItem?> getInventoryDirectly(String itemName) async {
    final db = await dbService.database;
    final List<Map<String, dynamic>> maps = await db.query('inventory', where: 'item_name = ?', whereArgs: [itemName]);
    if (maps.isNotEmpty) return InventoryItem.fromMap(maps.first);
    return null;
  }

  // Helper extension for DatabaseService for tests, if needed for setup/teardown.
  // This is defined in part_controller_test.dart, but for standalone DB test, can be here too.
  Future<void> upsertInventoryItem(DatabaseService service, InventoryItem item) async {
    final db = await service.database; // Use the instance passed or the one from setUp
    await db.insert('inventory', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }


  test('completeAssemblyOrder correctly updates inventory for assembly and components', () async {
    // 1. Define parts
    final rawMat = Part(name: 'RawMat1', isAssembly: false);
    final assembly = Part(name: 'Assembly1', isAssembly: true);
    final rawMatId = await dbService.insertPart(rawMat);
    final assemblyId = await dbService.insertPart(assembly);

    // 2. Define composition: Assembly1 needs 2 RawMat1
    await dbService.addComponentToAssembly(PartComposition(assemblyId: assemblyId, componentPartId: rawMatId, quantity: 2));

    // 3. Initial inventory: RawMat1 has 10 units
    await upsertInventoryItem(dbService, InventoryItem(itemName: 'RawMat1', quantity: 10));
    await upsertInventoryItem(dbService, InventoryItem(itemName: 'Assembly1', quantity: 0)); // Ensure assembly exists in inventory

    // 4. Create Assembly Order for 3 units of Assembly1
    final order = AssemblyOrder(partId: assemblyId, quantityToProduce: 3, date: DateTime.now());
    final orderId = await dbService.insertAssemblyOrder(order);

    // 5. Complete the order
    await dbService.completeAssemblyOrder(orderId);

    // 6. Verify inventory
    final rawMatStock = await getInventoryDirectly('RawMat1');
    expect(rawMatStock?.quantity, 4); // 10 - (2 * 3) = 4

    final assemblyStock = await getInventoryDirectly('Assembly1');
    expect(assemblyStock?.quantity, 3); // 0 + 3 = 3

    // 7. Verify order status
    final completedOrder = await dbService.getAssemblyOrderById(orderId);
    expect(completedOrder?.status, 'Completed');
  });
}
