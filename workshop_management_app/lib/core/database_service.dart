import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p; // Alias to avoid conflict
import '../modules/employees/models/employee.dart';
import '../modules/purchases/models/supplier.dart';
import '../modules/purchases/models/purchase_invoice.dart';
import '../modules/inventory/models/inventory_item.dart';
import '../modules/parts/models/part.dart';
import '../modules/parts/models/part_composition.dart';
import '../modules/parts/models/product.dart';
import '../modules/parts/models/product_part.dart';
import '../modules/parts/models/assembly_order.dart';

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
      version: 1, // Keep version 1 for now, or increment if significant schema changes
      onCreate: _createDB,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Ensure foreign key support is enabled (some versions of SQLite might need this explicitly)
    // Already handled in onConfigure, but good to be aware if that's removed.
    // await db.execute('PRAGMA foreign_keys = ON');

    // Employees Tables
    await db.execute('''
      CREATE TABLE employees(
        id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, pay_type TEXT NOT NULL CHECK(pay_type IN ('daily', 'hourly')),
        daily_rate REAL, hourly_rate REAL, overtime_rate REAL NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE work_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT, employee_id INTEGER NOT NULL, date TEXT NOT NULL, hours_worked REAL,
        worked_day INTEGER, overtime_hours REAL, FOREIGN KEY (employee_id) REFERENCES employees (id) ON DELETE CASCADE
      )
    ''');

    // Purchases Tables
    await db.execute('''
      CREATE TABLE suppliers(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, contact_info TEXT)
    ''');
    await db.execute('''
      CREATE TABLE purchase_invoices(
        id INTEGER PRIMARY KEY AUTOINCREMENT, supplier_id INTEGER NOT NULL, date TEXT NOT NULL, total_amount REAL NOT NULL,
        FOREIGN KEY (supplier_id) REFERENCES suppliers (id) ON DELETE RESTRICT
      )
    ''');
    await db.execute('''
      CREATE TABLE purchase_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT, invoice_id INTEGER NOT NULL, item_name TEXT NOT NULL, quantity REAL NOT NULL,
        unit_price REAL NOT NULL, total_price REAL NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES purchase_invoices (id) ON DELETE CASCADE
      )
    ''');

    // Inventory Table
    await db.execute('''
      CREATE TABLE inventory(item_name TEXT PRIMARY KEY, quantity REAL NOT NULL DEFAULT 0, threshold REAL NOT NULL DEFAULT 0)
    ''');

    // Parts and Assembly Tables (NEW)
    await db.execute('''
      CREATE TABLE parts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        is_assembly INTEGER NOT NULL DEFAULT 0 CHECK(is_assembly IN (0,1)) -- 0 for component/raw, 1 for assembly
      )
    ''');
    await db.execute('''
      CREATE TABLE part_compositions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        assembly_id INTEGER NOT NULL,          -- FK to parts.id where is_assembly = 1
        component_part_id INTEGER NOT NULL, -- FK to parts.id (the component)
        quantity REAL NOT NULL,
        FOREIGN KEY (assembly_id) REFERENCES parts (id) ON DELETE CASCADE,
        FOREIGN KEY (component_part_id) REFERENCES parts (id) ON DELETE RESTRICT
        -- RESTRICT deleting a part if it's used as a component. UI should handle this.
      )
    ''');
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');
    await db.execute('''
      CREATE TABLE product_parts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        part_id INTEGER NOT NULL,          -- FK to parts.id
        quantity REAL NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE,
        FOREIGN KEY (part_id) REFERENCES parts (id) ON DELETE RESTRICT
        -- RESTRICT deleting a part if it's used in a product. UI should handle this.
      )
    ''');
    await db.execute('''
      CREATE TABLE assembly_orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        part_id INTEGER NOT NULL,            -- FK to parts.id where is_assembly = 1
        quantity_to_produce REAL NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'Pending', -- e.g., Pending, In Progress, Completed
        FOREIGN KEY (part_id) REFERENCES parts (id) ON DELETE RESTRICT
      )
    ''');

    // TODO: Add other tables: customers, sales_orders, order_items, payments, backups
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
    return List.generate(maps.length, (i) {
      return Employee.fromMap(maps[i]);
    });
  }

  Future<Employee?> getEmployeeById(int id) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query('employees', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Employee.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateEmployee(Employee employee) async {
    final db = await database;
    return await db.update(
      'employees',
      employee.toMap(),
      where: 'id = ?',
      whereArgs: [employee.id],
    );
  }

  Future<int> deleteEmployee(int id) async {
    final db = await database;
    await db.delete('work_logs', where: 'employee_id = ?', whereArgs: [id]);
    return await db.delete(
      'employees',
      where: 'id = ?',
      whereArgs: [id],
    );
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

    final List<Map<String, dynamic>> maps = await db.query(
      'work_logs',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return WorkLog.fromMap(maps[i]);
    });
  }

  Future<WorkLog?> getWorkLogById(int id) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query('work_logs', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return WorkLog.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateWorkLog(WorkLog workLog) async {
    final db = await database;
    return await db.update(
      'work_logs',
      workLog.toMap(),
      where: 'id = ?',
      whereArgs: [workLog.id],
    );
  }

  Future<int> deleteWorkLog(int id) async {
    final db = await database;
    return await db.delete(
      'work_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Supplier CRUD ---
  Future<int> insertSupplier(Supplier supplier) async {
    final db = await database;
    try {
      return await db.insert('suppliers', supplier.toMap(), conflictAlgorithm: ConflictAlgorithm.fail);
    } catch (e) {
      print('Error inserting supplier: $e');
      rethrow;
    }
  }

  Future<List<Supplier>> getSuppliers({String? query}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (query != null && query.isNotEmpty) {
      maps = await db.query('suppliers', where: 'name LIKE ?', whereArgs: ['%$query%'], orderBy: 'name ASC');
    } else {
      maps = await db.query('suppliers', orderBy: 'name ASC');
    }
    return List.generate(maps.length, (i) {
      return Supplier.fromMap(maps[i]);
    });
  }

  Future<Supplier?> getSupplierById(int id) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query('suppliers', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Supplier.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateSupplier(Supplier supplier) async {
    final db = await database;
     try {
      return await db.update(
        'suppliers',
        supplier.toMap(),
        where: 'id = ?',
        whereArgs: [supplier.id],
        conflictAlgorithm: ConflictAlgorithm.fail
      );
    } catch (e) {
      print('Error updating supplier: $e');
      rethrow;
    }
  }

  Future<int> deleteSupplier(int id) async {
    final db = await database;
    try {
        return await db.delete(
        'suppliers',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
        print('Error deleting supplier: $e');
        rethrow;
    }
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

  Future<void> _updateInventoryItemQuantityInternal(String itemName, double quantityChange, {required DatabaseExecutor txn, double? threshold}) async {
    final currentItem = await getInventoryItemByName(itemName, txn: txn);
    if (currentItem != null) {
      final newQuantity = currentItem.quantity + quantityChange;
      Map<String, dynamic> updateValues = {'quantity': newQuantity};
      if (threshold != null) {
        updateValues['threshold'] = threshold;
      }
      await txn.update(
        'inventory',
        updateValues,
        where: 'item_name = ?',
        whereArgs: [itemName],
      );
    } else {
      await txn.insert(
        'inventory',
        {'item_name': itemName, 'quantity': quantityChange, 'threshold': threshold ?? 0.0},
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
    }
  }

  // --- PurchaseInvoice and PurchaseItem CRUD ---
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
    return List.generate(maps.length, (i) {
      return PurchaseItem.fromMap(maps[i]);
    });
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

  // --- Part CRUD (NEW) ---
  Future<int> insertPart(Part part) async {
    final db = await database;
    try {
      return await db.insert('parts', part.toMap(), conflictAlgorithm: ConflictAlgorithm.fail);
    } catch (e) { print('Error inserting part: $e'); rethrow; }
  }

  Future<List<Part>> getParts({String? query, bool? isAssembly}) async {
    final db = await database;
    String? whereClause;
    List<dynamic> whereArgs = [];
    if (query != null && query.isNotEmpty) {
      whereClause = 'name LIKE ?';
      whereArgs.add('%$query%');
    }
    if (isAssembly != null) {
      whereClause = (whereClause == null ? '' : '$whereClause AND ') + 'is_assembly = ?';
      whereArgs.add(isAssembly ? 1 : 0);
    }
    final List<Map<String, dynamic>> maps = await db.query('parts', where: whereClause, whereArgs: whereArgs.isNotEmpty ? whereArgs : null, orderBy: 'name ASC');
    return List.generate(maps.length, (i) => Part.fromMap(maps[i]));
  }

  Future<Part?> getPartById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('parts', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Part.fromMap(maps.first);
    return null;
  }

  Future<int> updatePart(Part part) async {
    final db = await database;
    try {
      return await db.update('parts', part.toMap(), where: 'id = ?', whereArgs: [part.id], conflictAlgorithm: ConflictAlgorithm.fail);
    } catch (e) { print('Error updating part: $e'); rethrow; }
  }

  Future<int> deletePart(int id) async {
    final db = await database;
    return await db.delete('parts', where: 'id = ?', whereArgs: [id]);
  }

  // --- PartComposition Management (NEW) ---
  Future<List<PartComposition>> getComponentsForAssembly(int assemblyId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('part_compositions', where: 'assembly_id = ?', whereArgs: [assemblyId]);
    return List.generate(maps.length, (i) => PartComposition.fromMap(maps[i]));
  }

  Future<int> addComponentToAssembly(PartComposition composition) async {
    final db = await database;
    final assemblyPart = await getPartById(composition.assemblyId);
    if (assemblyPart == null || !assemblyPart.isAssembly) throw Exception('Assembly ID does not refer to an assembly part.');
    final componentPart = await getPartById(composition.componentPartId);
    if (componentPart == null) throw Exception('Component Part ID does not exist.');

    return await db.insert('part_compositions', composition.toMap());
  }

  Future<void> setAssemblyComponents(int assemblyId, List<PartComposition> components) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('part_compositions', where: 'assembly_id = ?', whereArgs: [assemblyId]);
      for (var comp in components) {
        if (comp.assemblyId != assemblyId) throw Exception('Component assemblyId mismatch.');
        final componentPart = await getPartById(comp.componentPartId);
        if (componentPart == null) throw Exception('Component Part ID ${comp.componentPartId} does not exist.');
        await txn.insert('part_compositions', comp.toMap());
      }
    });
  }

  Future<int> removeComponentFromAssembly(int compositionId) async {
    final db = await database;
    return await db.delete('part_compositions', where: 'id = ?', whereArgs: [compositionId]);
  }

  // --- Product CRUD (NEW) ---
  Future<int> insertProduct(Product product) async {
    final db = await database;
    try {
      return await db.insert('products', product.toMap(), conflictAlgorithm: ConflictAlgorithm.fail);
    } catch (e) { print('Error inserting product: $e'); rethrow; }
  }
  Future<List<Product>> getProducts({String? query}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products', where: query != null ? 'name LIKE ?' : null, whereArgs: query != null ? ['%$query%'] : null, orderBy: 'name ASC');
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }
  Future<Product?> getProductById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Product.fromMap(maps.first);
    return null;
  }
  Future<int> updateProduct(Product product) async {
    final db = await database;
     try {
      return await db.update('products', product.toMap(), where: 'id = ?', whereArgs: [product.id], conflictAlgorithm: ConflictAlgorithm.fail);
    } catch (e) { print('Error updating product: $e'); rethrow; }
  }
  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // --- ProductPart Management (NEW) ---
  Future<List<ProductPart>> getPartsForProduct(int productId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('product_parts', where: 'product_id = ?', whereArgs: [productId]);
    return List.generate(maps.length, (i) => ProductPart.fromMap(maps[i]));
  }

  Future<void> setProductParts(int productId, List<ProductPart> productParts) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('product_parts', where: 'product_id = ?', whereArgs: [productId]);
      for (var pp in productParts) {
        if (pp.productId != productId) throw Exception('ProductPart productId mismatch.');
        final part = await getPartById(pp.partId);
        if (part == null) throw Exception('Part ID ${pp.partId} for product does not exist.');
        await txn.insert('product_parts', pp.toMap());
      }
    });
  }

  // --- AssemblyOrder CRUD & Processing (NEW) ---
  Future<int> insertAssemblyOrder(AssemblyOrder order) async {
    final db = await database;
    final part = await getPartById(order.partId);
    if (part == null || !part.isAssembly) throw Exception('Part ID for assembly order must be an assembly part.');
    return await db.insert('assembly_orders', order.toMap());
  }
  Future<List<AssemblyOrder>> getAssemblyOrders({String? status}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('assembly_orders', where: status != null ? 'status = ?' : null, whereArgs: status != null ? [status] : null, orderBy: 'date DESC');
    return List.generate(maps.length, (i) => AssemblyOrder.fromMap(maps[i]));
  }
  Future<AssemblyOrder?> getAssemblyOrderById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('assembly_orders', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return AssemblyOrder.fromMap(maps.first);
    return null;
  }
  Future<int> updateAssemblyOrderStatus(int orderId, String status) async {
    final db = await database;
    return await db.update('assembly_orders', {'status': status}, where: 'id = ?', whereArgs: [orderId]);
  }
  Future<int> deleteAssemblyOrder(int id) async {
    final db = await database;
    return await db.delete('assembly_orders', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> completeAssemblyOrder(int assemblyOrderId) async {
    final db = await database;
    await db.transaction((txn) async {
      final orderMap = await txn.query('assembly_orders', where: 'id = ?', whereArgs: [assemblyOrderId]);
      if (orderMap.isEmpty) throw Exception('AssemblyOrder not found');
      final order = AssemblyOrder.fromMap(orderMap.first);

      if (order.status == 'Completed') throw Exception('Order already completed');

      final assembledPart = await getPartById(order.partId);
      if (assembledPart == null) throw Exception('Assembled part not found');

      await _updateInventoryItemQuantityInternal(assembledPart.name, order.quantityToProduce, txn: txn);

      final components = await getComponentsForAssembly(order.partId);
      for (var composition in components) {
        final componentPart = await getPartById(composition.componentPartId);
        if (componentPart == null) throw Exception('Component part ${composition.componentPartId} not found');

        final quantityToConsume = composition.quantity * order.quantityToProduce;
        await _updateInventoryItemQuantityInternal(componentPart.name, -quantityToConsume, txn: txn);
      }
      await txn.update('assembly_orders', {'status': 'Completed'}, where: 'id = ?', whereArgs: [assemblyOrderId]);
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
