// import 'package:sahibz_inventory_management_system/models/recent_activity.dart';
import 'package:sahibz_inventory_management_system/services/core_service.dart';

class RecentactivityService {
  final CoreService core = CoreService(tableName: 'recent_activity');

  Future<int> count({
    String? where,
    List<Object?>? whereArgs,
  }) async {
    return await core.countTotal();
  }

  Future<List<Map<String, Object?>>> getAll() async {
    return await core.getAll();
  }

  // Future<int> insert({required RecentActivity recentActivity}) async {
  //   Map<String, Object?> data = recentActivity.toJson();
  //   data.remove('id');
  //   return await core.insert(data: data);
  // }

  // Future<int> update({
  //   required int id,
  //   required RecentActivity recentActivity,
  //   String? idColumnName,
  // }) async {
  //   return await core.update(
  //     id: id,
  //     data: recentActivity.toJson(),
  //     idColumnName: idColumnName,
  //   );
  // }

  // Future<int> delete({required int id, String? idColumnName}) async {
  //   return await core.delete(id: id, idColumnName: idColumnName);
  // }
}
