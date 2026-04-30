// ignore_for_file: must_be_immutable, use_build_context_synchronously, deprecated_member_use, non_constant_identifier_names

import 'package:sahibz_inventory_management_system/dialogs/core/coredialog_framework.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:sahibz_inventory_management_system/dialogs/item_selector.dart';
import 'package:sahibz_inventory_management_system/dialogs/purchase_add_edit.dart';
import 'package:sahibz_inventory_management_system/models/purchase_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:sahibz_inventory_management_system/services/core_service.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';

void PurchaseItemAddEdit({
  required BuildContext context,
  List<PurchaseItem>? purchaseItems,
  required void Function() onDone,
  required List<PurchaseItem> purchaseItemsCartList,
  required FlutterStorageSetter storageSetter,
  TextEditingController? invoiceNumberController,
  TextEditingController? paymentMethodController,
  TextEditingController? totalTaxAmountController,
}) {
  // // Initialize variables
  bool isPurchaseItemExists = purchaseItems != null;

  CoreDialogFramework(
    context: context,
    storageSetter: storageSetter,
    title: isPurchaseItemExists ? 'Edit Purchase Items' : 'Add Purchase Items',
    content: PurchaseItemAddEditContent(
      storageSetter: storageSetter,
      onDone: onDone,
      purchaseItemsCartList: purchaseItemsCartList,
      invoiceNumberController: invoiceNumberController,
      paymentMethodController: paymentMethodController,
      totalTaxAmountController: totalTaxAmountController,
    ),
  );
}

class PurchaseItemAddEditContent extends StatefulWidget {
  final PurchaseItem? purchaseItem;
  final FlutterStorageSetter storageSetter;
  final Function() onDone;
  final List<PurchaseItem> purchaseItemsCartList;
  final TextEditingController? invoiceNumberController;
  final TextEditingController? paymentMethodController;
  final TextEditingController? totalTaxAmountController;
  const PurchaseItemAddEditContent({
    super.key,
    this.purchaseItem,
    required this.storageSetter,
    required this.onDone,
    required this.purchaseItemsCartList,
    this.invoiceNumberController,
    this.paymentMethodController,
    this.totalTaxAmountController,
  });

  @override
  State<PurchaseItemAddEditContent> createState() =>
      _PurchaseItemAddEditContentState();
}

