import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  final String databasePath = 'sahibz.db';

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(databasePath);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  final String inventoryTableName = 'inventory';
  final String expenseTableName = 'expense';

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const numType = 'REAL NOT NULL';

    // Inventory table
    await db.execute('''
      CREATE TABLE $inventoryTableName (
        id $idType,
        label TEXT UNIQUE DEFAULT (UPPER(SUBSTR(HEX(RANDOMBLOB(8)), 1, 8))),
        name $textType,
        company $textType,
        unit $textType,
        date $textType,
        update_date TEXT
      )
    ''');

    // Expense table
    await db.execute('''
      CREATE TABLE $expenseTableName (
        id $idType,
        title $textType,
        amount $numType,
        description $textType,
        date $textType
      )
    ''');

    // Recent activity table
    await db.execute('''
      CREATE TABLE recent_activity (
        id $idType,
        type $textType,
        title $textType,
        date $textType
      )
    ''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }

  /// Delete the database file
  Future<void> deleteDb() async {
    await close();
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, databasePath);
    await deleteDatabase(path);
  }
}
