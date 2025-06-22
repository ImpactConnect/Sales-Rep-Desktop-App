import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sales_rep.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create tables
        await db.execute('''
          CREATE TABLE IF NOT EXISTS ${AppTables.profiles} (
            id TEXT PRIMARY KEY,
            email TEXT NOT NULL,
            full_name TEXT,
            outlet_id TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS ${AppTables.outlets} (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            location TEXT,
            contact_person TEXT,
            contact_number TEXT,
            synced INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS ${AppTables.stock} (
            id TEXT PRIMARY KEY,
            product_name TEXT NOT NULL,
            quantity REAL NOT NULL,
            unit TEXT NOT NULL,
            cost_per_unit REAL NOT NULL,
            date_added TEXT NOT NULL,
            last_updated TEXT,
            description TEXT,
            outlet_id TEXT,
            synced INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS ${AppTables.sales} (
            id TEXT PRIMARY KEY,
            outlet_id TEXT NOT NULL,
            rep_id TEXT NOT NULL,
            customer_id TEXT,
            vat REAL DEFAULT 0.0,
            total_amount REAL NOT NULL,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            synced INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (outlet_id) REFERENCES ${AppTables.outlets} (id),
            FOREIGN KEY (rep_id) REFERENCES ${AppTables.profiles} (id),
            FOREIGN KEY (customer_id) REFERENCES customers (id)
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS ${AppTables.saleItems} (
            id TEXT PRIMARY KEY,
            sale_id TEXT NOT NULL,
            product_id TEXT NOT NULL,
            quantity REAL NOT NULL,
            unit_price REAL NOT NULL,
            total REAL GENERATED ALWAYS AS (quantity * unit_price) STORED,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (sale_id) REFERENCES ${AppTables.sales} (id),
            FOREIGN KEY (product_id) REFERENCES ${AppTables.stock} (id)
          )
        ''');
      },
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
