// ignore_for_file: use_build_context_synchronously

import 'package:sahibz_inventory_management_system/dialogs/delete_confirm_dialog.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:sahibz_inventory_management_system/dialogs/sale_item_dialog.dart';
import 'package:sahibz_inventory_management_system/dialogs/success_dialog.dart';
import 'package:sahibz_inventory_management_system/models/sale.dart';
import 'package:sahibz_inventory_management_system/models/sale_item.dart';
import 'package:sahibz_inventory_management_system/services/core_service.dart';
import 'package:sahibz_inventory_management_system/services/sale_service.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';
import 'package:sahibz_inventory_management_system/shared/shared_screen/index.dart';
import 'package:flutter/cupertino.dart';

class SaleScreen extends StatefulWidget {
  final FlutterStorageSetter flutterStorage;
  const SaleScreen({super.key, required this.flutterStorage});

  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  late FlutterStorageSetter flutterStorage;

  final List<Sale> saleList = [];
  final List<Sale> searchReservedSaleList = [];

  final List<SaleItem> saleItems = [];
  final List<SaleItem> searchReservedSaleItems = [];

  static const String defaultSaleTitle = 'SALES';
  static const String defaultSaleItemTitle = 'SALE ITEMS';

  String title = '';

  @override
  void initState() {
    super.initState();
    flutterStorage = widget.flutterStorage;
    title = defaultSaleTitle;
    init();
  }

  void init({String? saleId}) async {
    switch (title) {
      case defaultSaleTitle:
        // Load sales
        final sales = await SaleService().getAll();
        setState(() {
          saleList.clear();
          saleList.addAll(sales.map((s) => Sale.fromJson(s)));
          searchReservedSaleList.clear();
          searchReservedSaleList.addAll(sales.map((s) => Sale.fromJson(s)));
        });
        break;
      case defaultSaleItemTitle:
        if (saleId == null) {
          ErrorDialog(
            context: context,
            error: 'Sale ID is required',
            storageSetter: flutterStorage,
          );
          return;
        }
        // Load sale items
        final saleItems = await CoreService(
          tableName: .saleItem,
        ).getControlled(where: 'sale_id = ?', whereArgs: [saleId]);
        setState(() {
          this.saleItems.clear();
          this.saleItems.addAll(
            saleItems.map((item) => SaleItem.fromJson(item)),
          );
          searchReservedSaleItems.clear();
          searchReservedSaleItems.addAll(
            saleItems.map((item) => SaleItem.fromJson(item)),
          );
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SharedScreen(
      title: title,
      isDefaultHeader: true,
      storageSetter: widget.flutterStorage,
      data: saleList.map((e) => e.toJson()).toList(),
      searchReserveddata: searchReservedSaleList
          .map((e) => e.toJson())
          .toList(),
      dbTableName: title == defaultSaleTitle ? .sale : .saleItem,
      backButton: title == defaultSaleItemTitle
          ? CustomMouseCursor(
              child: CupertinoButton.filled(
                sizeStyle: .medium,
                borderRadius: .circular(8.0),
                onPressed: () {
                  if (title == defaultSaleItemTitle) {
                    title = defaultSaleTitle;
                    setState(() {});
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
      onRefresh: () => init(
        saleId: title == defaultSaleTitle
            ? null
            : saleItems.isEmpty
            ? null
            : saleItems.first.saleId,
      ),
      onRowTap: (row) {
        if (title == defaultSaleTitle) {
          // Navigate to sale items screen
          setState(() {
            title = defaultSaleItemTitle;
            init(saleId: row['sale_id']);
          });
          return;
        }
      },
      onAdd: (onadd) {
        SaleItemDialog(
          context: context,
          storageSetter: widget.flutterStorage,
          saleItemList: null,
          searchReservedSaleItemList: null,
          saleList: null,
          searchReservedSaleList: null,
          isUpdate: false,
          sale: null,
          onAdd: onadd,
        );
      },
      onUpdate: title == defaultSaleTitle
          ? (onupdate, data, _, saleId) async {
              // Handle update for purchases
              final items = await CoreService(
                tableName: .saleItem,
              ).getControlled(where: 'sale_id = ?', whereArgs: [saleId]);
              final purchaseItems = items
                  .map((item) => SaleItem.fromJson(item))
                  .toList();
              final searchReservedItems = List<SaleItem>.from(purchaseItems);

              SaleItemDialog(
                context: context,
                storageSetter: widget.flutterStorage,
                isUpdate: true,
                onAdd: onupdate,
                sale: Sale.fromJson(data),
                saleItemList: saleItems.isNotEmpty ? saleItems : null,
                searchReservedSaleItemList: searchReservedItems.isNotEmpty
                    ? searchReservedItems
                    : null,
                saleList: null,
                searchReservedSaleList: null,
              );
            }
          : null,
          onDelete: title == defaultSaleTitle
              ? (ondelete, dataId, purchaseId, saleId) {
                  // Handle delete
                  DeleteConfirmDialog(
                    context: context,
                    ondelete: () async {
                      await SaleService().deleteSaleWithItems(
                        saleId: saleId!,
                        context: context,
                        flutterStorageSetter: widget.flutterStorage,
                      );
                      ondelete();
                      Navigator.of(context).pop();
                      SuccessDialog(
                        context: context,
                        success: 'Sale deleted successfully',
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
