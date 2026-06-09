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
Future<bool> purchaseCheck({
  required BuildContext context,
  required FlutterStorageSetter storageSetter,
}) async {

  /// Get all items from purchases
  final purchases = (await CoreService(tableName: .purchase).getAll());
  final purchaseList = purchases.map((e) => e['name'] as String).toList();

  /// Check if there are any items in the inventory
  if (purchaseList.isEmpty) {
    CoreDialogFramework(
      context: context,
      title: 'Error',
      titleColor: CupertinoColors.systemRed,
      storageSetter: storageSetter,
      content: Padding(
        padding: .only(bottom: 20.0),
        child: Text('No items found in purchases', textAlign: .center,),
      ),
    );
    return false;
  }

  /// Return true if both exist
  return true;
}