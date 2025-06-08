import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:workshop_management_app/core/database_service.dart';
import 'package:workshop_management_app/modules/orders/models/sales_order.dart'; // For SalesOrder
import 'package:workshop_management_app/modules/purchases/models/purchase_invoice.dart'; // For PurchaseInvoice
import 'package:workshop_management_app/modules/orders/models/customer.dart'; // For Customer
import 'package:workshop_management_app/modules/purchases/models/supplier.dart'; // For Supplier


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
    // The DatabaseService's _initDB will use the FFI factory for in-memory DB.
    // We need to ensure it's a fresh DB for each test, which opening `inMemoryDatabasePath` does.
    // The schema creation is handled by the DatabaseService's `_createDB` via `_initDB`.

    // Explicitly open and create schema for test isolation
    Database db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
      options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            // Replicate all table creations from DatabaseService._createDB
            await db.execute('PRAGMA foreign_keys = ON');
            await db.execute("CREATE TABLE employees(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, pay_type TEXT NOT NULL CHECK(pay_type IN ('daily', 'hourly')), daily_rate REAL, hourly_rate REAL, overtime_rate REAL NOT NULL)");
            await db.execute("CREATE TABLE work_logs(id INTEGER PRIMARY KEY AUTOINCREMENT, employee_id INTEGER NOT NULL, date TEXT NOT NULL, hours_worked REAL, worked_day INTEGER, overtime_hours REAL, FOREIGN KEY (employee_id) REFERENCES employees (id) ON DELETE CASCADE)");
            await db.execute("CREATE TABLE suppliers(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, contact_info TEXT)");
            await db.execute("CREATE TABLE purchase_invoices(id INTEGER PRIMARY KEY AUTOINCREMENT, supplier_id INTEGER NOT NULL, date TEXT NOT NULL, total_amount REAL NOT NULL, FOREIGN KEY (supplier_id) REFERENCES suppliers (id) ON DELETE RESTRICT)");
            await db.execute("CREATE TABLE purchase_items(id INTEGER PRIMARY KEY AUTOINCREMENT, invoice_id INTEGER NOT NULL, item_name TEXT NOT NULL, quantity REAL NOT NULL, unit_price REAL NOT NULL, total_price REAL NOT NULL, FOREIGN KEY (invoice_id) REFERENCES purchase_invoices (id) ON DELETE CASCADE)");
            await db.execute("CREATE TABLE inventory(item_name TEXT PRIMARY KEY, quantity REAL NOT NULL DEFAULT 0, threshold REAL NOT NULL DEFAULT 0)");
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
      )
    );
    // Re-initialize dbService to use this specific in-memory DB instance if its internal _db isn't already set by factory.
    // This setup ensures that DatabaseService operates on a clean, schema-ready in-memory database for each test.
    // dbService.database = Future.value(db); // If DatabaseService allowed direct DB injection.
    // For now, rely on the factory being set for subsequent DatabaseService() instantiations.
    // The dbService instance created in setUp() for the tests will use the FFI factory.
    // To be absolutely sure it's a fresh DB, we can close the previous and open a new one.
    await dbService.close(); // Close any existing from a previous test if not torn down properly
    dbService = DatabaseService(); // This should now get a fresh in-memory DB
    await dbService.database; // Ensure it's initialized

    // Seed dummy customer/supplier for FK constraints
    await dbService.insertCustomer(Customer(name: "Test Cust For Report"));
    await dbService.insertSupplier(Supplier(name: "Test Supp For Report"));
  });

  tearDown(() async {
    await dbService.close();
  });

  final rangeStart = DateTime(2023, 7, 1);
  final rangeEnd = DateTime(2023, 7, 31);

  test('getSalesTotalInDateRange sums correctly for "Completed" orders', async () {
    final customer = await dbService.getCustomers(query: "Test Cust For Report");
    expect(customer, isNotEmpty, reason: "Test customer should exist for FK constraints.");
    final customerId = customer.first.id!;

    // Orders within range
    await dbService.insertSalesOrder(SalesOrder(customerId: customerId, orderDate: DateTime(2023,7,5), totalAmount: 100, status: 'Completed', items: []));
    await dbService.insertSalesOrder(SalesOrder(customerId: customerId, orderDate: DateTime(2023,7,15), totalAmount: 150, status: 'Completed', items: []));
    // Order in range but pending
    await dbService.insertSalesOrder(SalesOrder(customerId: customerId, orderDate: DateTime(2023,7,10), totalAmount: 50, status: 'Pending', items: []));
    // Order out of range
    await dbService.insertSalesOrder(SalesOrder(customerId: customerId, orderDate: DateTime(2023,6,20), totalAmount: 200, status: 'Completed', items: []));

    final total = await dbService.getSalesTotalInDateRange(rangeStart, rangeEnd);
    expect(total, 250.0); // 100 + 150
  });

  test('getPurchaseTotalInDateRange sums correctly', async () {
    final supplier = await dbService.getSuppliers(query: "Test Supp For Report");
    expect(supplier, isNotEmpty, reason: "Test supplier should exist for FK constraints.");
    final supplierId = supplier.first.id!;

    // Purchases within range
    await dbService.insertPurchaseInvoice(PurchaseInvoice(supplierId: supplierId, date: DateTime(2023,7,8), totalAmount: 75, items: []));
    await dbService.insertPurchaseInvoice(PurchaseInvoice(supplierId: supplierId, date: DateTime(2023,7,18), totalAmount: 125, items: []));
    // Purchase out of range
    await dbService.insertPurchaseInvoice(PurchaseInvoice(supplierId: supplierId, date: DateTime(2023,8,5), totalAmount: 60, items: []));

    final total = await dbService.getPurchaseTotalInDateRange(rangeStart, rangeEnd);
    expect(total, 200.0); // 75 + 125
  });
}
