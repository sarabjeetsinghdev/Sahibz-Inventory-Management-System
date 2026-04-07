// ignore_for_file: non_constant_identifier_names

import 'package:sahibz_inventory_management_system/database_helper.dart';
import 'package:sahibz_inventory_management_system/models/recent_activity.dart';

class CoreService {
  String tableName;
  String recentActivityTableName =
      DatabaseHelper.instance.recentActivityTableName;
  CoreService({required this.tableName});

  final _database = DatabaseHelper.instance.database;

  Future<List<Map<String, Object?>>> getControlled({
    int? limit,
    int? offset,
    String? where,
    List<Object?>? whereArgs,
  }) async {
    return await (await _database).query(
      tableName,
      limit: limit,
      offset: offset,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<num> totalExpenses() async {
    return await (await _database)
        .rawQuery('SELECT SUM(amount) FROM $tableName')
        .then((value) => value.first.values.first as num? ?? 0);
  }

  Future<int> countTotal() async {
    return await (await _database)
        .rawQuery('SELECT COUNT(*) FROM $tableName')
        .then((value) => value.first.values.first as int? ?? 0);
  }

  Future<List<Map<String, Object?>>> getAll() async {
    return await (await _database).query(tableName);
  }

  Future<int> insert({
    required Map<String, Object?> data,
    required RecentActivityType type,
  }) async {
    int id = await (await _database).insert(
      tableName,
      data,
      conflictAlgorithm: .rollback,
    );
    if (!(id > 0)) {
      throw Exception('Insert failed');
    }
    final recent_activity = RecentActivity(
      id: 0,
      type: type,
      title: type.value,
      date: DateTime.now(),
    ).toJson();
    recent_activity.remove('id');
    int id2 = await (await _database).insert(
      recentActivityTableName,
      recent_activity,
      conflictAlgorithm: .rollback,
    );
    return id2;
  }

  Future<int> update({
    required int id,
    String? idColumnName,
    required RecentActivityType type,
    required Map<String, Object?> data,
  }) async {
    int idd = await (await _database).update(
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
      title: type.value,
      date: DateTime.now(),
    ).toJson();
    recent_activity.remove('id');
    int id2 = await (await _database).insert(
      recentActivityTableName,
      recent_activity,
      conflictAlgorithm: .rollback,
    );
    if (!(id2 > 0)) {
      throw Exception('Update failed');
    }
    return id2;
  }

  Future<int> delete({required int id, String? idColumnName, required RecentActivityType type}) async {
    int idd = await (await _database).delete(
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
      title: type.value,
      date: DateTime.now(),
    ).toJson();
    recent_activity.remove('id');
    int id2 = await (await _database).insert(
      recentActivityTableName,
      recent_activity,
      conflictAlgorithm: .rollback,
    );
    if (!(id2 > 0)) {
      throw Exception('Delete failed');
    }
    return id2;
  }
}
