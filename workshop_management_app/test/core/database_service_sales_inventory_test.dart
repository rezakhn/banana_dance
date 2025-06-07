import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:workshop_management_app/core/database_service.dart';
import 'package:workshop_management_app/modules/orders/models/customer.dart';
import 'package:workshop_management_app/modules/orders/models/sales_order.dart';
import 'package:workshop_management_app/modules/orders/models/order_item.dart';
import 'package:workshop_management_app/modules/parts/models/product.dart';
import 'package:workshop_management_app/modules/parts/models/part.dart';
import 'package:workshop_management_app/modules/parts/models/product_part.dart';
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
    // Open new in-memory DB for each test and create schema
    Database db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath, options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        // Replicate _createDB to ensure all tables are present
        await db.execute('PRAGMA foreign_keys = ON');
        await db.execute("CREATE TABLE customers(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, contact_info TEXT)");
        await db.execute("CREATE TABLE sales_orders(id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER NOT NULL, order_date TEXT NOT NULL, delivery_date TEXT, total_amount REAL NOT NULL DEFAULT 0, status TEXT NOT NULL DEFAULT 'Pending', FOREIGN KEY (customer_id) REFERENCES customers (id))");
        await db.execute("CREATE TABLE order_items(id INTEGER PRIMARY KEY AUTOINCREMENT, order_id INTEGER NOT NULL, product_id INTEGER NOT NULL, quantity REAL NOT NULL, price_at_sale REAL NOT NULL, FOREIGN KEY (order_id) REFERENCES sales_orders (id), FOREIGN KEY (product_id) REFERENCES products (id))");
        await db.execute("CREATE TABLE products(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE)");
        await db.execute("CREATE TABLE parts(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, is_assembly INTEGER NOT NULL DEFAULT 0)");
        await db.execute("CREATE TABLE product_parts(id INTEGER PRIMARY KEY AUTOINCREMENT, product_id INTEGER NOT NULL, part_id INTEGER NOT NULL, quantity REAL NOT NULL, FOREIGN KEY (product_id) REFERENCES products (id), FOREIGN KEY (part_id) REFERENCES parts (id))");
        await db.execute("CREATE TABLE inventory(item_name TEXT PRIMARY KEY, quantity REAL NOT NULL DEFAULT 0, threshold REAL NOT NULL DEFAULT 0)");
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
            CREATE TABLE part_compositions(id INTEGER PRIMARY KEY AUTOINCREMENT, assembly_id INTEGER NOT NULL, component_part_id INTEGER NOT NULL, quantity REAL NOT NULL, FOREIGN KEY (assembly_id) REFERENCES parts (id) ON DELETE CASCADE, FOREIGN KEY (component_part_id) REFERENCES parts (id) ON DELETE RESTRICT)
        ''');
        await db.execute('''
            CREATE TABLE assembly_orders(id INTEGER PRIMARY KEY AUTOINCREMENT, part_id INTEGER NOT NULL, quantity_to_produce REAL NOT NULL, date TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'Pending', FOREIGN KEY (part_id) REFERENCES parts (id) ON DELETE RESTRICT)
        ''');
        await db.execute('''
            CREATE TABLE payments(id INTEGER PRIMARY KEY AUTOINCREMENT, order_id INTEGER NOT NULL, amount REAL NOT NULL, payment_date TEXT NOT NULL, payment_method TEXT, FOREIGN KEY (order_id) REFERENCES sales_orders (id) ON DELETE CASCADE)
        ''');


      }
    ));
    // This ensures DatabaseService uses our in-memory DB for this test suite.
    // This requires DatabaseService to be refactored to accept a Database instance or use the FFI factory.
    // For now, assuming DatabaseService() uses the FFI factory after sqfliteTestInit().
    await dbService.database; // Initialize/ensure it's using the test DB
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
  Future<void> upsertInventoryItem(DatabaseService service, InventoryItem item) async {
    final db = await service.database; // Use the instance passed or the one from setUp
    await db.insert('inventory', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }


  test('completeSalesOrderAndUpdateInventory correctly updates inventory', () async {
    // 1. Setup Customer
    final customerId = await dbService.insertCustomer(Customer(name: 'Sales Test Customer'));
    // 2. Setup Part (this part is what's in inventory)
    final partId = await dbService.insertPart(Part(name: 'SoldPart1', isAssembly: false));
    // 3. Setup Product that uses this Part
    final productId = await dbService.insertProduct(Product(name: 'SoldProduct1'));
    await dbService.setProductParts(productId, [ProductPart(productId: productId, partId: partId, quantity: 1)]);
    // 4. Initial Inventory for the Part
    await upsertInventoryItem(dbService, InventoryItem(itemName: 'SoldPart1', quantity: 100));

    // 5. Create Sales Order
    final order = SalesOrder(customerId: customerId, orderDate: DateTime.now(), items: [
      OrderItem(orderId: 0, productId: productId, quantity: 10, priceAtSale: 5.0)
    ]);
    order.calculateTotalAmount();
    final orderId = await dbService.insertSalesOrder(order);

    // 6. Complete the Sales Order
    await dbService.completeSalesOrderAndUpdateInventory(orderId);

    // 7. Verify Inventory
    final stock = await getInventoryDirectly('SoldPart1');
    expect(stock?.quantity, 90); // 100 - 10 = 90

    // 8. Verify Order Status
    final completedOrder = await dbService.getSalesOrderById(orderId);
    expect(completedOrder?.status, 'Completed');
  });
}
