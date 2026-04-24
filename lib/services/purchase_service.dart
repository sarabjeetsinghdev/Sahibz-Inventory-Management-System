// ignore_for_file: non_constant_identifier_names

import 'package:sahibz_inventory_management_system/services/core_service.dart';
import 'package:sahibz_inventory_management_system/models/purchase_item.dart';
import 'package:sahibz_inventory_management_system/database_helper.dart';
import 'package:sahibz_inventory_management_system/models/purchase.dart';

class PurchaseService extends CoreService {
  PurchaseService() : super(tableName: .purchase);

  Future<List<Map<String, dynamic>>> getByPurchaseId(String purchaseId) async {
    return await getControlled(
      where: 'purchase_id = ?',
      whereArgs: [purchaseId],
    );
  }

  Future<int> insertPurchasesWithItems({
    required Purchase purchase,
    required List<PurchaseItem> items,
  }) async {
    /// Transaction with purchase insert
    return (await DatabaseHelper.instance.database).transaction((txn) async {
      var purchaseJson = purchase.toJson();
      purchaseJson.remove('id');
      purchaseJson.remove('purchase_id');
      purchaseJson.remove('total_cost_after_tax');
      purchaseJson.remove('grand_total');
      int purchaseId = await txn.insert(
        tableName.value,
        purchaseJson,
        conflictAlgorithm: .rollback,
      );
      if (purchaseId <= 0) {
        throw Exception('Insert failed for purchase');
      }

      // query actual purchase id from table
      var queryResult = await txn.query(
        tableName.value,
        where: 'id = ?',
        whereArgs: [purchaseId],
      );
      if (queryResult.isEmpty) {
        throw Exception('Purchase not found in table');
      }
      String purchaseIdd = queryResult.first['purchase_id'].toString();

      // remove id, unique_id, total from itemsJson
      List<Map<String, Object?>> itemsJson = items
          .map((item) => item.toJson())
          .toList();
      for (var itemJson in itemsJson) {
        itemJson.remove('id');
        itemJson.remove('unique_id');
        itemJson.remove('total');
        itemJson['purchase_id'] = purchaseIdd;

        // insert items into purchase_item table
        int itemId = await txn.insert(
          DatabaseTableNames.purchaseItem.value,
          itemJson,
          conflictAlgorithm: .rollback,
        );
        if (itemId <= 0) {
          throw Exception('Insert failed for purchase item');
        }
      }
      return purchaseId;
    });
  }

  Future<int> updatePurchasesWithItems({
    required Purchase purchase,
    required List<PurchaseItem> items,
  }) async {
    return (await DatabaseHelper.instance.database).transaction((txn) async {
      // Update purchase
      int id;
      id = await txn.update(
        tableName.value,
        purchase.toJson(),
        where: 'id = ?',
        whereArgs: [purchase.id],
        conflictAlgorithm: .rollback,
      );

      // check if update was successful
      if (id <= 0) {
        throw Exception('Update failed!!!');
      }

      // Get items by purchase id
      var itemsQuery = await txn.query(
        DatabaseTableNames.purchaseItem.value,
        where: 'purchase_id = ?',
        whereArgs: [purchase.id],
      );
      if (itemsQuery.isEmpty) {
        throw Exception('Items not found in table');
      }

      // delete extra items
      if (itemsQuery.length > items.length) {
        for (var item in itemsQuery) {
          bool found = false;
          for (var item2 in items) {
            if (item['id'] == item2.id) {
              found = true;
              break;
            }
          }
          if (!found) {
            int id3 = await txn.delete(
              DatabaseTableNames.purchaseItem.value,
              where: 'id = ?',
              whereArgs: [item['id']],
            );
            if (id3 <= 0) {
              throw Exception('Delete failed!!!');
            }
          }
        }
      }

      // Update items
      for (var item in items) {
        int id2;
        id2 = await txn.update(
          DatabaseTableNames.purchaseItem.value,
          item.toJson(),
          where: 'purchase_id = ?',
          whereArgs: [item.purchaseId],
          conflictAlgorithm: .rollback,
        );

        // check if update was successful
        if (id2 <= 0) {
          throw Exception('Update failed!!!');
        }
      }
      return 1;
    });
  }
}

class PurchaseItemService extends CoreService {
  PurchaseItemService() : super(tableName: .purchaseItem);

  Future<List<Map<String, dynamic>>> getByPurchaseId(String purchaseId) async {
    return await getControlled(
      where: 'purchase_id = ?',
      whereArgs: [purchaseId],
    );
  }
}
