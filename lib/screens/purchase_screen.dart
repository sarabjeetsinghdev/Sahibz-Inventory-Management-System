// ignore_for_file: use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:sahibz_inventory_management_system/database_helper.dart';
import 'package:sahibz_inventory_management_system/dialogs/delete_confirm_dialog.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:sahibz_inventory_management_system/dialogs/purchase_item_dialog.dart';
import 'package:sahibz_inventory_management_system/dialogs/success_dialog.dart';
import 'package:sahibz_inventory_management_system/models/purchase.dart';
import 'package:sahibz_inventory_management_system/models/purchase_item.dart';
import 'package:sahibz_inventory_management_system/services/core_service.dart';
import 'package:sahibz_inventory_management_system/services/purchase_service.dart';
import 'package:sahibz_inventory_management_system/shared/shared_screen/index.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';

class PurchaseScreen extends StatefulWidget {
  final FlutterStorageSetter flutterStorage;
  const PurchaseScreen({super.key, required this.flutterStorage});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  late FlutterStorageSetter flutterStorage;

  final List<Purchase> purchaseList = [];
  final List<Purchase> searchReservedPurchaseList = [];

  final List<PurchaseItem> purchaseItems = [];
  final List<PurchaseItem> searchReservedPurchaseItems = [];

  static const String defaultPurchaseTitle = 'PURCHASES';
  static const String defaultPurchaseItemTitle = 'PURCHASE ITEMS';

  String title = '';

  @override
  void initState() {
    super.initState();
    flutterStorage = widget.flutterStorage;
    title = defaultPurchaseTitle;
    init();
  }

  void init({String? purchaseId}) async {
    switch (title) {
      case defaultPurchaseTitle:
        // Load purchases
        final purchases = await PurchaseService().getAll();
        setState(() {
          purchaseList.clear();
          purchaseList.addAll(purchases.map((p) => Purchase.fromJson(p)));
          searchReservedPurchaseList.clear();
          searchReservedPurchaseList.addAll(
            purchases.map((p) => Purchase.fromJson(p)),
          );
        });
        break;
      case defaultPurchaseItemTitle:
        if (purchaseId == null) {
          ErrorDialog(
            context: context,
            error: 'Purchase ID is required',
            storageSetter: flutterStorage,
          );
          return;
        }
        // Load purchase items
        final purchaseItems = await PurchaseItemService().getByPurchaseId(
          purchaseId,
        );
        setState(() {
          this.purchaseItems.clear();
          this.purchaseItems.addAll(
            purchaseItems.map((item) => PurchaseItem.fromJson(item)),
          );
          searchReservedPurchaseItems.clear();
          searchReservedPurchaseItems.addAll(
            purchaseItems.map((item) => PurchaseItem.fromJson(item)),
          );
        });
    }
  }

  @override
  void dispose() {
    super.dispose();
    purchaseList.clear();
    searchReservedPurchaseList.clear();
    purchaseItems.clear();
    searchReservedPurchaseItems.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SharedScreen(
      title: title,
      data: title == defaultPurchaseTitle
          ? purchaseList.map((purchase) => purchase.toJson()).toList()
          : purchaseItems.map((item) => item.toJson()).toList(),
      searchReserveddata: title == defaultPurchaseTitle
          ? searchReservedPurchaseList
                .map((purchase) => purchase.toJson())
                .toList()
          : searchReservedPurchaseItems.map((item) => item.toJson()).toList(),
      onRefresh: () => init(
        purchaseId: title == defaultPurchaseTitle
            ? null
            : purchaseItems.isEmpty
            ? null
            : purchaseItems.first.purchaseId,
      ),
      dbTableName: title == defaultPurchaseTitle
          ? DatabaseTableNames.purchase
          : DatabaseTableNames.purchaseItem,
      storageSetter: widget.flutterStorage,
      isDefaultHeader: true,
      onRowTap: (row) {
        if (title == defaultPurchaseTitle) {
          // Navigate to purchase items screen
          setState(() {
            title = defaultPurchaseItemTitle;
            init(purchaseId: row['purchase_id']);
          });
          return;
        }
      },
      backButton: title == defaultPurchaseItemTitle
          ? CustomMouseCursor(
              child: CupertinoButton.filled(
                sizeStyle: .medium,
                borderRadius: .circular(8.0),
                onPressed: () {
                  if (title == defaultPurchaseItemTitle) {
                    setState(() {
                      title = defaultPurchaseTitle;
                      init();
                    });
                  }
                },
                child: Row(
                  children: [
                    Icon(CupertinoIcons.back),
                    SizedBox(width: 4),
                    Text('Back'),
                  ],
                ),
              ),
            )
          : null,
      onAdd: (onadd) {
        PurchaseItemDialog(
          context: context,
          purchaseList: null,
          searchReservedPurchaseList: null,
          purchaseItemList: null,
          searchReservedPurchaseItemList: null,
          storageSetter: widget.flutterStorage,
          isUpdate: false,
          onAdd: onadd,
        );
      },
      onUpdate: title == defaultPurchaseTitle
          ? (onupdate, data) async {
              // Handle update for purchases
              final items = await CoreService(tableName: .purchaseItem)
                  .getControlled(
                    where: 'purchase_id = ?',
                    whereArgs: [data['purchase_id']],
                  );
              final purchaseItems = items
                  .map((item) => PurchaseItem.fromJson(item))
                  .toList();
              final searchReservedItems = List<PurchaseItem>.from(
                purchaseItems,
              );

              PurchaseItemDialog(
                context: context,
                storageSetter: widget.flutterStorage,
                purchaseList: null,
                searchReservedPurchaseList: null,
                purchaseItemList: purchaseItems.isNotEmpty
                    ? purchaseItems
                    : null,
                searchReservedPurchaseItemList: searchReservedItems.isNotEmpty
                    ? searchReservedItems
                    : null,
                isUpdate: true,
                onAdd: onupdate,
                purchase: Purchase.fromJson(data),
              );
            }
          : null,
      onDelete: title == defaultPurchaseTitle
          ? (ondelete, _, purchaseId, _) {
              // Handle delete
              DeleteConfirmDialog(
                context: context,
                ondelete: () async {
                  await PurchaseService().deletePurchaseWithItems(
                    purchaseId: purchaseId!,
                    context: context,
                    flutterStorageSetter: widget.flutterStorage,
                  );
                  ondelete();
                  Navigator.of(context).pop();
                  SuccessDialog(
                    context: context,
                    success: 'Purchase deleted successfully',
                    storageSetter: widget.flutterStorage,
                  );
                },
                storageSetter: widget.flutterStorage,
              );
            }
          : null,
    );
  }
}
