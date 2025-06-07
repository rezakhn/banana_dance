import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p; // Alias to avoid conflict
import '../modules/employees/models/employee.dart';
import '../modules/purchases/models/supplier.dart';
import '../modules/purchases/models/purchase_invoice.dart';
import '../modules/inventory/models/inventory_item.dart'; // Added

class DatabaseService {
  static const String _dbName = "workshop_management.db";
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Employees Tables
    await db.execute('''
      CREATE TABLE employees(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        pay_type TEXT NOT NULL CHECK(pay_type IN ('daily', 'hourly')),
        daily_rate REAL,
        hourly_rate REAL,
        overtime_rate REAL NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE work_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        hours_worked REAL,
        worked_day INTEGER,
        overtime_hours REAL,
        FOREIGN KEY (employee_id) REFERENCES employees (id) ON DELETE CASCADE
      )
    ''');

    // Purchases Tables
    await db.execute('''
      CREATE TABLE suppliers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        contact_info TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE purchase_invoices(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplier_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        total_amount REAL NOT NULL,
        FOREIGN KEY (supplier_id) REFERENCES suppliers (id) ON DELETE RESTRICT
      )
    ''');
    await db.execute('''
      CREATE TABLE purchase_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        item_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        total_price REAL NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES purchase_invoices (id) ON DELETE CASCADE
      )
    ''');

    // Inventory Table
    await db.execute('''
      CREATE TABLE inventory(
        item_name TEXT PRIMARY KEY,
        quantity REAL NOT NULL DEFAULT 0,
        threshold REAL NOT NULL DEFAULT 0
      )
    ''');

