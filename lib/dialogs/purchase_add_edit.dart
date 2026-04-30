// ignore_for_file: deprecated_member_use, use_build_context_synchronously, non_constant_identifier_names

import 'package:sahibz_inventory_management_system/dialogs/core/coredialog_framework.dart';
import 'package:sahibz_inventory_management_system/models/payment_method_purchase_enum.dart';
import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';
import 'package:sahibz_inventory_management_system/services/purchase_service.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/dialogs/item_selector.dart';
import 'package:sahibz_inventory_management_system/services/core_service.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:sahibz_inventory_management_system/models/purchase_item.dart';
import 'package:sahibz_inventory_management_system/models/purchase.dart';
import 'package:flutter/cupertino.dart';

final CoreService coreService = CoreService(tableName: .purchase);

void PurchaseAddEdit({
  required BuildContext contextt,
  Purchase? purchase,
  required void Function() onDone,
  required FlutterStorageSetter storageSetter,
  TextEditingController? invoiceNumberController,
  TextEditingController? paymentMethodController,
  TextEditingController? totalTaxAmountController,
  required TextEditingController totalCostBeforeTaxController,
  required TextEditingController totalDiscountController,
  required List<PurchaseItem> purchaseItemsCartList,
}) {
  // Check if the purchase exists
  bool isPurchaseExists = purchase != null;

  CoreDialogFramework(
    context: contextt,
    storageSetter: storageSetter,
    title: isPurchaseExists ? 'Edit Purchase' : 'Add Purchase',
    content: PurchaseAddEditDialogState(
      purchase: purchase,
      onDone: onDone,
      storageSetter: storageSetter,
      invoiceNumberController: invoiceNumberController,
      paymentMethodController: paymentMethodController,
      totalTaxAmountController: totalTaxAmountController,
      totalCostBeforeTaxController: totalCostBeforeTaxController,
      totalDiscountController: totalDiscountController,
      purchaseItemsCartList: purchaseItemsCartList,
    ),
  );
}

class PurchaseAddEditDialogState extends StatefulWidget {
  final Purchase? purchase;
  final void Function() onDone;
  final FlutterStorageSetter storageSetter;
  final TextEditingController? invoiceNumberController;
  final TextEditingController? paymentMethodController;
  final TextEditingController? totalTaxAmountController;
  final TextEditingController totalCostBeforeTaxController;
  final TextEditingController totalDiscountController;
  final List<PurchaseItem> purchaseItemsCartList;

  const PurchaseAddEditDialogState({
    super.key,
    required this.purchase,
    required this.onDone,
    required this.storageSetter,
    this.invoiceNumberController,
    this.paymentMethodController,
    this.totalTaxAmountController,
    required this.totalCostBeforeTaxController,
    required this.totalDiscountController,
    required this.purchaseItemsCartList,
  });

  @override
  State<PurchaseAddEditDialogState> createState() =>
      _PurchaseAddEditDialogStateState();
}

