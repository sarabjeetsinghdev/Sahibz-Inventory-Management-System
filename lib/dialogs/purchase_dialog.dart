// ignore_for_file: use_build_context_synchronously, deprecated_member_use, unused_element, non_constant_identifier_names

import 'package:sahibz_inventory_management_system/models/payment_method_purchase_enum.dart';
import 'package:sahibz_inventory_management_system/dialogs/core/coredialog_framework.dart';
import 'package:sahibz_inventory_management_system/models/purchase.dart';
import 'package:sahibz_inventory_management_system/services/purchase_service.dart';
import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/dialogs/item_selector.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:sahibz_inventory_management_system/models/purchase_item.dart';
import 'package:flutter/cupertino.dart';

/// Purchase Dialog
///
/// This dialog is the second step in the purchase creation process. It allows users to:
/// - Enter invoice details (invoice number, payment method)
/// - Review and edit financial calculations (tax, discounts, totals)
/// - Complete the purchase order with all required information
///
/// This dialog receives the purchase items from the previous step (purchase_item_dialog.dart)
/// and handles the financial aspects of completing a purchase order.
///
/// The workflow:
/// 1. User adds items to cart (purchase_item_dialog.dart)
/// 2. User completes purchase details (this dialog)
/// 3. Purchase is saved to database

/// Entry point function to display the Purchase Dialog
///
/// This function creates and shows a dialog for completing purchase order details.
/// It wraps the actual dialog widget in the CoreDialogFramework for consistent styling.
///
/// Parameters:
/// - [context]: BuildContext for displaying the dialog
/// - [storageSetter]: Utility for accessing app settings and preferences
/// - [totalCostBeforeTax]: Total cost of all items before tax (from previous step)
/// - [totalDiscount]: Total discount amount (from previous step)
/// - [purchaseItemList]: List of items in the purchase cart (from previous step)
/// - [isUpdate]: Whether this is an update operation
void PurchaseDialog({
  required BuildContext context,
  required FlutterStorageSetter storageSetter,
  required double totalCostBeforeTax,
  required double totalDiscount,
  required List<PurchaseItem> purchaseItemList,
  required bool isUpdate,
  required bool isUpdatedList,
  Purchase? purchase,
  VoidCallback? onAdd,
  TextEditingController? invoiceNumber,
  TextEditingController? paymentMethod,
  TextEditingController? totalTaxAmount,
}) {
  CoreDialogFramework(
    context: context,
    title: 'Add Purchase',
    storageSetter: storageSetter,
    content: _PurchaseDialog(
      storageSetter: storageSetter,
      totalCostBeforeTax: totalCostBeforeTax,
      totalDiscount: totalDiscount,
      purchaseItemList: purchaseItemList,
      isUpdate: isUpdate,
      isUpdatedList: isUpdatedList,
      purchase: purchase,
      onAdd: onAdd,
      invoiceNumber: invoiceNumber,
      paymentMethod: paymentMethod,
      totalTaxAmount: totalTaxAmount,
    ),
  );
}

/// Private StatefulWidget that implements the Purchase Dialog UI
///
/// This widget manages the state and UI for completing purchase order details.
/// It includes form fields for invoice information, payment method selection,
/// and automatic calculation of taxes and totals.
class _PurchaseDialog extends StatefulWidget {
  /// Storage utility for accessing app preferences
  final FlutterStorageSetter storageSetter;

  /// Total cost before tax (from previous dialog step)
  final double totalCostBeforeTax;

  /// Total discount amount (from previous dialog step)
  final double totalDiscount;

  /// List of items being purchased (from previous dialog step)
  final List<PurchaseItem> purchaseItemList;

  /// Whether this is an update operation
  final bool isUpdate;

  /// Whether the purchase items list is updated
  final bool isUpdatedList;

  /// Purchase object for update operation
  final Purchase? purchase;

  /// Callback function to be called when adding purchase
  final VoidCallback? onAdd;

  /// Controller for invoice number field
  final TextEditingController? invoiceNumber;

  /// Payment method
  final TextEditingController? paymentMethod;

  /// Total tax amount
  final TextEditingController? totalTaxAmount;

  const _PurchaseDialog({
    required this.storageSetter,
    required this.totalCostBeforeTax,
    required this.totalDiscount,
    required this.purchaseItemList,
    required this.isUpdate,
    required this.isUpdatedList,
    this.purchase,
    this.onAdd,
    this.invoiceNumber,
    this.paymentMethod,
    this.totalTaxAmount,
  });

  @override
  State<_PurchaseDialog> createState() => _PurchaseDialogState();
}

