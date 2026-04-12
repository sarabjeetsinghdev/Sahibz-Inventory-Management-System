import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Singleton helper class for managing SQLite database operations.
///
/// This class provides centralized database management for the inventory
/// management system, including:
/// - Database initialization and creation
/// - Table schema management for inventory, expense, and activity tracking
/// - Database lifecycle management (open/close/delete)
///
/// The database uses sqflite package and stores data locally in the app directory.
///
/// Usage:
/// ```dart
/// final db = await DatabaseHelper.instance.database;
/// // Perform database operations
/// await DatabaseHelper.instance.close();
/// ```
///
/// Tables:
/// - [inventoryTableName]: Stores inventory item details
/// - [expenseTableName]: Stores expense records
/// - [recentActivityTableName]: Tracks system activity history
class DatabaseHelper {
  /// Singleton instance of the database helper.
  ///
  /// Access this instance to perform all database operations.
  static final DatabaseHelper instance = DatabaseHelper._init();

  /// Internal database instance cache.
  ///
  /// This is null when the database is not yet initialized.
  static Database? _database;

  /// Name of the database file on disk.
  final String databasePath = 'sahibz.db';

  /// Private constructor to prevent direct instantiation.
  ///
  /// Use [instance] to access the singleton.
  DatabaseHelper._init();

  /// Gets the database instance, initializing it if necessary.
  ///
  /// Returns a [Future] that completes with the [Database] instance.
  /// If the database is already open, returns the cached instance.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(databasePath);
    return _database!;
  }

  /// Initializes the database by opening or creating it.
  ///
  /// [filePath] - The name of the database file.
  ///
  /// Returns a [Future] that completes with the opened [Database].
  /// The database version is set to 1 and [onCreate] is called if the
  /// database is newly created.
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: createDB);
  }

  /// Name of the inventory items table.
  final String inventoryTableName = 'inventory';

  /// Name of the expense records table.
  final String expenseTableName = 'expense';

  /// Name of the recent activity tracking table.
  final String recentActivityTableName = 'recent_activity';

  /// Creates the database tables with their schema definitions.
  ///
  /// [db] - The database instance to create tables in.
  /// [version] - The database version number.
  ///
  /// This method creates three tables:
  /// - Inventory table: Stores product items with auto-generated labels
  /// - Expense table: Tracks financial expenses
  /// - Recent activity table: Logs system activities for auditing
  ///
  /// The inventory table uses a unique 8-character alphanumeric label
  /// generated automatically for each item.
  Future createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const numType = 'REAL NOT NULL';

    // Inventory table with auto-generated unique labels
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $inventoryTableName (
        id $idType,
        label TEXT UNIQUE DEFAULT (UPPER(SUBSTR(HEX(RANDOMBLOB(8)), 1, 8))),
        name $textType,
        company $textType,
        unit $textType,
        date $textType,
        update_date TEXT
      )
    ''');

    // Expense table for tracking financial records
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $expenseTableName (
        id $idType,
        title $textType,
        amount $numType,
        description $textType,
        date $textType
      )
    ''');

    // Recent activity table for system audit trail
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $recentActivityTableName (
        id $idType,
        type $textType,
        date $textType
      )
    ''');
  }

  /// Closes the database connection.
  ///
  /// Returns a [Future] that completes when the database is closed.
  /// This method should be called when the database is no longer needed
  /// to free up resources. The database can be reopened by calling [database] again.
  Future close() async {
    final db = await instance.database;
    db.close();
  }

  /// Permanently deletes the database file from disk.
  ///
  /// This method:
  /// 1. Closes the current database connection
  /// 2. Deletes the physical database file
  ///
  /// Warning: This action cannot be undone. All data will be permanently lost.
  /// The database will be recreated with default schema on next access.
  ///
  /// Returns a [Future] that completes when the database is deleted.
  Future<void> deleteDb() async {
    await close();
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, databasePath);
    await deleteDatabase(path);
  }
}
