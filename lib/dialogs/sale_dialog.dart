// ignore_for_file: unused_element_parameter, use_build_context_synchronously, deprecated_member_use, non_constant_identifier_names

import 'package:sahibz_inventory_management_system/dialogs/core/coredialog_framework.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:sahibz_inventory_management_system/dialogs/item_selector.dart';
import 'package:sahibz_inventory_management_system/dialogs/success_dialog.dart';
import 'package:sahibz_inventory_management_system/models/payment_method_purchase_sale_enum.dart';
import 'package:sahibz_inventory_management_system/services/sale_service.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';
import 'package:sahibz_inventory_management_system/models/sale_item.dart';
import 'package:sahibz_inventory_management_system/models/sale.dart';
import 'package:flutter/cupertino.dart';

void SaleDialog({
  required BuildContext context,
  required FlutterStorageSetter storageSetter,
  required double totalPriceBeforeTax,
  required double totalDiscount,
  required List<SaleItem> saleItemList,
  required bool isUpdate,
  required bool isUpdatedList,
  Sale? sale,
  VoidCallback? onAdd,
  TextEditingController? referenceNumber,
  TextEditingController? paymentMethod,
  double? totalTaxAmount,
}) {
  CoreDialogFramework(
    context: context,
    title: 'Add Sale',
    storageSetter: storageSetter,
    content: _SaleDialog(
      context: context,
      storageSetter: storageSetter,
      totalPriceBeforeTax: totalPriceBeforeTax,
      totalDiscount: totalDiscount,
      saleItemList: saleItemList,
      isUpdate: isUpdate,
      isUpdatedList: isUpdatedList,
      onAdd: onAdd,
      paymentMethod: paymentMethod,
      referenceNumber: referenceNumber,
      sale: sale,
      totalTaxAmount: totalTaxAmount,
    ),
  );
}

class _SaleDialog extends StatefulWidget {
  final BuildContext context;
  final FlutterStorageSetter storageSetter;
  final double totalPriceBeforeTax;
  final double totalDiscount;
  final List<SaleItem> saleItemList;
  final bool isUpdate;
  final bool isUpdatedList;
  final Sale? sale;
  final VoidCallback? onAdd;
  final TextEditingController? referenceNumber;
  final TextEditingController? paymentMethod;
  final double? totalTaxAmount;

  const _SaleDialog({
    required this.context,
    required this.storageSetter,
    required this.totalPriceBeforeTax,
    required this.totalDiscount,
    required this.saleItemList,
    required this.isUpdate,
    required this.isUpdatedList,
    this.sale,
    this.onAdd,
    this.referenceNumber,
    this.paymentMethod,
    this.totalTaxAmount,
  });

  @override
  State<_SaleDialog> createState() => _SaleDialogState();
}

class _SaleDialogState extends State<_SaleDialog> {
  // Form controllers
  final TextEditingController _referenceNumberController =
      TextEditingController();
  final TextEditingController _paymentMethodController =
      TextEditingController();
  final TextEditingController _totalAmountBeforeTaxController =
      TextEditingController();
  final TextEditingController _totalTaxAmountController =
      TextEditingController();
  final TextEditingController _totalAmountAfterTaxController =
      TextEditingController();
  final TextEditingController _totalDiscountController =
      TextEditingController();
  final TextEditingController _netTotalController = TextEditingController();

  // UI state flags
  bool isDarkMode = false; // Dark mode toggle
  bool initialLoad =
      false; // Flag to control validation behavior during initialization

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    final darkMode = await widget.storageSetter.getDarkMode() ?? false;
    isDarkMode = darkMode;

    _totalAmountBeforeTaxController.text = widget.totalPriceBeforeTax
        .toString();
    _totalDiscountController.text = widget.totalDiscount.toString();
    _totalTaxAmountController.text = widget.totalTaxAmount?.toString() ?? '0.0';
    _totalAmountAfterTaxController.text =
        (widget.totalPriceBeforeTax + (widget.totalTaxAmount ?? 0.0))
            .toString();
    _netTotalController.text =
        (widget.totalPriceBeforeTax +
                (widget.totalTaxAmount ?? 0.0) -
                widget.totalDiscount)
            .toString();

