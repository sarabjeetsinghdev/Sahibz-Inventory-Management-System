// ignore_for_file: use_build_context_synchronously, no_leading_underscores_for_local_identifiers, non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:sahibz_inventory_management_system/services/core_service.dart';
import 'package:sahibz_inventory_management_system/models/purchase_item.dart';
import 'package:sahibz_inventory_management_system/database_helper.dart';
import 'package:sahibz_inventory_management_system/models/purchase.dart';
import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';

class PurchaseService extends CoreService {
  PurchaseService() : super(tableName: .purchase);

  Future<List<Map<String, dynamic>>> getByPurchaseId(String purchaseId) async {
    return await getControlled(
      where: 'purchase_id = ?',
      whereArgs: [purchaseId],
    );
  }

  Future<bool> insertPurchasesWithItems({
    required Purchase purchase,
    required List<PurchaseItem> items,
    required FlutterStorageSetter flutterStorageSetter,
    required BuildContext context,
  }) async {
    try {
      /// Initialize database
      final _database = await DatabaseHelper.instance.database;

      /// Prepare purchase data
      final _purchase = purchase.toJson();
      for (var key in [
        'id',
        'purchase_id',
        'total_cost_after_tax',
        'grand_total',
      ]) {
        _purchase.remove(key);
      }

      /// Prepare purchase items data
      final _items = items.map((item) {
        final _item = item.toJson();
        for (var key in ['id', 'purchase_id', 'unique_id', 'total']) {
          _item.remove(key);
        }
        return _item;
      }).toList();

      /// Insert purchase and items in transaction
      return await _database.transaction<bool>((txn) async {
        // Insert purchase
        final _purchaseResultId = await txn.insert(
          tableName.value,
          _purchase,
          conflictAlgorithm: .rollback,
        );
        if (_purchaseResultId == 0) {
          throw Exception('Failed to insert purchase');
        }

        // Get the purchase ID
        final _purchaseId = (await txn.query(
          tableName.value,
          where: 'id = ?',
          whereArgs: [_purchaseResultId],
        )).first['purchase_id'];

        // Insert purchase items
        final DatabaseTableNames purchaseItemsTable = .purchaseItem;
        for (var item in _items) {
          item['purchase_id'] = _purchaseId;
          final _purchaseItemResult = await txn.insert(
            purchaseItemsTable.value,
            item,
            conflictAlgorithm: .rollback,
          );
          if (_purchaseItemResult == 0) {
            throw Exception('Failed to insert purchase item');
          }
        }
        return true;
      });
    } catch (e) {
      ErrorDialog(
        context: context,
        error: e.toString(),
        storageSetter: flutterStorageSetter,
      );
      return false;
    }
  }

  Future<bool> updatePurchasesWithItems({
    required Purchase purchase,
    required List<PurchaseItem> items,
    required BuildContext context,
    required FlutterStorageSetter flutterStorageSetter,
    required bool isUpdatedList,
  }) async {
    try {
      /// Initialize database
      final _database = await DatabaseHelper.instance.database;

      /// Prepare purchase data
      final _purchase = purchase.toJson();
      for (var key in ['total_cost_after_tax', 'grand_total']) {
        _purchase.remove(key);
      }

      /// Prepare purchase items data
      final _items = items.map((item) {
        final _item = item.toJson();
        for (var key in ['id', 'purchase_id', 'unique_id', 'total']) {
          _item.remove(key);
        }
        return _item;
      }).toList();

      /// Update purchase and items in transaction
      return await _database.transaction<bool>((txn) async {
        // Update purchase
        final _purchaseResultId = await txn.update(
          tableName.value,
          _purchase,
          where: 'id = ?',
          whereArgs: [purchase.id],
          conflictAlgorithm: .rollback,
        );
        if (_purchaseResultId == 0) {
          throw Exception('Failed to update purchase');
        }

        // Update purchase items
        final _purchaseId = purchase.purchaseId;

        // If purchase items are updated
        if (isUpdatedList) {
          final _purchaseItemsTableName = DatabaseTableNames.purchaseItem.value;
          // GET all items from database with this purchaseId
          final List<Map<String, dynamic>> _existingItems = await txn.query(
            _purchaseItemsTableName,
            where: 'purchase_id = ?',
            whereArgs: [_purchaseId],
          );

          // In case, item is added
          // Compare with _items and add new items
          // Add new items
          for (var item in _items) {
            if (!_existingItems.any(
              (e) => e['unique_id'] == item['unique_id'],
            )) {
              item['purchase_id'] = _purchaseId;
              final _purchaseItemResult = await txn.insert(
                _purchaseItemsTableName,
                item,
                conflictAlgorithm: .rollback,
              );
              if (_purchaseItemResult == 0) {
                throw Exception('Failed to add purchase item during updation');
              }
            }
          }

          // In case, item is removed
          // GET all items from database with this purchaseId
          // Compare with _items and remove items that are not in _items
          for (var item in _existingItems) {
            if (!_items.any((e) => e['unique_id'] == item['unique_id'])) {
              final _purchaseItemResult = await txn.delete(
                _purchaseItemsTableName,
                where: 'unique_id = ?',
                whereArgs: [item['unique_id']],
              );

              if (_purchaseItemResult == 0) {
                throw Exception(
                  'Failed to remove purchase item during updation',
                );
              }
            }
          }
        }
        return true;
      });
    } catch (e) {
      ErrorDialog(
        context: context,
        error: e.toString(),
        storageSetter: flutterStorageSetter,
      );
      return false;
    }
  }

  Future<bool> deletePurchaseWithItems({
    required String purchaseId,
    required BuildContext context,
    required FlutterStorageSetter flutterStorageSetter,
  }) async {
    try {
      /// Initialize database
      final _database = await DatabaseHelper.instance.database;

      /// Initialize transaction
      await _database.transaction((txn) async {
        /// Delete purchase items
        await txn.delete(
          DatabaseTableNames.purchaseItem.value,
          where: 'purchase_id = ?',
          whereArgs: [purchaseId],
        );

        /// Delete purchase
        await txn.delete(
          DatabaseTableNames.purchase.value,
          where: 'purchase_id = ?',
          whereArgs: [purchaseId],
        );
      });
      return true;
    } catch (e) {
      ErrorDialog(
        context: context,
        error: e.toString(),
        storageSetter: flutterStorageSetter,
      );
      return false;
    }
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
