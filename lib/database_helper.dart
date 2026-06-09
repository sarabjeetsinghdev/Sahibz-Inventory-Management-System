import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

enum DatabaseTableNames {
  // inventory
  inventory('inventory'),
  // expense
  expense('expense'),
  // recent activity
  recentactivity('recent_activity'),
  // supplier
  supplier('supplier'),
  // purchase
  purchase('purchase'),
  // purchase item
  purchaseItem('purchase_item'),
  // sale
  sale('sale'),
  // sale item
  saleItem('sale_item');

  const DatabaseTableNames(this.value);
  final String value;
}

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
  static final DatabaseHelper instance = DatabaseHelper.init();

  /// Internal database instance cache.
  ///
  /// This is null when the database is not yet initialized.
  static Database? _database;

  /// Name of the database file on disk.
  final String databasePath = 'sahibz.db';

  /// Private constructor to prevent direct instantiation.
  ///
  /// Use [instance] to access the singleton.
  DatabaseHelper.init();

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
  final String inventoryTableName = DatabaseTableNames.inventory.value;

  /// Name of the expense records table.
  final String expenseTableName = DatabaseTableNames.expense.value;

  /// Name of the recent activity tracking table.
  final String recentActivityTableName =
      DatabaseTableNames.recentactivity.value;

  // Supplier table
  final String supplierTableName = DatabaseTableNames.supplier.value;

  // Purchase table
  final String purchaseTableName = DatabaseTableNames.purchase.value;

  // Purchase item table
  final String purchaseItemTableName = DatabaseTableNames.purchaseItem.value;

  // Sale table
  final String saleTableName = DatabaseTableNames.sale.value;

  // Sale item table
  final String saleItemTableName = DatabaseTableNames.saleItem.value;

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
    const inventoryLabelUniqueDefaultType =
        'TEXT UNIQUE DEFAULT (UPPER(SUBSTR(HEX(RANDOMBLOB(8)), 1, 8)))';

    // Enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON;');

    // Inventory table with auto-generated unique labels
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $inventoryTableName (
        id $idType,
        label $inventoryLabelUniqueDefaultType,
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
        type $textType,
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

    // Supplier table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $supplierTableName (
        id $idType,
        supplier_id TEXT UNIQUE,
        name $textType,
        contact $textType,
        email $textType,
        address $textType,
        date $textType
      )
    ''');

    // Supplier id insert trigger
    await db.execute('''
    CREATE TRIGGER IF NOT EXISTS supplier_id_insert
    AFTER INSERT ON $supplierTableName
    FOR EACH ROW
    WHEN NEW.supplier_id IS NULL
    BEGIN
    UPDATE $supplierTableName
    SET supplier_id =
        '00' ||
        SUBSTR(CAST(ABS(RANDOM()) AS TEXT), 1, 4) || TRIM(UPPER(
            SUBSTR(
                TRIM(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                    LOWER(TRIM(NEW.name)),
                    'mr ',''),
                    'mrs ',''),
                    'ms ',''),
                    'dr ',''),
                    'miss ',''),
                    'prof ','')
                ),
            1,4)
        ))
    WHERE id = NEW.id;
    END;
    ''');

    await db.execute('''
    CREATE TRIGGER IF NOT EXISTS supplier_id_update
    AFTER UPDATE OF name ON $supplierTableName
    FOR EACH ROW
    BEGIN
    UPDATE $supplierTableName
    SET supplier_id =
        '00' ||
        SUBSTR(CAST(ABS(RANDOM()) AS TEXT), 1, 4) || TRIM(UPPER(
            SUBSTR(
                TRIM(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                    LOWER(TRIM(NEW.name)),
                    'mr ',''),
                    'mrs ',''),
                    'ms ',''),
                    'dr ',''),
                    'miss ',''),
                    'prof ','')
                ),
            1,4)
        ))
    WHERE id = NEW.id;
    END;
    ''');

    // Purchase table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $purchaseTableName (
        id $idType,
        purchase_id TEXT UNIQUE,
        invoice_number $textType,
        payment_method $textType,
        total_cost_before_tax $numType,
        total_tax_amount $numType,
        total_cost_after_tax REAL GENERATED ALWAYS AS (total_cost_before_tax + total_tax_amount) STORED,
        total_discount $numType,
        grand_total REAL GENERATED ALWAYS AS (total_cost_after_tax - total_discount) STORED,
        date $textType
      )
    ''');

    await db.execute('''
        CREATE TRIGGER IF NOT EXISTS generate_purchase_id
        AFTER INSERT ON $purchaseTableName
        FOR EACH ROW
        WHEN NEW.purchase_id IS NULL
        BEGIN
            UPDATE $purchaseTableName
            SET purchase_id = 'PUR' || UPPER(SUBSTR(HEX(RANDOMBLOB(6)), 1, 6))
            WHERE id = NEW.id;
        END;
    ''');

    // Purchase item table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $purchaseItemTableName (
        id $idType,
        purchase_id $textType,
        supplier_id $textType,
        unique_id TEXT UNIQUE DEFAULT (UPPER(SUBSTR(HEX(RANDOMBLOB(12)), 1, 12))),
        product_name $textType,
        cost $numType,
        quantity $numType,
        quantity_left $numType,
        discount $numType,
        tax $numType,
        selling_price $numType,
        total REAL GENERATED ALWAYS AS (quantity * cost + tax - discount) STORED,
        date $textType,

        FOREIGN KEY (purchase_id) REFERENCES purchase(purchase_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

        FOREIGN KEY (supplier_id) REFERENCES supplier(supplier_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
        )
    ''');

    // Sale table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $saleTableName (
        id $idType,
        sale_id TEXT UNIQUE,
        reference_number TEXT UNIQUE DEFAULT (UPPER(SUBSTR(HEX(RANDOMBLOB(6)), 1, 6))),
        payment_method $textType,
        gross_total $numType,
        total_tax $numType,
        total_discount $numType,
        net_total REAL GENERATED ALWAYS AS (gross_total + total_tax - total_discount) STORED,
        date $textType
      )
    ''');

    await db.execute('''
        CREATE TRIGGER IF NOT EXISTS generate_sale_id
        AFTER INSERT ON $saleTableName
        FOR EACH ROW
        WHEN NEW.sale_id IS NULL
        BEGIN
            UPDATE $saleTableName
            SET sale_id = 'SL' || UPPER(SUBSTR(HEX(RANDOMBLOB(6)), 1, 6))
            WHERE id = NEW.id;
        END;
    ''');

    // Sale item table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $saleItemTableName (
        id $idType,
        sale_id $textType,
        purchase_id $textType,
        supplier_id $textType,
        unique_id TEXT UNIQUE DEFAULT (UPPER(SUBSTR(HEX(RANDOMBLOB(12)), 1, 12))),
        product_name $textType,
        quantity $numType,
        price $numType,
        discount $numType,
        tax $numType,
        net_total REAL GENERATED ALWAYS AS (quantity * cost + tax - discount) STORED,
        net_profit REAL GENERATED ALWAYS AS (net_total - (quantity * cost)) STORED,
        cost $numType,
        date $textType,

        FOREIGN KEY (sale_id) REFERENCES sale(sale_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
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
