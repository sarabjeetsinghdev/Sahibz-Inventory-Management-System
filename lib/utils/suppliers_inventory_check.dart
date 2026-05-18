// ignore_for_file: use_build_context_synchronously

import 'package:sahibz_inventory_management_system/dialogs/core/coredialog_framework.dart';
import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';
import 'package:sahibz_inventory_management_system/services/core_service.dart';
import 'package:flutter/cupertino.dart';

/// Checks if there are any items in the inventory and if there are any suppliers
/// Returns true if both exist, false otherwise
/// 
/// Parameters:
/// - `context`: The build context
/// - `storageSetter`: The storage setter
Future<bool> suppliersInventoryCheck({
  required BuildContext context,
  required FlutterStorageSetter storageSetter,
}) async {
  /// Initialize errors list
  final errors = [];

  /// Get all items from inventory
  final items = (await CoreService(tableName: .inventory).getAll());
  final itemsList = items.map((e) => e['name'] as String).toList();

  /// Get all suppliers
  final suppliers = await CoreService(tableName: .supplier).getAll();
  final supplierIds = suppliers
      .map((supplier) => supplier['supplier_id'] as String)
      .toList();

  /// Check if there are any items in the inventory
  if (itemsList.isEmpty) errors.add('No items found in inventory');

  /// Check if there are any suppliers
  if (supplierIds.isEmpty) errors.add('No suppliers found');


  if (errors.isNotEmpty) {
    CoreDialogFramework(
      context: context,
      title: 'Error',
      titleColor: CupertinoColors.systemRed,
      storageSetter: storageSetter,
      content: Padding(
        padding: .only(bottom: 20.0),
        child: Text(errors.join('\n'), textAlign: .center,),
      ),
    );
    return false;
  }

  /// Return true if both exist
  return true;
}