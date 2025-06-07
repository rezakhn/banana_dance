import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p; // Alias to avoid conflict if 'path' is used elsewhere
import '../modules/employees/models/employee.dart';

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
    final path = p.join(dbPath, _dbName); // Use aliased 'p'
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
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
        date TEXT NOT NULL, -- YYYY-MM-DD
        hours_worked REAL,
        worked_day INTEGER, -- 0 for false, 1 for true
        overtime_hours REAL,
        FOREIGN KEY (employee_id) REFERENCES employees (id) ON DELETE CASCADE
      )
    ''');

    // TODO: Add other tables here as per the full schema in the issue
    // purchase_invoices, purchase_items, suppliers, parts, part_compositions,
    // products, product_parts, assembly_orders, customers, sales_orders,
    // order_items, payments, inventory, backups
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
    // Also delete associated work logs
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

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