class _PurchaseAddEditDialogStateState
    extends State<PurchaseAddEditDialogState> {
  TextEditingController invoiceNumberController = TextEditingController();
  TextEditingController paymentMethodController = TextEditingController();
  TextEditingController totalCostBeforeTaxController = TextEditingController();
  TextEditingController totalTaxAmountController = TextEditingController();
  TextEditingController totalDiscountController = TextEditingController();
  bool isPurchaseExists = false;
  bool isDarkMode = false;
  List<PurchaseItem> purchaseItemsCartList = [];

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    super.dispose();
    invoiceNumberController.dispose();
    paymentMethodController.dispose();
    totalCostBeforeTaxController.dispose();
    totalTaxAmountController.dispose();
    totalDiscountController.dispose();
  }

  void init() async {
    final darkMode = await widget.storageSetter.getDarkMode() ?? false;
    setState(() {
      isPurchaseExists = widget.purchase != null;
      isDarkMode = darkMode;
      if (widget.purchaseItemsCartList.isNotEmpty) {
        purchaseItemsCartList = widget.purchaseItemsCartList;
      }
    });

    // Initialize controllers with existing values if editing
    if (widget.purchase != null) {
      invoiceNumberController.text = widget.purchase!.invoiceNumber;
      paymentMethodController.text = widget.purchase!.paymentMethod;
      totalTaxAmountController.text = widget.purchase!.totalTaxAmount
          .toString();
    }
    totalCostBeforeTaxController.text = widget.totalCostBeforeTaxController.text;
    totalDiscountController.text = widget.totalDiscountController.text;
    
    // Initialize with values from external controllers when updating
    invoiceNumberController.text = widget.invoiceNumberController?.text ?? '';
    paymentMethodController.text = widget.paymentMethodController?.text ?? '';
    totalTaxAmountController.text = widget.totalTaxAmountController?.text ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 15.0,
      children: [
        // Invoice Number Text Field
        CupertinoTextField(
          placeholder: 'Invoice Number',
          padding: const EdgeInsets.all(15.0),
          controller: invoiceNumberController,
          placeholderStyle: .new(
            color: isDarkMode
                ? CupertinoColors.white.withOpacity(0.2)
                : CupertinoColors.black.withOpacity(0.4),
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
            color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),

        // Payment Method Text Field
        CupertinoTextField(
          placeholder: 'Payment Method',
          padding: const EdgeInsets.all(15.0),
          controller: paymentMethodController,
          placeholderStyle: .new(
            color: isDarkMode
                ? CupertinoColors.white.withOpacity(0.2)
                : CupertinoColors.black.withOpacity(0.4),
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
            color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
          ),
          onTap: () async {
            // Show payment method selector
            final selectedPaymentMethod = await itemSelector(
              context: context,
              items: PaymentMethodPurchase.values.map((e) => e.name).toList(),
              isSingleSelector: true,
              storageSetter: widget.storageSetter,
            );
            if (selectedPaymentMethod.isNotEmpty) {
              paymentMethodController.text = selectedPaymentMethod.first;
            }
          },
        ),

        // Total Cost Before Tax Text Field
        CupertinoTextField(
          placeholder: 'Total Cost Before Tax',
          padding: const EdgeInsets.all(15.0),
          controller: totalCostBeforeTaxController,
          placeholderStyle: .new(
            color: isDarkMode
                ? CupertinoColors.white.withOpacity(0.2)
                : CupertinoColors.black.withOpacity(0.4),
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
            color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),

        // Total Tax Amount Text Field
        CupertinoTextField(
          placeholder: 'Total Tax Amount',
          padding: const EdgeInsets.all(15.0),
          controller: totalTaxAmountController,
          placeholderStyle: .new(
            color: isDarkMode
                ? CupertinoColors.white.withOpacity(0.2)
                : CupertinoColors.black.withOpacity(0.4),
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
            color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),

        // Total Discount Text Field
        CupertinoTextField(
          placeholder: 'Total Discount',
          padding: const EdgeInsets.all(15.0),
          controller: totalDiscountController,
          placeholderStyle: .new(
            color: isDarkMode
                ? CupertinoColors.white.withOpacity(0.2)
                : CupertinoColors.black.withOpacity(0.4),
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
            color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),

        Align(
          alignment: .centerRight,
          child: CustomMouseCursor(
            child: CupertinoButton.filled(
              onPressed: () => _onPress(
                context: context,
                purchase: widget.purchase,
                onDone: widget.onDone,
                storageSetter: widget.storageSetter,
                isPurchaseExists: isPurchaseExists,
                invoiceNumberController: invoiceNumberController,
                paymentMethodController: paymentMethodController,
                totalCostBeforeTaxController: totalCostBeforeTaxController,
                totalTaxAmountController: totalTaxAmountController,
                totalDiscountController: totalDiscountController,
                purchaseItems: purchaseItemsCartList,
              ),
              sizeStyle: .medium,
              borderRadius: .circular(10.0),
              child: Text(isPurchaseExists ? 'Update' : 'Submit'),
            ),
          ),
        ),
      ],
    );
  }
}

/// Handle the submit button press
Future<void> _onPress({
  required BuildContext context,
  required Purchase? purchase,
  required void Function() onDone,
  required bool isPurchaseExists,
  required FlutterStorageSetter storageSetter,
  required TextEditingController invoiceNumberController,
  required TextEditingController paymentMethodController,
  required TextEditingController totalCostBeforeTaxController,
  required TextEditingController totalTaxAmountController,
  required TextEditingController totalDiscountController,
  required List<PurchaseItem> purchaseItems,
}) async {
  try {
    // Error Lists
    List<String> errors = [];

    // Check the input
    List<Map<String, TextEditingController>> controllers = [
      {'Invoice Number': invoiceNumberController},
      {'Payment Method': paymentMethodController},
      {'Total Cost Before Tax': totalCostBeforeTaxController},
      {'Total Tax Amount': totalTaxAmountController},
      {'Total Discount': totalDiscountController},
    ];

    // Check if the inputs are valid
    for (var e in controllers) {
      for (var f in e.keys) {
        if (e[f]!.text.isEmpty) {
          errors.add("$f can't be empty");
        }
      }
    }

    // If there are errors, show the error dialog
    if (errors.isNotEmpty) {
      ErrorDialog(
        context: context,
        error: errors.join('\n'),
        storageSetter: storageSetter,
      );
      return;
    }

    // Numbers check
    if (double.tryParse(totalCostBeforeTaxController.text) == null) {
      errors.add("Total Cost Before Tax must be a double number");
    }
    if (double.tryParse(totalTaxAmountController.text) == null) {
      errors.add("Total Tax Amount must be a double number");
    }
    if (double.tryParse(totalDiscountController.text) == null) {
      errors.add("Total Discount must be a double number");
    }

    // If there are errors, show the error dialog
    if (errors.isNotEmpty) {
      ErrorDialog(
        context: context,
        error: errors.join('\n'),
        storageSetter: storageSetter,
      );
      return;
    }

    // Create the purchase object
    final purchasee = Purchase(
      id: isPurchaseExists ? purchase!.id : 0,
      purchaseId: isPurchaseExists ? purchase!.purchaseId : '',
      invoiceNumber: invoiceNumberController.text,
      paymentMethod: paymentMethodController.text,
      totalCostBeforeTax: double.parse(totalCostBeforeTaxController.text),
      totalTaxAmount: double.parse(totalTaxAmountController.text),
      totalDiscount: double.parse(totalDiscountController.text),
      date: isPurchaseExists ? purchase!.date : DateTime.now(),
    );

    // If purchase is null, insert it, otherwise update it
    if (purchase == null) {
      await PurchaseService().insertPurchasesWithItems(
        purchase: purchasee,
        items: purchaseItems,
      );
    } else {
      await PurchaseService().updatePurchasesWithItems(
        purchase: purchasee,
        items: purchaseItems,
      );
    }

    // Pop the dialog and call the onDone function to update the changes in UI
    Navigator.of(context).pop();
    onDone();
  } catch (e) {
    // Show error dialog if there is an error
    ErrorDialog(
      context: context,
      error: e.toString(),
      storageSetter: storageSetter,
    );
    return;
  }
}
