// ignore_for_file: use_build_context_synchronously, no_leading_underscores_for_local_identifiers

import 'package:flutter/cupertino.dart';
import 'package:sahibz_inventory_management_system/database_helper.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:sahibz_inventory_management_system/models/sale.dart';
import 'package:sahibz_inventory_management_system/models/sale_item.dart';
import 'package:sahibz_inventory_management_system/services/core_service.dart';
import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';

class SaleService extends CoreService {
  SaleService() : super(tableName: .sale);

  Future<List<Map<String, dynamic>>> getBySaleId(String saleId) async {
    return await getControlled(where: 'sale_id = ?', whereArgs: [saleId]);
  }

  Future<bool> insertSalesWithItems({
    required Sale sale,
    required List<SaleItem> items,
    required FlutterStorageSetter flutterStorageSetter,
    required BuildContext context,
  }) async {
    try {
      /// Initializa database
      final _database = await DatabaseHelper.instance.database;

      /// Prepare sale data
      final _sale = sale.toJson();
      for (var key in ['id', 'sale_id', 'reference_number', 'net_total']) {
        _sale.remove(key);
      }

      /// Prepare sale items data
      final _items = items.map((item) {
        final _item = item.toJson();
        for (var key in [
          'id',
          'sale_id',
          'unique_id',
          'net_total',
          'net_profit',
        ]) {
          _item.remove(key);
        }
        return _item;
      }).toList();

      return await _database.transaction<bool>((txn) async {
        // Insert sale
        final _saleResultId = await txn.insert(
          tableName.value,
          _sale,
          conflictAlgorithm: .rollback,
        );
        if (_saleResultId == 0) {
          throw Exception('Failed to insert sale');
        }

        // Get the sale ID
        final _saleId = (await txn.query(
          tableName.value,
          where: 'id = ?',
          whereArgs: [_saleResultId],
        )).first['sale_id'];

        // Insert sale items
        final DatabaseTableNames saleItemsTable = .saleItem;
        for (var item in _items) {
          item['sale_id'] = _saleId;
          final _saleItemResult = await txn.insert(
            saleItemsTable.value,
            item,
            conflictAlgorithm: .rollback,
          );
          if (_saleItemResult == 0) {
            throw Exception('Failed to insert sale item');
          }
        }

        // Reduce quantity in purchase items
        for (var item in _items) {
          // Get purchase id and supplier id from each sale item
          final purchaseId = item['purchase_id'];
          final supplierId = item['supplier_id'];

          if (purchaseId == null || supplierId == null) {
            throw Exception('Purchase id or supplier id is null');
          }

          // Get purchase items where sale item purchase id and supplier id matches
          final purchaseItems = await txn.query(
            DatabaseTableNames.purchaseItem.value,
            where: 'purchase_id = ? AND supplier_id = ?',
            whereArgs: [purchaseId, supplierId],
          );

          if (purchaseItems.isEmpty) {
            throw Exception(
              'No purchase items found for purchase id $purchaseId and supplier id $supplierId',
            );
          }

          // Reduce their quantity_left from 
          for (var purchaseItem in purchaseItems) {
            final quantityLeft = double.tryParse(purchaseItem['quantity_left'].toString());
            final quantity = double.tryParse(item['quantity'].toString());
            if (quantityLeft == null || quantity == null) {
              throw Exception('Quantity left or quantity is null');
            }
            if (quantityLeft < quantity) {
              throw Exception('Quantity left is less than quantity');
            }

            final newQuantityLeft = quantityLeft - quantity;
        // Reduce their quantity_left from quantity
            await txn.update(
              DatabaseTableNames.purchaseItem.value,
              {'quantity_left': newQuantityLeft},
              where: 'id = ?',
              whereArgs: [int.parse(purchaseItem['id'].toString())],
              conflictAlgorithm: .rollback,
            );
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

  Future<bool> updateSalesWithItems({
    required Sale sale,
    required List<SaleItem> items,
    required BuildContext context,
    required FlutterStorageSetter flutterStorageSetter,
    required bool isUpdatedList,
  }) async {
    try {
      /// Initialize database
      final _database = await DatabaseHelper.instance.database;

      /// Prepare sale data
      final _sale = sale.toJson();
      for (var key in ['net_total']) {
        _sale.remove(key);
      }

      /// Prepare sale items data
      final _items = items.map((item) {
        final _item = item.toJson();
        for (var key in ['id', 'sale_id', 'net_total', 'net_profit']) {
          _item.remove(key);
        }
        return _item;
      }).toList();

      return await _database.transaction<bool>((txn) async {
        // Update sale
        final _saleResult = await txn.update(
          tableName.value,
          _sale,
          where: 'id = ?',
          whereArgs: [sale.id],
          conflictAlgorithm: .rollback,
        );
        if (_saleResult == 0) {
          throw Exception('Failed to update sale');
        }

        // Get the sale ID
        final _saleId = sale.saleId;

        // If sale items are updated
        if (isUpdatedList) {
          // Update sale items
          final _saleItemsTableName = DatabaseTableNames.saleItem.value;

          // Get all items from database with this saleId
          final List<Map<String, dynamic>> _existingItems = await txn.query(
            _saleItemsTableName,
            where: 'sale_id = ?',
            whereArgs: [_saleId],
          );

          // In case, item is added
          // Compare with _items and add new items
          // Add new items
          for (var item in _items) {
            if (!_existingItems.any(
              (e) => e['unique_id'] == item['unique_id'],
            )) {
              item['sale_id'] = _saleId;
              final _saleItemResult = await txn.insert(
                _saleItemsTableName,
                item,
                conflictAlgorithm: .rollback,
              );
              if (_saleItemResult == 0) {
                throw Exception('Failed to insert sale item during updation');
              }
            }
          }

          // In case, item is removed
          // Compare with _existingItems and remove items
          // Remove items
          for (var item in _existingItems) {
            if (!_items.any((e) => e['unique_id'] == item['unique_id'])) {
              final _saleItemResult = await txn.delete(
                _saleItemsTableName,
                where: 'unique_id = ?',
                whereArgs: [item['unique_id']],
              );
              if (_saleItemResult == 0) {
                throw Exception('Failed to delete sale item during updation');
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

  Future<bool> deleteSaleWithItems({
    required String saleId,
    required BuildContext context,
    required FlutterStorageSetter flutterStorageSetter,
  }) async {
    try {
      /// Initialize database
      final _database = await DatabaseHelper.instance.database;

      /// Initialize transaction
      await _database.transaction((txn) async {
        /// Delete sale items
        await txn.delete(
          DatabaseTableNames.saleItem.value,
          where: 'sale_id = ?',
          whereArgs: [saleId],
        );

        /// Delete sale
        await txn.delete(
          DatabaseTableNames.sale.value,
          where: 'sale_id = ?',
          whereArgs: [saleId],
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
