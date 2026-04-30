// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, no_leading_underscores_for_local_identifiers

import 'package:sahibz_inventory_management_system/dialogs/purchase_item_add_edit.dart';
import 'package:sahibz_inventory_management_system/dialogs/delete_confirm_dialog.dart';
import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';
import 'package:sahibz_inventory_management_system/shared/shared_screen/index.dart';
import 'package:sahibz_inventory_management_system/services/purchase_service.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:sahibz_inventory_management_system/models/purchase_item.dart';
import 'package:sahibz_inventory_management_system/models/purchase.dart';
import 'package:sahibz_inventory_management_system/database_helper.dart';
import 'package:flutter/cupertino.dart';

final GlobalKey<_PurchasesScreenState> purchasesKey =
    GlobalKey<_PurchasesScreenState>();

class PurchasesScreen extends StatefulWidget {
  final FlutterStorageSetter flutterStorage;
  PurchasesScreen({required this.flutterStorage}) : super(key: purchasesKey);

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  List<Purchase> purchases = [];
  List<Purchase> searchReservedPurchases = [];
  List<PurchaseItem> purchaseItems = [];
  List<PurchaseItem> searchReservedPurchaseItems = [];

  // Cart list
  List<PurchaseItem> purchaseItemsCartList = [];

  // SearchReserved cart list
  List<PurchaseItem> searchReservedPurchaseItemsCartList = [];

  // Title for the screen
  String title = 'PURCHASES';

  // Top title for the screen
  String toptitle = 'Purchases Screen';

  // FlutterStorageSetter instance
  late FlutterStorageSetter flutterStorageSetter;

  @override
  void initState() {
    super.initState();
    flutterStorageSetter = widget.flutterStorage;
    init();
  }

  void init() async {
    try {
      // Copy existing data to avoid modifying the original list
      List<Purchase> _purchases = List<Purchase>.from(purchases);

      // Fetch purchases from database
      final _purchasesDb = await PurchaseService().getAll();

      // Convert database records to Purchase model objects
      _purchases = _purchasesDb.map((ele) => Purchase.fromJson(ele)).toList();

      // Update both lists with fresh data
      setState(() {
        purchases = _purchases;
        searchReservedPurchases = purchases;
      });
    } catch (e) {
      ErrorDialog(context: context, error: e.toString(), storageSetter: flutterStorageSetter);
      rethrow;
    }
  }

  // Text controllers for purchase form
  final TextEditingController _invoiceNumberController =
      TextEditingController();
  final TextEditingController _paymentMethodController =
      TextEditingController();

  final TextEditingController _totalTaxAmountController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SharedScreen(
      storageSetter: flutterStorageSetter,
      title: title,
      toptitle: toptitle,
      backButton: title == 'PURCHASE ITEMS'
          ? CustomMouseCursor(
              child: CupertinoButton.filled(
                sizeStyle: .medium,
                onPressed: () {
                  // Navigate back to purchases list
                  setState(() {
                    title = 'PURCHASES';
                    toptitle = 'Purchases Screen';
                  });
                },
                child: Row(
                  spacing: 8.0,
                  children: [
                    Icon(CupertinoIcons.back, size: 20.0),
                    Text('Back', style: TextStyle(fontSize: 20)),
                  ],
                ),
              ),
            )
          : null,
      dbTableName: title == 'PURCHASES'
          ? DatabaseTableNames.purchase
          : DatabaseTableNames.purchaseItem,
      isDefaultHeader: true,
      data: title == 'PURCHASES'
          ? purchases.map((ele) => ele.toJson()).toList()
          : purchaseItems.map((ele) => ele.toJson()).toList(),
      searchReserveddata: title == 'PURCHASES'
          ? searchReservedPurchases.map((ele) => ele.toJson()).toList()
          : searchReservedPurchaseItems.map((ele) => ele.toJson()).toList(),
      onRefresh: init,
      onRowTap: (row) async {
        try {
          if (title == 'PURCHASES') {
            final List<Map<String, dynamic>> items = await PurchaseItemService()
                .getByPurchaseId(row['purchase_id']);
            setState(() {
              title = 'PURCHASE ITEMS';
              toptitle = 'Purchase Items Screen';

              // Copy list to avoid modifying original
              final List<PurchaseItem> purchaseItemss = [];
              purchaseItemss.addAll(items.map((e) => PurchaseItem.fromJson(e)));
              purchaseItems = purchaseItemss;
              searchReservedPurchaseItems = purchaseItems;
            });
          }
        } catch (e) {
          ErrorDialog(context: context, error: e.toString(), storageSetter: flutterStorageSetter);
          rethrow;
        }
      },
      onAdd: (onadd) {
        PurchaseItemAddEdit(
          context: context,
          onDone: init,
          storageSetter: flutterStorageSetter,
          purchaseItemsCartList: purchaseItemsCartList,
        );
      },
      onUpdate: (onupdate, data) async {
        final List<PurchaseItem> purchaseItemss = [];
        if (title == 'PURCHASES') {
          final purchaseId = data['purchase_id'];
          final purchaseItems = await PurchaseItemService().getByPurchaseId(
            purchaseId,
          );
          // Copy list to avoid modifying original
          purchaseItemss.addAll(
            purchaseItems.map((e) => PurchaseItem.fromJson(e)),
          );

          _invoiceNumberController.text = data['invoice_number'];
          _paymentMethodController.text = data['payment_method'];
          _totalTaxAmountController.text = data['total_tax_amount'].toString();
        } else {
          final purchaseId = data['purchase_id'];
          final purchaseItems = await PurchaseItemService().getByPurchaseId(
            purchaseId,
          );
          final purchases = await PurchaseService().getByPurchaseId(purchaseId);
          // Copy list to avoid modifying original
          purchaseItemss.addAll(
            purchaseItems.map((e) => PurchaseItem.fromJson(e)),
          );
          _invoiceNumberController.text =
              purchases.first['invoice_number'].toString();
          _paymentMethodController.text =
              purchases.first['payment_method'].toString();
          _totalTaxAmountController.text =
              purchases.first['total_tax_amount'].toString();
        }
        setState(() {
          purchaseItemsCartList = purchaseItemss;
        });

        PurchaseItemAddEdit(
          context: context,
          storageSetter: flutterStorageSetter,
          purchaseItems: purchaseItemss,
          onDone: init,
          purchaseItemsCartList: purchaseItemsCartList,
          invoiceNumberController: _invoiceNumberController,
          paymentMethodController: _paymentMethodController,
          totalTaxAmountController: _totalTaxAmountController,
        );
      },
      onDelete: (ondelete, data, purchaseId, saleId) {
        DeleteConfirmDialog(
          context: context,
          storageSetter: flutterStorageSetter,
          ondelete: () async {
            try {
              if (purchaseId != null) {
                await PurchaseService().delete(
                  id: data,
                  type: .purchaseRemoved,
                );
                await PurchaseItemService().delete(
                  id: int.parse(purchaseId),
                  idColumnName: 'purchase_id',
                  type: .purchaseItemRemoved,
                );
              }
              ondelete();
              Navigator.of(context).pop();
            } catch (e) {
              ErrorDialog(context: context, error: e.toString(), storageSetter: flutterStorageSetter);
              rethrow;
            }
          },
        );
      },
    );
  }
}
