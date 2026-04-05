import 'package:sahibz_inventory_management_system/database_helper.dart';

class CoreService {
  String tableName;
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
    return await (await _database).rawQuery(
      'SELECT SUM(amount) FROM $tableName',
    ).then((value) => value.first.values.first as num? ?? 0);
  }

  Future<int> countTotal() async {
    return await (await _database).rawQuery(
      'SELECT COUNT(*) FROM $tableName'
    ).then((value) => value.first.values.first as int? ?? 0);
  }

  Future<List<Map<String, Object?>>> getAll() async {
    return await (await _database).query(tableName);
  }

  Future<int> insert({required Map<String, Object?> data}) async {
    return await (await _database).insert(
      tableName,
      data,
      conflictAlgorithm: .rollback,
    );
  }

  Future<int> update({
    required int id,
    String? idColumnName,
    required Map<String, Object?> data,
  }) async {
    return await (await _database).update(
      tableName,
      data,
      where: '${idColumnName ?? 'id'} = ?',
      whereArgs: [id],
      conflictAlgorithm: .rollback,
    );
  }

  Future<int> delete({required int id, String? idColumnName}) async {
    return await (await _database).delete(
      tableName,
      where: '${idColumnName ?? 'id'} = ?',
      whereArgs: [id],
    );
  }
}