    // TODO: Add other tables here: parts, part_compositions, products, etc.
  }

  // --- Employee CRUD ---
  Future<int> insertEmployee(Employee employee) async {
    final db = await database;
    return await db.insert('employees', employee.toMap());
  }
  Future<List<Employee>> getEmployees({String? query}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (query != null && query.isNotEmpty) {
      maps = await db.query('employees', where: 'name LIKE ?', whereArgs: ['%$query%']);
    } else {
      maps = await db.query('employees');
    }
    return List.generate(maps.length, (i) => Employee.fromMap(maps[i]));
  }
  Future<Employee?> getEmployeeById(int id) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query('employees', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Employee.fromMap(maps.first);
    return null;
  }
  Future<int> updateEmployee(Employee employee) async {
    final db = await database;
    return await db.update('employees', employee.toMap(), where: 'id = ?', whereArgs: [employee.id]);
  }
  Future<int> deleteEmployee(int id) async {
    final db = await database;
    await db.delete('work_logs', where: 'employee_id = ?', whereArgs: [id]);
    return await db.delete('employees', where: 'id = ?', whereArgs: [id]);
  }

  // --- WorkLog CRUD ---
  Future<int> insertWorkLog(WorkLog workLog) async {
    final db = await database;
    return await db.insert('work_logs', workLog.toMap());
  }
  Future<List<WorkLog>> getWorkLogsForEmployee(int employeeId, {DateTime? startDate, DateTime? endDate}) async {
    final db = await database;
    String whereClause = 'employee_id = ?';
    List<dynamic> whereArgs = [employeeId];
    if (startDate != null && endDate != null) {
      whereClause += ' AND date BETWEEN ? AND ?';
      whereArgs.add(startDate.toIso8601String().substring(0,10));
      whereArgs.add(endDate.toIso8601String().substring(0,10));
    } else if (startDate != null) {
      whereClause += ' AND date >= ?';
      whereArgs.add(startDate.toIso8601String().substring(0,10));
    } else if (endDate != null) {
      whereClause += ' AND date <= ?';
      whereArgs.add(endDate.toIso8601String().substring(0,10));
    }
    final List<Map<String, dynamic>> maps = await db.query('work_logs', where: whereClause, whereArgs: whereArgs, orderBy: 'date DESC');
    return List.generate(maps.length, (i) => WorkLog.fromMap(maps[i]));
  }
  Future<WorkLog?> getWorkLogById(int id) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query('work_logs', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return WorkLog.fromMap(maps.first);
    return null;
  }
  Future<int> updateWorkLog(WorkLog workLog) async {
    final db = await database;
    return await db.update('work_logs', workLog.toMap(), where: 'id = ?', whereArgs: [workLog.id]);
  }
  Future<int> deleteWorkLog(int id) async {
    final db = await database;
    return await db.delete('work_logs', where: 'id = ?', whereArgs: [id]);
  }

  // --- Supplier CRUD ---
  Future<int> insertSupplier(Supplier supplier) async {
    final db = await database;
    try {
      return await db.insert('suppliers', supplier.toMap(), conflictAlgorithm: ConflictAlgorithm.fail);
    } catch (e) { rethrow; }
  }
  Future<List<Supplier>> getSuppliers({String? query}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (query != null && query.isNotEmpty) {
      maps = await db.query('suppliers', where: 'name LIKE ?', whereArgs: ['%$query%'], orderBy: 'name ASC');
    } else {
      maps = await db.query('suppliers', orderBy: 'name ASC');
    }
    return List.generate(maps.length, (i) => Supplier.fromMap(maps[i]));
  }
  Future<Supplier?> getSupplierById(int id) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query('suppliers', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Supplier.fromMap(maps.first);
    return null;
  }
  Future<int> updateSupplier(Supplier supplier) async {
    final db = await database;
    try {
      return await db.update('suppliers', supplier.toMap(), where: 'id = ?', whereArgs: [supplier.id], conflictAlgorithm: ConflictAlgorithm.fail);
    } catch (e) { rethrow; }
  }
  Future<int> deleteSupplier(int id) async {
    final db = await database;
    try {
      return await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
    } catch (e) { rethrow; }
  }

  // --- Inventory CRUD ---
  Future<InventoryItem?> getInventoryItemByName(String itemName, {DatabaseExecutor? txn}) async {
    final db = txn ?? await database;
    List<Map<String, dynamic>> maps = await db.query(
      'inventory',
      where: 'item_name = ?',
      whereArgs: [itemName],
    );
    if (maps.isNotEmpty) {
      return InventoryItem.fromMap(maps.first);
    }
    return null;
  }

  // This is a helper for internal use by purchase/sales logic, uses transaction
  Future<void> _updateInventoryItemQuantityInternal(String itemName, double quantityChange, {required DatabaseExecutor txn, double? threshold}) async {
    final currentItem = await getInventoryItemByName(itemName, txn: txn);
    if (currentItem != null) {
      final newQuantity = currentItem.quantity + quantityChange;
      Map<String, dynamic> updateValues = {'quantity': newQuantity};
      if (threshold != null) { // Only update threshold if provided
        updateValues['threshold'] = threshold;
      }
      await txn.update(
        'inventory',
        updateValues,
        where: 'item_name = ?',
        whereArgs: [itemName],
      );
    } else {
      // If item does not exist, create it with the changed quantity.
      // This assumes positive quantityChange for new items from purchases.
      // Negative quantityChange for new items (e.g. from sales of non-existent items) should be handled carefully.
      await txn.insert(
        'inventory',
        {'item_name': itemName, 'quantity': quantityChange, 'threshold': threshold ?? 0.0},
        conflictAlgorithm: ConflictAlgorithm.fail, // Should not fail if currentItem is null
      );
    }
  }

  // --- PurchaseInvoice and PurchaseItem CRUD (MODIFIED for Inventory) ---
  Future<int> insertPurchaseInvoice(PurchaseInvoice invoice) async {
    final db = await database;
    return await db.transaction((txn) async {
      invoice.calculateTotalAmount();
      int invoiceId = await txn.insert('purchase_invoices', invoice.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      for (var item in invoice.items) {
        var itemMap = item.toMap();
        itemMap['invoice_id'] = invoiceId;
        await txn.insert('purchase_items', itemMap, conflictAlgorithm: ConflictAlgorithm.replace);
        await _updateInventoryItemQuantityInternal(item.itemName, item.quantity, txn: txn);
      }
      return invoiceId;
    });
  }

  Future<List<PurchaseItem>> _getPurchaseItemsForInvoice(int invoiceId, {DatabaseExecutor? txn}) async {
    final db = txn ?? await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'purchase_items',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );
    return List.generate(maps.length, (i) => PurchaseItem.fromMap(maps[i]));
  }

  Future<List<PurchaseInvoice>> getPurchaseInvoices({DateTime? startDate, DateTime? endDate, int? supplierId}) async {
    final db = await database;
    String whereFinalClause = "";
    List<dynamic> whereArgsFinal = [];

    if (supplierId != null) {
        whereFinalClause += (whereFinalClause.isNotEmpty ? " AND " : "") + "supplier_id = ?";
        whereArgsFinal.add(supplierId);
    }
    if (startDate != null && endDate != null) {
        whereFinalClause += (whereFinalClause.isNotEmpty ? " AND " : "") + "date BETWEEN ? AND ?";
        whereArgsFinal.add(startDate.toIso8601String().substring(0,10));
        whereArgsFinal.add(endDate.toIso8601String().substring(0,10));
    } else if (startDate != null) {
        whereFinalClause += (whereFinalClause.isNotEmpty ? " AND " : "") + "date >= ?";
        whereArgsFinal.add(startDate.toIso8601String().substring(0,10));
    } else if (endDate != null) {
        whereFinalClause += (whereFinalClause.isNotEmpty ? " AND " : "") + "date <= ?";
        whereArgsFinal.add(endDate.toIso8601String().substring(0,10));
    }

    final List<Map<String, dynamic>> invoiceMaps = await db.query('purchase_invoices',
        where: whereFinalClause.isNotEmpty ? whereFinalClause : null,
        whereArgs: whereArgsFinal.isNotEmpty ? whereArgsFinal : null,
        orderBy: 'date DESC');
    List<PurchaseInvoice> invoices = [];
    for (var map in invoiceMaps) {
      List<PurchaseItem> items = await _getPurchaseItemsForInvoice(map['id'] as int);
      invoices.add(PurchaseInvoice.fromMap(map, items));
    }
    return invoices;
  }

  Future<PurchaseInvoice?> getPurchaseInvoiceById(int id) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query('purchase_invoices', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      List<PurchaseItem> items = await _getPurchaseItemsForInvoice(id);
      return PurchaseInvoice.fromMap(maps.first, items);
    }
    return null;
  }

  Future<int> updatePurchaseInvoice(PurchaseInvoice invoice) async {
    final db = await database;
    return await db.transaction((txn) async {
      invoice.calculateTotalAmount();

      List<PurchaseItem> oldItems = await _getPurchaseItemsForInvoice(invoice.id!, txn: txn);
      for (var oldItem in oldItems) {
         await _updateInventoryItemQuantityInternal(oldItem.itemName, -oldItem.quantity, txn: txn);
      }

      int count = await txn.update('purchase_invoices', invoice.toMap(), where: 'id = ?', whereArgs: [invoice.id], conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.delete('purchase_items', where: 'invoice_id = ?', whereArgs: [invoice.id]);

      for (var item in invoice.items) {
        var itemMap = item.toMap();
        itemMap['invoice_id'] = invoice.id;
        await txn.insert('purchase_items', itemMap, conflictAlgorithm: ConflictAlgorithm.replace);
        await _updateInventoryItemQuantityInternal(item.itemName, item.quantity, txn: txn);
      }
      return count;
    });
  }

  Future<int> deletePurchaseInvoice(int id) async {
    final db = await database;
    return await db.transaction((txn) async {
      List<PurchaseItem> itemsToDelete = await _getPurchaseItemsForInvoice(id, txn: txn);
      for (var item in itemsToDelete) {
        await _updateInventoryItemQuantityInternal(item.itemName, -item.quantity, txn: txn);
      }
      return await txn.delete('purchase_invoices', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> close() async {
    final db = await database;
    if (db.isOpen) {
      db.close();
    }
    _database = null;
  }
}
