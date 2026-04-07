import 'package:sahibz_inventory_management_system/models/recent_activity.dart';
import 'package:sahibz_inventory_management_system/services/core_service.dart';
import 'package:sahibz_inventory_management_system/models/inventory.dart';

class InventoryService {
  final CoreService core = CoreService(tableName: 'inventory');
  
  Future<int> count({
    String? where,
    List<Object?>? whereArgs,
  }) async {
    return await core.countTotal();
  }

  Future<List<Map<String, Object?>>> getAll() async {
    return await core.getAll();
  }

  Future<int> insert({required Inventory inventory}) async {
    Map<String, Object?> data = inventory.toJson();
    data.remove('id');
    data.remove('label');
    return await core.insert(data: data, type: RecentActivityType.inventoryAdded);
  }

  Future<int> update({
    required int id,
    required Inventory inventory,
    String? idColumnName,
  }) async {
    return await core.update(
      id: id,
      data: inventory.toJson(),
      idColumnName: idColumnName,
      type: RecentActivityType.inventoryUpdated,
    );
  }

  Future<int> delete({
    required int id,
    String? idColumnName,
  }) async {
    return await core.delete(id: id, idColumnName: idColumnName, type: RecentActivityType.inventoryRemoved);
  }
}
