// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names

import 'package:sahibz_inventory_management_system/dialogs/core/coredialog_framework.dart';
import 'package:sahibz_inventory_management_system/dialogs/item_selector.dart';
import 'package:sahibz_inventory_management_system/models/payment_method_purchase_enum.dart';
import 'package:sahibz_inventory_management_system/services/purchase_service.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/services/core_service.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:sahibz_inventory_management_system/models/purchase_item.dart';
import 'package:sahibz_inventory_management_system/models/purchase.dart';
import 'package:flutter/cupertino.dart';

final CoreService coreService = CoreService(tableName: .purchase);

void PurchaseAddEdit({
  required BuildContext context,
  Purchase? purchase,
  required void Function() onDone,
  required TextEditingController invoiceNumberController,
  required TextEditingController paymentMethodController,
  required TextEditingController totalCostBeforeTaxController,
  required TextEditingController totalTaxAmountController,
  required TextEditingController totalDiscountController,
  required List<PurchaseItem> purchaseItemsCartList,
}) {
  // Check if the purchase exists
  bool isPurchaseExists = purchase != null;

  // Filing TextControllers Texts with data if the purchase exists
  invoiceNumberController.text =
      isPurchaseExists ? purchase.invoiceNumber : invoiceNumberController.text;
  paymentMethodController.text =
      isPurchaseExists ? purchase.paymentMethod : paymentMethodController.text;
  totalCostBeforeTaxController.text = isPurchaseExists
      ? purchase.totalCostBeforeTax.toString()
      : totalCostBeforeTaxController.text;
  totalTaxAmountController.text = isPurchaseExists
      ? purchase.totalTaxAmount.toString()
      : totalTaxAmountController.text;
  totalDiscountController.text = isPurchaseExists
      ? purchase.totalDiscount.toString()
      : totalDiscountController.text;

  CoreDialogFramework(
    context: context,
    title: isPurchaseExists ? 'Edit Purchase' : 'Add Purchase',
    content: Column(
      spacing: 15.0,
      children: [
        // Invoice Number Text Field
        CupertinoTextField(
          placeholder: 'Invoice Number',
          padding: const EdgeInsets.all(15.0),
          controller: invoiceNumberController,
        ),

        // Payment Method Text Field
        CupertinoTextField(
          placeholder: 'Payment Method',
          padding: const EdgeInsets.all(15.0),
          controller: paymentMethodController,
          onTap: () async {
            // Show payment method selector
            final selectedPaymentMethod = await itemSelector(
              context: context,
              items: PaymentMethodPurchase.values.map((e) => e.name).toList(),
              isSingleSelector: true,
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
        ),

        // Total Tax Amount Text Field
        CupertinoTextField(
          placeholder: 'Total Tax Amount',
          padding: const EdgeInsets.all(15.0),
          controller: totalTaxAmountController,
        ),

        // Total Discount Text Field
        CupertinoTextField(
          placeholder: 'Total Discount',
          padding: const EdgeInsets.all(15.0),
          controller: totalDiscountController,
        ),
      ],
    ),
    
    submitButton: CustomMouseCursor(
      child: CupertinoButton.filled(
        onPressed: () => _onPress(
          context: context,
          purchase: purchase,
          onDone: onDone,
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
  );
}

/// Handle the submit button press
Future<void> _onPress({
  required BuildContext context,
  required Purchase? purchase,
  required void Function() onDone,
  required bool isPurchaseExists,
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
      ErrorDialog(context: context, error: errors.join('\n'));
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
      ErrorDialog(context: context, error: errors.join('\n'));
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
    ErrorDialog(context: context, error: e.toString());
    return;
  }
}