/// State class for _PurchaseDialog
///
/// Manages the dialog's state including form controllers, UI state flags,
/// and automatic calculation of purchase totals and taxes.
class _PurchaseDialogState extends State<_PurchaseDialog> {
  // Form controllers for purchase details input
  final TextEditingController _invoiceNumberController =
      TextEditingController();
  final TextEditingController _paymentMethodController =
      TextEditingController();
  final TextEditingController _totalCostBeforeTaxController =
      TextEditingController();
  final TextEditingController _totalTaxAmountController =
      TextEditingController();
  final TextEditingController _totalCostAfterTaxController =
      TextEditingController();
  final TextEditingController _totalDiscountController =
      TextEditingController();
  final TextEditingController _grandTotalController = TextEditingController();

  // UI state flags
  bool isDarkMode = false; // Dark mode toggle
  bool initialLoad =
      false; // Flag to control validation behavior during initialization

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    // Clean up all text controllers to prevent memory leaks
    _invoiceNumberController.dispose();
    _paymentMethodController.dispose();
    _totalCostBeforeTaxController.dispose();
    _totalTaxAmountController.dispose();
    _totalCostAfterTaxController.dispose();
    _totalDiscountController.dispose();
    _grandTotalController.dispose();
    initialLoad = false;
    super.dispose();
  }

  /// Initialize the dialog state
  ///
  /// Sets up initial data from widget parameters, loads dark mode preference,
  /// populates form fields with values from the previous dialog step,
  /// and performs initial calculations.
  void init() async {
    final darkMode = await widget.storageSetter.getDarkMode() ?? false;
    isDarkMode = darkMode;

    // Populate fields with data from previous step
    _totalCostBeforeTaxController.text = widget.totalCostBeforeTax.toString();
    _totalDiscountController.text = widget.totalDiscount.toString();
    _grandTotalController.text =
        (widget.totalCostBeforeTax - widget.totalDiscount).toString();

    // If isUpdate is true, populate the invoice number field
    if (widget.isUpdate) {
      _invoiceNumberController.text = widget.invoiceNumber != null
          ? widget.invoiceNumber!.text
          : '';
      _paymentMethodController.text = widget.paymentMethod != null
          ? widget.paymentMethod!.text
          : '';
      _totalTaxAmountController.text = widget.totalTaxAmount != null
          ? widget.totalTaxAmount!.text
          : '';
      checkPaymentMethod();
    }

    // Perform initial calculations
    calculateValues();
    setState(() {});
  }

  /// Calculate and update all financial values
  ///
  /// Performs automatic calculations based on user input:
  /// - Cost After Tax = Cost Before Tax - Tax Amount
  /// - Grand Total = Cost After Tax - Discount
  ///
  /// During initial load, validation is skipped to avoid showing errors for
  /// pre-populated fields. After initial load, validation is enabled.
  void calculateValues() {
    try {
      // Get and trim input values
      final totalCostBeforeTax = _totalCostBeforeTaxController.text.trim();
      final totalTaxAmount = _totalTaxAmountController.text.trim();
      final totalDiscount = _totalDiscountController.text.trim();

      // Parse numeric values
      final totalCostBeforeTaxValue = double.tryParse(totalCostBeforeTax);
      final totalTaxAmountValue = double.tryParse(totalTaxAmount);
      final totalDiscountValue = double.tryParse(totalDiscount);

      // Validate numeric inputs (only after initial load)
      if (initialLoad == true) {
        final errors = <String>[];
        for (final value in [
          {'Total Cost Before Tax': totalCostBeforeTaxValue},
          {'Total Tax Amount': totalTaxAmountValue},
          {'Total Discount': totalDiscountValue},
        ]) {
          if (value.values.first == null) {
            errors.add("${value.keys.first} is an invalid number");
          }
        }
        if (errors.isNotEmpty) {
          ErrorDialog(
            context: context,
            error: errors.join('\n'),
            storageSetter: widget.storageSetter,
          );
          return;
        }
      }

      // Calculate cost after tax and grand total
      _totalCostAfterTaxController.text =
          (totalCostBeforeTaxValue! - totalTaxAmountValue!).toString();
      _grandTotalController.text =
          (double.parse(_totalCostAfterTaxController.text) -
                  totalDiscountValue!)
              .toString();

      // Set initial load flag after first calculation
      if (initialLoad == false) {
        initialLoad = true;
        setState(() {});
      }
    } catch (e) {
      // Handle calculation errors (show error only after initial load)
      if (initialLoad == true) {
        ErrorDialog(
          context: context,
          error: e.toString(),
          storageSetter: widget.storageSetter,
        );
      }
      if (initialLoad == true) {
        initialLoad = true;
        setState(() {});
      }
    }
  }

  /// Validate all numeric input fields
  ///
  /// Checks that all financial fields contain valid numbers.
  /// Sets default value for discount if empty and shows error dialog
  /// for any invalid numeric inputs.
  ///
  /// Returns:
  /// - true: All fields are valid
  /// - false: Invalid numbers found and error shown
  bool validateDoubles() {
    // Default discount to 0.0 if empty
    if (_totalDiscountController.text.isEmpty) {
      _totalDiscountController.text = '0.0';
    }

    final errors = <String>[];
    final dataa = {
      'Total Cost Before Tax': _totalCostBeforeTaxController,
      'Total Tax Amount': _totalTaxAmountController,
      'Total Discount': _totalDiscountController,
      'Total Cost After Tax': _totalCostAfterTaxController,
      'Grand Total': _grandTotalController,
    };

    // Validate each numeric field
    for (final entry in dataa.entries) {
      if (entry.value.text.isNotEmpty &&
          double.tryParse(entry.value.text) == null) {
        errors.add("${entry.key} must be a valid number.");
      }
    }

    // Show error dialog if validation failed
    if (errors.isNotEmpty) {
      ErrorDialog(
        context: context,
        error: errors.join('\n'),
        storageSetter: widget.storageSetter,
      );
      return false;
    }
    return true;
  }

  bool checkPaymentMethod() {
    if (_paymentMethodController.text.isNotEmpty) {
      final paymentMethods = PaymentMethodPurchase.values;
      if (paymentMethods.indexWhere(
            (e) => e.name == _paymentMethodController.text,
          ) !=
          -1) {
        return true;
      }
      ErrorDialog(
        context: context,
        error: 'Payment method does not exist',
        storageSetter: widget.storageSetter,
      );
      return false;
    }
    ErrorDialog(
      context: context,
      error: "Payment method can't be empty",
      storageSetter: widget.storageSetter,
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Map of field names to their controllers for easy iteration
    final data = {
      'Invoice Number': _invoiceNumberController,
      'Payment Method': _paymentMethodController,
      'Total Cost Before Tax': _totalCostBeforeTaxController,
      'Total Tax Amount': _totalTaxAmountController,
      'Total Cost After Tax': _totalCostAfterTaxController,
      'Total Discount': _totalDiscountController,
      'Grand Total': _grandTotalController,
    };

    final programmaticallyUneditableFields = [
      'Total Cost After Tax',
      'Grand Total',
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        spacing: 12.0,
        children: [
          ...data.entries.map(
            (entry) => Row(
              children: [
                Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? CupertinoColors.placeholderText
                        : CupertinoColors.systemGrey6,
                    borderRadius: .only(
                      topLeft: .circular(10.0),
                      bottomLeft: .circular(10.0),
                    ),
                    border: .all(
                      color: isDarkMode
                          ? CupertinoColors.white.withOpacity(0.3)
                          : CupertinoColors.black.withOpacity(0.3),
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: .symmetric(horizontal: 12.0),
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          color: isDarkMode
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: CupertinoTextField(
                    controller: entry.value,
                    enabled: !programmaticallyUneditableFields.contains(
                      entry.key,
                    ),
                    placeholderStyle: .new(
                      color: isDarkMode
                          ? CupertinoColors.white.withOpacity(0.2)
                          : CupertinoColors.black.withOpacity(0.4),
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? programmaticallyUneditableFields.contains(entry.key)
                                ? CupertinoColors.white.withOpacity(0.03)
                                : CupertinoColors.black.withOpacity(0.5)
                          : programmaticallyUneditableFields.contains(entry.key)
                          ? CupertinoColors.systemGrey5.withOpacity(0.95)
                          : CupertinoColors.systemGrey6.withOpacity(0.95),
                      border: .all(
                        color: isDarkMode
                            ? CupertinoColors.white.withOpacity(0.3)
                            : CupertinoColors.black.withOpacity(0.3),
                      ),
                      borderRadius: .only(
                        topRight: .circular(10.0),
                        bottomRight: .circular(10.0),
                      ),
                    ),
                    style: .new(
                      color: isDarkMode
                          ? programmaticallyUneditableFields.contains(entry.key)
                                ? CupertinoColors.white.withOpacity(0.4)
                                : CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                    padding: .all(10.0),
                    onTap: () async {
                      // Show payment method selector when payment method field is tapped
                      if (entry.key.toString() == 'Payment Method') {
                        final paymentMethods = PaymentMethodPurchase.values;
                        final selectedPaymentMethod = await itemSelector(
                          context: context,
                          items: paymentMethods.map((e) => e.name).toList(),
                          isSingleSelector: true,
                          storageSetter: widget.storageSetter,
                        );
                        if (selectedPaymentMethod.isNotEmpty) {
                          _paymentMethodController.text =
                              selectedPaymentMethod.first;
                        }
                      }
                    },
                    onChanged: (value) {
                      // Recalculate totals when any financial field changes
                      calculateValues();

                      // Auto-format invoice number to uppercase
                      if (entry.key.toString() == 'Invoice Number') {
                        _invoiceNumberController.value =
                            _invoiceNumberController.value.copyWith(
                              text: value.toUpperCase(),
                            );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.0),
          Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              CustomMouseCursor(
                child: CupertinoButton.filled(
                  sizeStyle: .medium,
                  color: CupertinoColors.systemRed,
                  borderRadius: .circular(10.0),
                  onPressed: () {
                    // Clear all form fields
                    for (var controller in data.values) {
                      controller.clear();
                    }
                  },
                  child: Text('Clear all'),
                ),
              ),
              CustomMouseCursor(
                child: CupertinoButton.filled(
                  sizeStyle: .medium,
                  borderRadius: .circular(10.0),
                  onPressed: () async {
                    final List<String> errors = [];

                    // Default discount to 0.0 if empty
                    if (_totalDiscountController.text.isEmpty) {
                      _totalDiscountController.text = '0.0';
                    }

                    // Validate all required fields are filled
                    for (final controller in data.keys) {
                      if (data[controller]!.text.isEmpty) {
                        errors.add("$controller cannot be empty.");
                      }
                    }

                    // Validate numeric fields
                    final dataa = {
                      'Total Cost Before Tax': _totalCostBeforeTaxController,
                      'Total Tax Amount': _totalTaxAmountController,
                      'Total Cost After Tax': _totalCostAfterTaxController,
                      'Total Discount': _totalDiscountController,
                      'Grand Total': _grandTotalController,
                    };
                    for (final controller in dataa.keys) {
                      if (dataa[controller]!.text.isNotEmpty &&
                          double.tryParse(dataa[controller]!.text) == null) {
                        errors.add("$controller must be a valid number.");
                      }
                    }

                    // Show validation errors if any
                    if (errors.isNotEmpty) {
                      ErrorDialog(
                        context: context,
                        error: errors.join('\n'),
                        storageSetter: widget.storageSetter,
                      );
                      return;
                    }

                    // Additional validation for numeric fields
                    if (!validateDoubles()) return;

                    // Check payment method
                    if (!checkPaymentMethod()) return;

                    // Initiate Purchase Service
                    final purchaseService = PurchaseService();

                    // If this is an update operation, update the existing purchase
                    if (widget.isUpdate) {
                      final purchaseUpdate = Purchase(
                        id: widget.purchase!.id,
                        purchaseId: widget.purchase!.purchaseId,
                        date: widget.purchase!.date,
                        invoiceNumber: _invoiceNumberController.text,
                        paymentMethod: _paymentMethodController.text,
                        totalCostBeforeTax: double.parse(
                          _totalCostBeforeTaxController.text,
                        ),
                        totalTaxAmount: double.parse(
                          _totalTaxAmountController.text,
                        ),
                        totalCostAfterTax: double.parse(
                          _totalCostAfterTaxController.text,
                        ),
                        totalDiscount: double.parse(
                          _totalDiscountController.text,
                        ),
                        grandTotal: double.parse(_grandTotalController.text),
                      );
                      final result = await purchaseService
                          .updatePurchasesWithItems(
                            purchase: purchaseUpdate,
                            items: widget.purchaseItemList,
                            context: context,
                            flutterStorageSetter: widget.storageSetter,
                            isUpdatedList: widget.isUpdatedList,
                          );
                      if (result) {
                        widget.onAdd?.call();
                        Navigator.pop(context);
                      } else {
                        // Show error message
                        ErrorDialog(
                          context: context,
                          error: 'Failed to update purchase',
                          storageSetter: widget.storageSetter,
                        );
                      }
                      return;
                    }

                    // Create new purchase
                    final purchase = Purchase(
                      id: 0,
                      purchaseId: '',
                      date: DateTime.now(),
                      invoiceNumber: _invoiceNumberController.text,
                      paymentMethod: _paymentMethodController.text,
                      totalCostBeforeTax: double.parse(
                        _totalCostBeforeTaxController.text,
                      ),
                      totalTaxAmount: double.parse(
                        _totalTaxAmountController.text,
                      ),
                      totalCostAfterTax: double.parse(
                        _totalCostAfterTaxController.text,
                      ),
                      totalDiscount: double.parse(
                        _totalDiscountController.text,
                      ),
                      grandTotal: double.parse(_grandTotalController.text),
                    );

                    final result = await purchaseService
                        .insertPurchasesWithItems(
                          purchase: purchase,
                          items: widget.purchaseItemList,
                          context: context,
                          flutterStorageSetter: widget.storageSetter,
                        );

                    if (result) {
                      widget.onAdd?.call();
                      Navigator.of(context).pop();
                    } else {
                      ErrorDialog(
                        context: context,
                        error: 'Failed to insert purchase',
                        storageSetter: widget.storageSetter,
                      );
                    }
                  },
                  child: Text('Submit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