    if (widget.isUpdate) {
      _referenceNumberController.text = widget.sale?.referenceNumber ?? '';
      _paymentMethodController.text = widget.sale?.paymentMethod ?? '';
      checkPaymentMethod();
    }
    calculateValues();
    setState(() {});
  }

  void calculateValues() {
    try {
      // Get and trim input values
      final totalAmountBeforeTax = _totalAmountBeforeTaxController.text.trim();
      final totalTaxAmount = _totalTaxAmountController.text.trim();
      final totalDiscount = _totalDiscountController.text.trim();

      // Parse numeric values
      final totalAmountBeforeTaxValue = double.tryParse(totalAmountBeforeTax);
      final totalTaxAmountValue = double.tryParse(totalTaxAmount);
      final totalDiscountValue = double.tryParse(totalDiscount);

      // Validate numeric inputs (only after initial load)
      if (initialLoad == true) {
        final errors = <String>[];
        for (final value in [
          {'Total Amount Before Tax': totalAmountBeforeTaxValue},
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
      _totalAmountAfterTaxController.text =
          (totalAmountBeforeTaxValue! + totalTaxAmountValue!).toString();
      _netTotalController.text =
          (double.parse(_totalAmountAfterTaxController.text) -
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
      if (initialLoad == false) {
        initialLoad = true;
        setState(() {});
      }
    }
  }

  bool validateDoubles() {
    // Default discount to 0.0 if empty
    if (_totalDiscountController.text.isEmpty) {
      _totalDiscountController.text = '0.0';
    }

    final errors = <String>[];
    final dataa = {
      'Total Amount Before Tax': _totalAmountBeforeTaxController,
      'Total Tax Amount': _totalTaxAmountController,
      'Total Discount': _totalDiscountController,
      'Total Amount After Tax': _totalAmountAfterTaxController,
      'Net Total': _netTotalController,
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
      final paymentMethods = PaymentMethodSale.values;
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
  void dispose() {
    // Clean up all text controllers to prevent memory leaks
    _referenceNumberController.dispose();
    _paymentMethodController.dispose();
    _totalAmountBeforeTaxController.dispose();
    _totalTaxAmountController.dispose();
    _totalAmountAfterTaxController.dispose();
    _totalDiscountController.dispose();
    _netTotalController.dispose();
    initialLoad = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Map of field names to their controllers for easy iteration
    final data = {
      'Reference Number': _referenceNumberController,
      'Payment Method': _paymentMethodController,
      'Total Amount Before Tax': _totalAmountBeforeTaxController,
      'Total Tax Amount': _totalTaxAmountController,
      'Total Amount After Tax': _totalAmountAfterTaxController,
      'Total Discount': _totalDiscountController,
      'Net Total': _netTotalController,
    };

    final programmaticallyUneditableFields = [
      'Total Amount After Tax',
      'Net Total',
    ];
    return Padding(
      padding: .all(16.0),
      child: Column(
        spacing: 12.0,
        children: [
          ...data.entries.map((entry) {
            return Row(
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
                        final paymentMethods = PaymentMethodSale.values;
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

                      // Auto-format reference number to uppercase
                      if (entry.key.toString() == 'Reference Number') {
                        _referenceNumberController.value =
                            _referenceNumberController.value.copyWith(
                              text: value.toUpperCase(),
                            );
                      }
                    },
                  ),
                ),
              ],
            );
          }),
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
                      'Total Amount Before Tax':
                          _totalAmountBeforeTaxController,
                      'Total Tax Amount': _totalTaxAmountController,
                      'Total Amount After Tax': _totalAmountAfterTaxController,
                      'Total Discount': _totalDiscountController,
                      'Net Total': _netTotalController,
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

                    // Initiate Sale Service
                    final saleService = SaleService();

                    // If this is an update operation, update the existing purchase
                    if (widget.isUpdate) {
                      final purchaseUpdate = Sale(
                        id: widget.sale!.id,
                        saleId: widget.sale!.saleId,
                        date: widget.sale!.date,
                        referenceNumber: _referenceNumberController.text,
                        paymentMethod: _paymentMethodController.text,
                        grossTotal: double.parse(
                          _totalAmountBeforeTaxController.text,
                        ),
                        totalTax: double.parse(_totalTaxAmountController.text),
                        totalDiscount: double.parse(
                          _totalDiscountController.text,
                        ),
                        netTotal: double.parse(_netTotalController.text),
                      );
                      final result = await saleService.updateSalesWithItems(
                        sale: purchaseUpdate,
                        items: widget.saleItemList,
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
                    final purchase = Sale(
                      id: 0,
                      saleId: '',
                      date: DateTime.now(),
                      referenceNumber: _referenceNumberController.text,
                      paymentMethod: _paymentMethodController.text,
                      grossTotal: double.parse(
                        _totalAmountBeforeTaxController.text,
                      ),
                      totalTax: double.parse(_totalTaxAmountController.text),
                      totalDiscount: double.parse(
                        _totalDiscountController.text,
                      ),
                      netTotal: double.parse(_netTotalController.text),
                    );

                    final result = await saleService.insertSalesWithItems(
                      sale: purchase,
                      items: widget.saleItemList,
                      context: context,
                      flutterStorageSetter: widget.storageSetter,
                    );

                    if (result) {
                      widget.onAdd?.call();
                      Navigator.of(context).pop();
                      Navigator.of(widget.context).pop();
                      SuccessDialog(
                        context: widget.context,
                        success: 'Sale inserted successfully',
                        storageSetter: widget.storageSetter,
                      );
                    } else {
                      ErrorDialog(
                        context: context,
                        error: 'Failed to insert sale',
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
