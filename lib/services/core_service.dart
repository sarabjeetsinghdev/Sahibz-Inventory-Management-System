// ignore_for_file: non_constant_identifier_names

import 'package:sahibz_inventory_management_system/database_helper.dart';
import 'package:sahibz_inventory_management_system/models/recent_activity.dart';

/// Core service class that provides base database operations for all entity services.
///
/// This class serves as the foundation for [InventoryService], [ExpenseService],
/// and [RecentactivityService], providing common CRUD operations with automatic
/// activity logging for audit purposes.
///
/// Features:
/// - Generic CRUD operations (Create, Read, Update, Delete)
/// - Automatic recent activity logging
/// - Query building with filtering and pagination support
/// - Aggregate operations (count, sum)
///
/// Each operation automatically creates a corresponding entry in the recent
/// activity log to maintain a complete audit trail of system changes.
///
/// Usage:
/// ```dart
/// final coreService = CoreService(tableName: 'inventory');
/// final items = await coreService.getAll();
/// ```
class CoreService {
  /// Name of the database table this service operates on.
  final String tableName;

  /// Name of the recent activity table for audit logging.
  ///
  /// This is automatically retrieved from [DatabaseHelper] to ensure
  /// consistency across all services.
  final String recentActivityTableName =
      DatabaseHelper.instance.recentActivityTableName;

  /// Creates a new core service instance for the specified table.
  ///
  /// [tableName] - The name of the database table to operate on.
  CoreService({required this.tableName});

  /// Database instance getter for performing operations.
  ///
  /// Returns a [Future] that completes with the [Database] instance
  /// from the singleton [DatabaseHelper].
  final _database = DatabaseHelper.instance.database;

  /// Retrieves records with optional filtering and pagination.
  ///
  /// [limit] - Maximum number of records to return.
  /// [offset] - Number of records to skip before starting to return results.
  /// [where] - Optional WHERE clause for filtering.
  /// [whereArgs] - Arguments for the WHERE clause placeholders.
  /// [orderBy] - Optional ORDER BY clause for sorting.
  ///
  /// Returns a [Future] that completes with a list of maps containing
  /// the retrieved records.
  ///
  /// Example:
  /// ```dart
  /// final records = await getControlled(
  ///   limit: 10,
  ///   offset: 0,
  ///   where: 'status = ?',
  ///   whereArgs: ['active'],
  ///   orderBy: 'created_at DESC',
  /// );
  /// ```
  Future<List<Map<String, Object?>>> getControlled({
    int? limit,
    int? offset,
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  }) async {
    return await (await _database).query(
      orderBy: orderBy,
      tableName,
      limit: limit,
      offset: offset,
      where: where,
      whereArgs: whereArgs,
    );
  }

  /// Calculates the sum of the 'amount' column for all records.
  ///
  /// This is primarily used by the expense service to calculate total expenses.
  ///
  /// Returns a [Future] that completes with the sum of all amounts,
  /// or 0 if no records exist.
  Future<num> totalExpenses() async {
    return await (await _database)
        .rawQuery('SELECT SUM(amount) FROM expense')
        .then((value) => value.first.values.first as num? ?? 0);
  }

  /// Counts the total number of records in the table.
  ///
  /// Returns a [Future] that completes with the count of all records,
  /// or 0 if the table is empty.
  Future<int> countTotal() async {
    return await (await _database)
        .rawQuery('SELECT COUNT(*) FROM $tableName')
        .then((value) => value.first.values.first as int? ?? 0);
  }

  /// Retrieves all records from the table.
  ///
  /// Returns a [Future] that completes with a list of maps containing
  /// all records in the table.
  Future<List<Map<String, Object?>>> getAll() async {
    return await (await _database).query(tableName);
  }

  /// Inserts a new record into the table and logs the activity.
  ///
  /// [data] - Map containing the field names and values to insert.
  /// [type] - The type of activity to log for this insertion.
  ///
  /// Returns a [Future] that completes with the ID of the activity log entry.
  ///
  /// Throws an [Exception] if the insert operation fails.
  ///
  /// Note: The ID field in [data] is ignored; auto-increment is used.
  Future<int> insert({
    required Map<String, Object?> data,
    required RecentActivityType type,
  }) async {
    final txn = await (await _database).transaction((txn) async {
      int id = await txn.insert(tableName, data, conflictAlgorithm: .rollback);
      if (id <= 0) {
        throw Exception('Insert failed');
      }
      final recent_activity = RecentActivity(
        id: 0,
        type: type,
        date: DateTime.now(),
      ).toJson();
      recent_activity.remove('id');
      int id2 = await txn.insert(
        recentActivityTableName,
        recent_activity,
        conflictAlgorithm: .rollback,
      );
      if (id2 <= 0) {
        throw Exception('Insert failed');
      }
      return id2;
    });
    return txn;
  }

  /// Updates an existing record and logs the activity.
  ///
  /// [id] - The ID of the record to update.
  /// [idColumnName] - Optional custom column name for the ID field. Defaults to 'id'.
  /// [type] - The type of activity to log for this update.
  /// [data] - Map containing the updated field names and values.
  ///
  /// Returns a [Future] that completes with the ID of the activity log entry.
  ///
  /// Throws an [Exception] if the update operation fails or no rows were affected.
  Future<int> update({
    required int id,
    String? idColumnName,
    required RecentActivityType type,
    required Map<String, Object?> data,
  }) async {
    final txn = (await _database).transaction((txn) async {
      int idd = await txn.update(
        tableName,
        data,
        where: '${idColumnName ?? 'id'} = ?',
        whereArgs: [id],
        conflictAlgorithm: .rollback,
      );
      if (!(idd > 0)) {
        throw Exception('Update failed');
      }
      final recent_activity = RecentActivity(
        id: 0,
        type: type,
        date: DateTime.now(),
      ).toJson();
      recent_activity.remove('id');
      int id2 = await txn.insert(
        recentActivityTableName,
        recent_activity,
        conflictAlgorithm: .rollback,
      );
      if (!(id2 > 0)) {
        throw Exception('Update failed');
      }
      return id2;
    });
    return txn;
  }

  /// Deletes a record and logs the activity.
  ///
  /// [id] - The ID of the record to delete.
  /// [idColumnName] - Optional custom column name for the ID field. Defaults to 'id'.
  /// [type] - The type of activity to log for this deletion.
  ///
  /// Returns a [Future] that completes with the ID of the activity log entry.
  ///
  /// Throws an [Exception] if the delete operation fails or no rows were affected.
  Future<int> delete({
    required int id,
    String? idColumnName,
    required RecentActivityType type,
  }) async {
    final txn = (await _database).transaction((txn) async {
    int idd = await txn.delete(
      tableName,
      where: '${idColumnName ?? 'id'} = ?',
      whereArgs: [id],
    );
    if (!(idd > 0)) {
      throw Exception('Delete failed');
    }
    final recent_activity = RecentActivity(
      id: 0,
      type: type,
      date: DateTime.now(),
    ).toJson();
    recent_activity.remove('id');
    int id2 = await txn.insert(
      recentActivityTableName,
      recent_activity,
      conflictAlgorithm: .rollback,
    );
    if (!(id2 > 0)) {
      throw Exception('Delete failed');
    }
    return id2;
  });
    return txn;
  }
}
