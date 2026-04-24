// ignore_for_file: use_build_context_synchronously, deprecated_member_use, non_constant_identifier_names

import 'package:sahibz_inventory_management_system/dialogs/core/coredialog_framework.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:sahibz_inventory_management_system/dialogs/item_selector.dart';
import 'package:sahibz_inventory_management_system/dialogs/purchase_add_edit.dart';
import 'package:sahibz_inventory_management_system/models/purchase_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:sahibz_inventory_management_system/services/core_service.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';

void PurchaseItemAddEdit({
  required BuildContext context,
  List<PurchaseItem>? purchaseItems,
  required void Function() onDone,
  required TextEditingController productNameController,
  required TextEditingController supplierIdController,
  required TextEditingController costController,
  required TextEditingController quantityController,
  required TextEditingController discountController,
  required List<PurchaseItem> purchaseItemsCartList,
  required List<PurchaseItem> searchReservedPurchaseItemsCartList,
  required List<PurchaseItem> Function() add2Cart,
  required TextEditingController invoiceNumberController,
  required TextEditingController paymentMethodController,
  required TextEditingController totalCostBeforeTaxController,
  required TextEditingController totalTaxAmountController,
  required TextEditingController totalDiscountController,
}) {
  // // Initialize variables
  bool isPurchaseItemExists = purchaseItems != null;

  // // Fill the text controllers with data if the purchase item exists
  // supplierIdController.text = isPurchaseItemExists
  //     ? purchaseItem.supplierId.toString()
  //     : '';
  // productNameController.text = isPurchaseItemExists
  //     ? purchaseItem.productName.toString()
  //     : '';
  // costController.text = isPurchaseItemExists
  //     ? purchaseItem.cost.toString()
  //     : '';
  // quantityController.text = isPurchaseItemExists
  //     ? purchaseItem.quantity.toString()
  //     : '';
  // discountController.text = isPurchaseItemExists
  //     ? purchaseItem.discount.toString()
  //     : '';

  final prototypeTile = {
    'Cost': costController,
    'Quantity': quantityController,
    'Discount': discountController,
  };

  CoreDialogFramework(
    context: context,
    title: isPurchaseItemExists ? 'Edit Purchase Items' : 'Add Purchase Items',
    onDispose: () {
      // Clear controllers when dialog is dismissed
      supplierIdController.clear();
      productNameController.clear();
      costController.clear();
      quantityController.clear();
      discountController.clear();
      invoiceNumberController.clear();
      paymentMethodController.clear();
      totalCostBeforeTaxController.clear();
      totalTaxAmountController.clear();
      totalDiscountController.clear();
      purchaseItemsCartList.clear();
      searchReservedPurchaseItemsCartList.clear();
    },
    content: StatefulBuilder(
      builder: (context, setDialogState) => SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          spacing: 15.0,
          children: [
            // Product Name
            Row(
              spacing: 10.0,
              children: [
                Expanded(
                  child: CupertinoTextField(
                    controller: supplierIdController,
                    placeholder: 'Select Supplier Id',
                    padding: const EdgeInsets.all(10.0),
                    onTap: () async {
                      List<Map<String, dynamic>> supplierList =
                          await CoreService(tableName: .supplier).getAll();
                      if (supplierList.isEmpty) {
                        ErrorDialog(
                          context: context,
                          error: 'Supplier table is empty.',
                        );
                        return;
                      }
                      final selected = await itemSelector(
                        context: context,
                        isSingleSelector: true,
                        items: supplierList
                            .map((e) => e['name'].toString())
                            .toList(),
                      );
                      if (selected.isNotEmpty) {
                        supplierIdController.text = supplierList
                            .firstWhere(
                              (e) => e['name'] == selected.first,
                            )['supplier_id']
                            .toString();
                      }
                    },
                  ),
                ),
                Expanded(
                  child: CupertinoTextField(
                    controller: productNameController,
                    placeholder: 'Product Name',
                    padding: const EdgeInsets.all(10.0),
                    onTap: () async {
                      List<Map<String, dynamic>> inventoryList =
                          await CoreService(tableName: .inventory).getAll();
                      if (inventoryList.isEmpty) {
                        ErrorDialog(
                          context: context,
                          error: 'Inventory table is empty.',
                        );
                        return;
                      }
                      final selected = await itemSelector(
                        context: context,
                        isSingleSelector: true,
                        items: inventoryList
                            .map((e) => e['name'].toString())
                            .toList(),
                      );
                      if (selected.isNotEmpty) {
                        productNameController.text = inventoryList
                            .firstWhere(
                              (e) => e['name'] == selected.first,
                            )['label']
                            .toString();
                      }
                    },
                  ),
                ),
              ],
            ),

            // Cost, Quantity, Discount
            Row(
              spacing: 10.0,
              children: [
                ...prototypeTile.entries.map(
                  (entry) => Expanded(
                    child: CupertinoTextField(
                      controller: entry.value,
                      placeholder: entry.key,
                      padding: const EdgeInsets.all(10.0),
                      onChanged: (value) {
                        if (entry.key == 'Quantity' &&
                            int.tryParse(value) == null) {
                          ErrorDialog(
                            context: context,
                            error: 'Quantity must be an integer number',
                          );
                          entry.value.text = '';
                          return;
                        } else if (double.tryParse(value) == null) {
                          ErrorDialog(
                            context: context,
                            error: '${entry.key} must be a double number',
                          );
                          entry.value.text = '';
                          return;
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),

            // Cart area
            purchaseItemsCartList.isEmpty
                ? Center(child: Text('No items in cart'))
                : IntrinsicHeight(
                    child: Container(
                      height: 400.0,
                      padding: const EdgeInsets.all(10.0),
                      child: ListView.builder(
                        itemCount: purchaseItemsCartList.length,
                        itemBuilder: (context, index) {
                          return CustomMouseCursor(
                            child: Container(
                              margin: .only(bottom: 15.0),
                              padding: .all(5.0),
                              decoration: BoxDecoration(
                                border: .all(
                                  color: CupertinoColors.white.withOpacity(0.5),
                                ),
                                borderRadius: .circular(10.0),
                              ),
                              child: CupertinoListTile(
                                title: Text(
                                  purchaseItemsCartList[index].productName,
                                ),
                                subtitle: Row(
                                  spacing: 10.0,
                                  children: [
                                    Text(
                                      'Cost: ${purchaseItemsCartList[index].cost}',
                                    ),
                                    Text(
                                      'Quantity: ${purchaseItemsCartList[index].quantity}',
                                    ),
                                    Text(
                                      'Discount: ${purchaseItemsCartList[index].discount}',
                                    ),
                                  ],
                                ),
                                trailing: CupertinoButton(
                                  child: const Icon(
                                    CupertinoIcons.delete,
                                    color: CupertinoColors.systemRed,
                                  ),
                                  onPressed: () {
                                    setDialogState(() {
                                      purchaseItemsCartList.removeAt(index);
                                    });
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

            // Buttons
            Padding(
              padding: .symmetric(horizontal: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomMouseCursor(
                    child: CupertinoButton.filled(
                      sizeStyle: CupertinoButtonSize.medium,
                      borderRadius: BorderRadius.circular(10.0),
                      onPressed: () {
                        // Call a method on the parent state
                        final List<PurchaseItem> data = add2Cart();
                        if (data.isNotEmpty) {
                          setDialogState(() {
                            // Clear the list first
                            purchaseItemsCartList.clear();

                            // Add the new items
                            purchaseItemsCartList = data;
                          });
                        }
                      },
                      child: const Text(
                        'Add to cart',
                        style: .new(fontWeight: .bold),
                      ),
                    ),
                  ),
                  CustomMouseCursor(
                    child: CupertinoButton.filled(
                      sizeStyle: CupertinoButtonSize.medium,
                      borderRadius: BorderRadius.circular(10.0),
                      onPressed: () {
                        if (purchaseItemsCartList.isNotEmpty) {
                          totalCostBeforeTaxController.text = purchaseItemsCartList
                              .map((item) => item.cost)
                              .reduce((a, b) => a + b)
                              .toString();
                          totalDiscountController.text = purchaseItemsCartList
                              .map((item) => item.discount)
                              .reduce((a, b) => a + b)
                              .toString();
                          PurchaseAddEdit(
                            context: context,
                            onDone: onDone,
                            invoiceNumberController: invoiceNumberController,
                            paymentMethodController: paymentMethodController,
                            totalCostBeforeTaxController:
                                totalCostBeforeTaxController,
                            totalTaxAmountController: totalTaxAmountController,
                            totalDiscountController: totalDiscountController,
                            purchaseItemsCartList: purchaseItemsCartList,
                          );
                        } else {
                          ErrorDialog(
                            context: context,
                            error: 'Please add at least one item to the cart',
                          );
                        }
                      },
                      child: const Text('Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