class _PurchaseItemAddEditContentState
    extends State<PurchaseItemAddEditContent> {
  TextEditingController supplierIdController = TextEditingController();
  TextEditingController productNameController = TextEditingController();
  TextEditingController costController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  TextEditingController discountController = TextEditingController();
  List<PurchaseItem> purchaseItemsCartList = [];
  bool isPurchaseItemExists = false;
  bool isDarkMode = false;

  TextEditingController totalCostBeforeTaxController = TextEditingController();
  TextEditingController totalDiscountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    super.dispose();
    supplierIdController.dispose();
    productNameController.dispose();
    costController.dispose();
    quantityController.dispose();
    discountController.dispose();
    totalCostBeforeTaxController.dispose();
    totalDiscountController.dispose();
  }

  void init() async {
    final darkMode = await widget.storageSetter.getDarkMode() ?? false;
    setState(() {
      // Initialize variables
      isPurchaseItemExists = widget.purchaseItem != null;
      isDarkMode = darkMode;
      purchaseItemsCartList = widget.purchaseItemsCartList;
    });

    // Fill the text controllers with data if the purchase item exists
    supplierIdController.text = isPurchaseItemExists
        ? widget.purchaseItem!.supplierId.toString()
        : '';
    productNameController.text = isPurchaseItemExists
        ? widget.purchaseItem!.productName.toString()
        : '';
    costController.text = isPurchaseItemExists
        ? widget.purchaseItem!.cost.toString()
        : '';
    quantityController.text = isPurchaseItemExists
        ? widget.purchaseItem!.quantity.toString()
        : '';
    discountController.text = isPurchaseItemExists
        ? widget.purchaseItem!.discount.toString()
        : '';
  }

  // Add to cart
  List<PurchaseItem> add2Cart() {
    try {
      // Error Handling
      if (productNameController.text.isEmpty) {
        ErrorDialog(
          context: context,
          error: 'Product Name can\'t be empty',
          storageSetter: widget.storageSetter,
        );
        return [];
      }

      if (costController.text.isEmpty) {
        ErrorDialog(
          context: context,
          error: 'Cost can\'t be empty',
          storageSetter: widget.storageSetter,
        );
        return [];
      }

      if (quantityController.text.isEmpty) {
        ErrorDialog(
          context: context,
          error: 'Quantity can\'t be empty',
          storageSetter: widget.storageSetter,
        );
        return [];
      }

      if (discountController.text.isEmpty) {
        ErrorDialog(
          context: context,
          error: 'Discount can\'t be empty',
          storageSetter: widget.storageSetter,
        );
        return [];
      }

      if (double.tryParse(costController.text) == null) {
        ErrorDialog(
          context: context,
          error: 'Cost must be a number',
          storageSetter: widget.storageSetter,
        );
        return [];
      }

      if (int.tryParse(quantityController.text) == null) {
        ErrorDialog(
          context: context,
          error: 'Quantity must be a number',
          storageSetter: widget.storageSetter,
        );
        return [];
      }

      if (double.tryParse(discountController.text) == null) {
        ErrorDialog(
          context: context,
          error: 'Discount must be a number',
          storageSetter: widget.storageSetter,
        );
        return [];
      }

      // Create purchase item
      final PurchaseItem purchaseItem = PurchaseItem(
        id: 0,
        purchaseId: '',
        supplierId: supplierIdController.text,
        date: DateTime.now().toIso8601String(),
        productName: productNameController.text,
        cost: double.parse(costController.text),
        quantity: double.parse(quantityController.text),
        discount: double.parse(discountController.text),
      );

      for (var element in purchaseItemsCartList) {
        if (element == purchaseItem) {
          // Item already exists, do nothing
          return [];
        }
      }

      // Add to cart list
      final List<PurchaseItem> newList = List.from(purchaseItemsCartList);
      newList.add(purchaseItem);
      setState(() {
        purchaseItemsCartList = newList;
      });
      return purchaseItemsCartList;
    } catch (e) {
      ErrorDialog(
        context: context,
        error: e.toString(),
        storageSetter: widget.storageSetter,
      );
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prototypeTile = {
      'Cost': costController,
      'Quantity': quantityController,
      'Discount': discountController,
    };
    return StatefulBuilder(
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
                    placeholder: 'Select Supplier',
                    padding: const EdgeInsets.all(10.0),
                    placeholderStyle: .new(
                      color: isDarkMode
                          ? CupertinoColors.white.withOpacity(0.2)
                          : CupertinoColors.black.withOpacity(0.35),
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? CupertinoColors.black.withOpacity(0.5)
                          : CupertinoColors.systemGrey6.withOpacity(0.95),
                      border: .all(
                        color: isDarkMode
                            ? CupertinoColors.white.withOpacity(0.3)
                            : CupertinoColors.black.withOpacity(0.3),
                      ),
                      borderRadius: .circular(10.0),
                    ),
                    style: .new(
                      color: isDarkMode
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                    onTap: () async {
                      List<Map<String, dynamic>> supplierList =
                          await CoreService(tableName: .supplier).getAll();
                      if (supplierList.isEmpty) {
                        ErrorDialog(
                          context: context,
                          error: 'Supplier table is empty.',
                          storageSetter: widget.storageSetter,
                        );
                        return;
                      }
                      final selected = await itemSelector(
                        context: context,
                        isSingleSelector: true,
                        storageSetter: widget.storageSetter,
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
                    placeholderStyle: .new(
                      color: isDarkMode
                          ? CupertinoColors.white.withOpacity(0.2)
                          : CupertinoColors.black.withOpacity(0.35),
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? CupertinoColors.black.withOpacity(0.5)
                          : CupertinoColors.systemGrey6.withOpacity(0.95),
                      border: .all(
                        color: isDarkMode
                            ? CupertinoColors.white.withOpacity(0.3)
                            : CupertinoColors.black.withOpacity(0.3),
                      ),
                      borderRadius: .circular(10.0),
                    ),
                    style: .new(
                      color: isDarkMode
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                    onTap: () async {
                      List<Map<String, dynamic>> inventoryList =
                          await CoreService(tableName: .inventory).getAll();
                      if (inventoryList.isEmpty) {
                        ErrorDialog(
                          context: context,
                          error: 'Inventory table is empty.',
                          storageSetter: widget.storageSetter,
                        );
                        return;
                      }
                      final selected = await itemSelector(
                        context: context,
                        isSingleSelector: true,
                        storageSetter: widget.storageSetter,
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
                      placeholderStyle: .new(
                        color: isDarkMode
                            ? CupertinoColors.white.withOpacity(0.2)
                            : CupertinoColors.black.withOpacity(0.35),
                      ),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? CupertinoColors.black.withOpacity(0.5)
                            : CupertinoColors.systemGrey6.withOpacity(0.95),
                        border: .all(
                          color: isDarkMode
                              ? CupertinoColors.white.withOpacity(0.3)
                              : CupertinoColors.black.withOpacity(0.3),
                        ),
                        borderRadius: .circular(10.0),
                      ),
                      style: .new(
                        color: isDarkMode
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                      ),
                      onChanged: (value) {
                        if (entry.key == 'Quantity' &&
                            int.tryParse(value) == null) {
                          ErrorDialog(
                            context: context,
                            error: 'Quantity must be an integer number',
                            storageSetter: widget.storageSetter,
                          );
                          entry.value.text = '';
                          return;
                        } else if (double.tryParse(value) == null) {
                          ErrorDialog(
                            context: context,
                            error: '${entry.key} must be a double number',
                            storageSetter: widget.storageSetter,
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
                ? Container(
                    padding: .all(20.0),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? CupertinoColors.systemGrey.withOpacity(0.2)
                          : CupertinoColors.systemGrey2.withOpacity(0.2),
                      borderRadius: .circular(10.0),
                      border: .all(
                        color: isDarkMode
                            ? CupertinoColors.systemGrey.withOpacity(0.3)
                            : CupertinoColors.systemGrey3.withOpacity(0.3),
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: .center,
                        children: [
                          Icon(
                            CupertinoIcons.cart,
                            color: isDarkMode
                                ? CupertinoColors.systemGrey3
                                : CupertinoColors.systemBlue,
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            'Cart is Empty',
                            style: .new(
                              color: isDarkMode
                                  ? CupertinoColors.white
                                  : CupertinoColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
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
            Row(
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
                        setState(() {
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
                        totalCostBeforeTaxController.text =
                            purchaseItemsCartList
                                .map((item) => item.cost)
                                .reduce((a, b) => a + b)
                                .toString();
                        totalDiscountController.text = purchaseItemsCartList
                            .map((item) => item.discount)
                            .reduce((a, b) => a + b)
                            .toString();
                        PurchaseAddEdit(
                          contextt: context,
                          onDone: widget.onDone,
                          storageSetter: widget.storageSetter,
                          totalCostBeforeTaxController:
                              totalCostBeforeTaxController,
                          totalDiscountController: totalDiscountController,
                          purchaseItemsCartList: purchaseItemsCartList,
                          invoiceNumberController:
                              widget.invoiceNumberController,
                          paymentMethodController:
                              widget.paymentMethodController,
                          totalTaxAmountController:
                              widget.totalTaxAmountController,
                        );
                      } else {
                        ErrorDialog(
                          context: context,
                          error: 'Please add at least one item to the cart',
                          storageSetter: widget.storageSetter,
                        );
                      }
                    },
                    child: const Text('Next', style: .new(fontWeight: .bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
