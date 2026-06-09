// ignore_for_file: no_leading_underscores_for_local_identifiers, deprecated_member_use, use_build_context_synchronously, non_constant_identifier_names

import 'package:sahibz_inventory_management_system/dialogs/core/coredialog_framework.dart';
import 'package:sahibz_inventory_management_system/dialogs/sale_dialog.dart';
import 'package:sahibz_inventory_management_system/models/purchase_item.dart';
import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/services/core_service.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:sahibz_inventory_management_system/models/sale_item.dart';
import 'package:sahibz_inventory_management_system/models/sale.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sahibz_inventory_management_system/utils/productName_supplierId_sale.dart';
import 'package:sahibz_inventory_management_system/utils/suppliers_purchases_check.dart';

void SaleItemDialog({
  required BuildContext context,
  required FlutterStorageSetter storageSetter,
  List<SaleItem>? saleItemList,
  List<SaleItem>? searchReservedSaleItemList,
  List<Sale>? saleList,
  List<Sale>? searchReservedSaleList,
  required bool isUpdate,
  required Sale? sale,
  required VoidCallback onAdd,
}) async {
  if (!(await suppliersPurchasesCheck(
    context: context,
    storageSetter: storageSetter,
  ))) {
    return;
  }

  CoreDialogFramework(
    context: context,
    title: 'Add Sale Items',
    storageSetter: storageSetter,
    content: _SaleItemDialog(
      context: context,
      storageSetter: storageSetter,
      saleItemList: saleItemList,
      searchReservedSaleItemList: searchReservedSaleItemList,
      saleList: saleList,
      searchReservedSaleList: searchReservedSaleList,
      isUpdate: isUpdate,
      sale: sale,
      onAdd: onAdd,
    ),
  );
}

class _SaleItemDialog extends StatefulWidget {
  final BuildContext context;
  final FlutterStorageSetter storageSetter;
  final List<Sale>? saleList;
  final List<Sale>? searchReservedSaleList;
  final List<SaleItem>? saleItemList;
  final List<SaleItem>? searchReservedSaleItemList;
  final bool isUpdate;
  final Sale? sale;
  final VoidCallback? onAdd;
  const _SaleItemDialog({
    required this.context,
    required this.storageSetter,
    required this.saleList,
    this.searchReservedSaleList,
    this.saleItemList,
    this.searchReservedSaleItemList,
    required this.isUpdate,
    this.sale,
    this.onAdd,
  });

  @override
  State<_SaleItemDialog> createState() => __SaleItemDialogState();
}

class __SaleItemDialogState extends State<_SaleItemDialog> {
  // Form controllers for user input fields
  final TextEditingController _purchaseIdController = TextEditingController();
  final TextEditingController _supplierIdController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // Data lists for managing sales and items
  List<Sale> saleList = []; // Current list of sales
  List<Sale> searchReservedSale = []; // Backup for search reset
  List<SaleItem> saleItemList = []; // Items in current cart
  List<SaleItem> searchReservedSaleItems = []; // Backup cart for search

  // UI state flags
  bool isDarkMode = false; // Dark mode toggle

  // Calculated totals for the sale cart
  double totalQuantity = 0.0; // Sum of all item quantities
  double totalPrice = 0.0; // Sum of all item prices
  double totalDiscount = 0.0; // Total discount applied
  double totalTax = 0.0; // Total tax applied
  double totalCost = 0.0; // Total cost after all calculations
  double totalPriceBeforeTax = 0.0; // Total price before tax
  double totalPriceAfterTax = 0.0; // Total price after tax
  double totalPriceAfterDiscount = 0.0; // Total after discount
  double totalProfit = 0.0; // Total profit after all calculations
  bool isUpdatedList = false; // Flag to check if sale items are updated
  bool isFormEmpty = true;
  TextEditingController availableQuantity = TextEditingController(text: '0.0');

  void clearForm() {
    _purchaseIdController.clear();
    _supplierIdController.clear();
    _productNameController.clear();
    _quantityController.clear();
    _priceController.clear();
    _discountController.clear();
    _taxController.clear();
    _costController.clear();
    _searchController.clear();
    isFormEmpty = true;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  /// Initialize the dialog state
  ///
  /// Sets up initial data from widget parameters, loads dark mode preference,
  /// and calculates initial totals if there are existing items in the cart.
  void init() async {
    final darkmode = await widget.storageSetter.getDarkMode() ?? false;
    saleList = widget.saleList ?? [];
    searchReservedSale = widget.searchReservedSaleList ?? [];
    saleItemList = widget.saleItemList ?? [];
    searchReservedSaleItems = widget.searchReservedSaleItemList ?? [];
    isDarkMode = darkmode;

    // Calculate totals if there are existing items
    if (saleItemList.isNotEmpty) {
      calculateTotals();
    }

    setState(() {});
  }

  void calculateTotals() {
    totalQuantity = saleItemList.fold(0.0, (sum, item) => sum + item.quantity);
    totalPrice = saleItemList.fold(0.0, (sum, item) => sum + item.price);
    totalDiscount = saleItemList.fold(0.0, (sum, item) => sum + item.discount);
    totalTax = saleItemList.fold(0.0, (sum, item) => sum + (item.tax));
    totalCost = saleItemList.fold(0.0, (sum, item) => sum + item.cost);
    totalPriceBeforeTax = totalPrice * totalQuantity;
    totalPriceAfterTax = totalPriceBeforeTax + totalTax;
    totalPriceAfterDiscount = totalPriceAfterTax - totalDiscount;
    totalProfit = totalPriceAfterDiscount - (totalCost * totalQuantity);
    setState(() {});
  }

  bool validateCostQtyDiscountTaxPrice() {
    final List<String> errors = [];

    // Check each numeric field for valid number format
    for (var entry in {
      'Cost': _costController,
      'Quantity': _quantityController,
      'Discount': _discountController,
      'Tax': _taxController,
      'Price': _priceController,
    }.entries) {
      if (entry.value.text.isNotEmpty &&
          double.tryParse(entry.value.text) == null) {
        errors.add('${entry.key} must be a valid number');
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

  Future<List<PurchaseItem>> getPurchaseNames() async {
    final items = (await CoreService(tableName: .purchaseItem).getAll());
    return items.map((item) => PurchaseItem.fromJson(item)).toList();
  }

  Future<bool> validateProductName() async {
    final productName = _productNameController.text.trim();
    final productNames = (await getPurchaseNames())
        .map((item) => item.toJson()['product_name'])
        .toList();

    // Validate product exists in inventory
    if (productName.isNotEmpty && !productNames.contains(productName)) {
      ErrorDialog(
        context: context,
        error: "Product name you entered doesn't exists",
        storageSetter: widget.storageSetter,
      );
      return false;
    }
    return true;
  }

  bool validateAvailableQuantity() {
    if (_productNameController.text.isNotEmpty) {
      if (double.tryParse(_quantityController.text) != null) {
        if (double.parse(_quantityController.text) >
            double.parse(availableQuantity.text)) {
          ErrorDialog(
            context: context,
            error:
                'Quantity cannot be greater than available quantity i.e. ${availableQuantity.text}',
            storageSetter: widget.storageSetter,
          );
          return false;
        }
      } else {
        ErrorDialog(
          context: context,
          error: 'Invalid quantity',
          storageSetter: widget.storageSetter,
        );
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    super.dispose();
    // Clean up all text controllers to prevent memory leaks
    [
      _purchaseIdController,
      _supplierIdController,
      _productNameController,
      _costController,
      _quantityController,
      _discountController,
      _taxController,
      _priceController,
      _searchController,
    ].map((controller) {
      controller.dispose();
    });
    isUpdatedList = false;
  }

  @override
  Widget build(BuildContext context) {
    final data = {
      'Purchase ID': _purchaseIdController,
      'Quantity': _quantityController,
      'Discount': _discountController,
      'Tax': _taxController,
      'Price': _priceController,
    };
    Size size = MediaQuery.of(context).size;
    return SizedBox(
      width: size.width * 0.75,
      height: size.height * 0.85,
      child: Stack(
        children: [
          Column(
            children: [
              ProductNameSupplierIdSale(
                productNameController: _productNameController,
                supplierIdController: _supplierIdController,
                storageSetter: widget.storageSetter,
                isDarkMode: isDarkMode,
                getProductNames: getPurchaseNames,
                supplierId: _supplierIdController,
                cost: _costController,
                sellingPrice: _priceController,
                purchaseId: _purchaseIdController,
                availableQuantity: availableQuantity,
                onDone: () {
                  isFormEmpty = false;
                  setState(() {});
                },
              ),
              const SizedBox(height: 16.0),
              Row(
                spacing: 16.0,
                children: [
                  ...data.entries.map(
                    (entry) => Expanded(
                      child: CupertinoTextField(
                        controller: entry.value,
                        placeholder: entry.key,
                        onChanged: (value) {
                          if (_productNameController.text.isNotEmpty) {
                            if (entry.key == 'Quantity') {
                              if (!validateAvailableQuantity()) return;
                            }
                          }
                          if (value.isNotEmpty) {
                            isFormEmpty = false;
                          } else {
                            isFormEmpty = true;
                          }
                          setState(() {});
                        },
                        placeholderStyle: .new(
                          color: isDarkMode
                              ? CupertinoColors.white.withOpacity(0.2)
                              : CupertinoColors.black.withOpacity(0.4),
                          fontSize: 16.0,
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
                          borderRadius: .circular(5.0),
                        ),
                        style: .new(
                          color: isDarkMode
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.0),
              const Divider(),
              SizedBox(height: 12.0),
              CupertinoSearchTextField(
                controller: _searchController,
                placeholder: saleItemList.isEmpty
                    ? 'Disabled because no items in cart'
                    : 'Search...',
                enabled:
                    saleItemList.isNotEmpty ||
                    _searchController.text.isNotEmpty,
                itemColor: isDarkMode
                    ? saleItemList.isEmpty
                          ? CupertinoColors.white.withOpacity(0.2)
                          : CupertinoColors.white
                    : saleItemList.isEmpty
                    ? CupertinoColors.black.withOpacity(0.2)
                    : CupertinoColors.black,
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
                  color: isDarkMode
                      ? CupertinoColors.white
                      : CupertinoColors.black,
                ),
                padding: .all(10.0),
                prefixInsets: .only(left: 12.0),
                onChanged: (value) {
                  // Filter sale items based on search query
                  // Searches across all fields of each item (case-insensitive)
                  saleItemList = searchReservedSaleItems
                      .where(
                        (item) => item.toJson().values.any(
                          (valuee) => valuee.toString().toLowerCase().contains(
                            value.toString().toLowerCase(),
                          ),
                        ),
                      )
                      .toList();
                  setState(() {});
                },
              ),

              const SizedBox(height: 12.0),

              saleItemList.isEmpty
                  ? Expanded(
                      child: Padding(
                        padding: .only(bottom: 100.0),
                        child: Column(
                          mainAxisAlignment: .center,
                          spacing: 10.0,
                          children: [
                            Icon(
                              Icons.do_not_disturb,
                              color: CupertinoColors.systemGrey.withOpacity(
                                0.5,
                              ),
                              size: 60.0,
                            ),
                            Text(
                              'No items in cart',
                              style: .new(
                                color: CupertinoColors.systemGrey.withOpacity(
                                  0.5,
                                ),
                                fontSize: 20.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight:
                            MediaQuery.of(widget.context).size.height * 0.5,
                      ),
                      child: SingleChildScrollView(
                        child: Table(
                          border: .new(
                            top: .new(color: CupertinoColors.white, width: 0.1),
                            bottom: .new(
                              color: CupertinoColors.white,
                              width: 0.1,
                            ),
                            left: .new(
                              color: CupertinoColors.white,
                              width: 0.1,
                            ),
                            right: .new(
                              color: CupertinoColors.white,
                              width: 0.1,
                            ),
                          ),
                          children: [
                            TableRow(
                              children: [
                                ...[
                                  'Product Name',
                                  'Supplier ID',
                                  'Purchase ID',
                                  'Cost per piece',
                                  'Price per piece',
                                  'Quantity',
                                  'Total Price before Tax',
                                  'Tax',
                                  'Total Price After Tax',
                                  'Discount',
                                  'Total Price After Discount',
                                  'Profit',
                                  'Actions',
                                ].map(
                                  (key) => TableCell(
                                    verticalAlignment: .intrinsicHeight,
                                    child: Container(
                                      padding: const EdgeInsets.all(10.0),
                                      decoration: BoxDecoration(
                                        color: CupertinoColors.systemFill,
                                        border: .symmetric(
                                          vertical: .new(
                                            color: isDarkMode
                                                ? CupertinoColors.white
                                                : CupertinoColors.black,
                                            width: 0.1,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        key,
                                        textAlign: .center,
                                        style: .new(
                                          color: isDarkMode
                                              ? CupertinoColors.white
                                              : CupertinoColors.black,
                                          fontSize: 14.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            ...saleItemList.map(
                              (item) => TableRow(
                                children: [
                                  ...[
                                    item.productName,
                                    item.supplierId,
                                    item.purchaseId,
                                    item.cost,
                                    item.price,
                                    item.quantity,
                                    totalPriceBeforeTax,
                                    item.tax,
                                    totalPriceAfterTax,
                                    item.discount,
                                    totalPriceAfterDiscount,
                                    totalProfit,
                                  ].map(
                                    (value) => TableCell(
                                      verticalAlignment: .intrinsicHeight,
                                      child: CustomMouseCursor(
                                        child: GestureDetector(
                                          onTap: () {
                                            _purchaseIdController.text =
                                                item.purchaseId;
                                            _supplierIdController.text =
                                                item.supplierId;
                                            _productNameController.text =
                                                item.productName;
                                            _quantityController.text = item
                                                .quantity
                                                .toString();
                                            _priceController.text = item.price
                                                .toString();
                                            _discountController.text = item
                                                .discount
                                                .toString();
                                            _taxController.text = item.tax
                                                .toString();
                                            _costController.text = item.cost
                                                .toString();
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: .all(
                                                color: isDarkMode
                                                    ? CupertinoColors.white
                                                    : CupertinoColors.black,
                                                width: 0.1,
                                              ),
                                              color: CupertinoColors.systemFill
                                                  .withOpacity(0.1),
                                            ),
                                            padding: .all(8.0),
                                            child: Text(
                                              value.toString(),
                                              textAlign: .center,
                                              style: .new(
                                                color: isDarkMode
                                                    ? CupertinoColors.white
                                                    : CupertinoColors.black,
                                                fontSize: 14.0,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  TableCell(
                                    verticalAlignment: .intrinsicHeight,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: .all(
                                          color: isDarkMode
                                              ? CupertinoColors.white
                                              : CupertinoColors.black,
                                          width: 0.1,
                                        ),
                                        color: CupertinoColors.systemFill
                                            .withOpacity(0.1),
                                      ),
                                      padding: .all(8.0),
                                      child: GestureDetector(
                                        onTap: () {
                                          // Remove this item from the list
                                          saleItemList.removeAt(
                                            saleItemList.indexOf(item),
                                          );
                                          searchReservedSaleItems.removeAt(
                                            searchReservedSaleItems.indexOf(
                                              item,
                                            ),
                                          );
                                          if (widget.isUpdate) {
                                            isUpdatedList = true;
                                          }
                                          setState(() {});
                                        },
                                        child: CustomMouseCursor(
                                          child: Icon(
                                            CupertinoIcons.delete,
                                            size: 18.0,
                                            color: CupertinoColors.systemRed,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TableRow(
                              children: [
                                ...[
                                  '',
                                  '',
                                  '',
                                  totalCost,
                                  totalPrice,
                                  totalQuantity,
                                  totalPriceBeforeTax,
                                  totalTax,
                                  totalPriceAfterTax,
                                  totalDiscount,
                                  totalPriceAfterDiscount,
                                  totalProfit,
                                  '',
                                ].map(
                                  (e) => TableCell(
                                    verticalAlignment: .intrinsicHeight,
                                    child: Container(
                                      padding: .all(8.0),
                                      decoration: BoxDecoration(
                                        border: .all(
                                          color: isDarkMode
                                              ? CupertinoColors.white
                                              : CupertinoColors.black,
                                          width: 0.1,
                                        ),
                                        color: CupertinoColors.systemFill
                                            .withOpacity(0.3),
                                      ),
                                      child: Text(
                                        e.toString(),
                                        textAlign: .center,
                                        style: .new(
                                          fontWeight: .bold,
                                          color: isDarkMode
                                              ? CupertinoColors.white
                                              : CupertinoColors.black,
                                          fontSize: 14.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
          Positioned(
            bottom: 12,
            child: Container(
              color: isDarkMode ? CupertinoColors.black : CupertinoColors.white,
              child: Row(
                children: [
                  CustomMouseCursor(
                    child: CupertinoButton.filled(
                      sizeStyle: .medium,
                      borderRadius: .circular(8.0),
                      child: Row(
                        spacing: 8.0,
                        children: [
                          const Icon(CupertinoIcons.cart_badge_plus),
                          const Text('Add'),
                        ],
                      ),
                      onPressed: () async {
                        final List<String> errors = [];

                        // Default discount to 0.0 if empty
                        if (_discountController.text.isEmpty) {
                          _discountController.text = '0.0';
                        }

                        // Default tax to 0.0 if empty
                        if (_taxController.text.isEmpty) {
                          _taxController.text = '0.0';
                        }

                        // Collect all form data for validation
                        final dataa = {
                          'Purchase ID': _purchaseIdController.text,
                          'Supplier ID': _supplierIdController.text,
                          'Product Name': _productNameController.text,
                          'Quantity': _quantityController.text,
                          'Price': _priceController.text,
                          'Discount': _discountController.text,
                          'Tax': _taxController.text,
                          'Cost': _costController.text,
                        };

                        // Validate all required fields are filled
                        for (var entry in dataa.entries) {
                          if (entry.value.isEmpty) {
                            errors.add('${entry.key} is required');
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

                        // Validate numeric fields
                        if (!validateCostQtyDiscountTaxPrice()) {
                          return;
                        }

                        // Validate product exists in inventory
                        if (!(await validateProductName())) {
                          return;
                        }

                        // Validate Quantity
                        if (!validateAvailableQuantity()) {
                          return;
                        }

                        // Validate supplier exists in database
                        final suppliers = await CoreService(
                          tableName: .supplier,
                        ).getAll();
                        final supplierIds = suppliers
                            .map(
                              (supplier) => supplier['supplier_id'] as String,
                            )
                            .toList();
                        if (!supplierIds.contains(_supplierIdController.text)) {
                          ErrorDialog(
                            context: context,
                            error: "Supplier ID you entered doesn't exists",
                            storageSetter: widget.storageSetter,
                          );
                          return;
                        }

                        // Check if product already exists in cart (update vs add)
                        if (saleItemList.any(
                          (item) =>
                              item.productName == _productNameController.text,
                        )) {
                          // Update existing item
                          final index = saleItemList.indexWhere(
                            (item) =>
                                item.productName == _productNameController.text,
                          );
                          saleItemList[index] = saleItemList[index].copyWith(
                            quantity: double.parse(_quantityController.text),
                            cost: double.parse(_costController.text),
                            discount: _discountController.text.isEmpty
                                ? 0.0
                                : double.parse(_discountController.text),
                            price: _priceController.text.isEmpty
                                ? 0.0
                                : double.parse(_priceController.text),
                            tax: _taxController.text.isEmpty
                                ? 0.0
                                : double.parse(_taxController.text),
                          );
                          if (widget.isUpdate) {
                            isUpdatedList = true;
                          }
                          calculateTotals();
                          setState(() {});
                          return;
                        }

                        // Add new item to cart
                        saleItemList.add(
                          SaleItem(
                            id: 0, // Temporary ID, will be set by database
                            purchaseId: _purchaseIdController.text,
                            saleId: '',
                            productName: _productNameController.text,
                            supplierId: _supplierIdController.text,
                            quantity: double.parse(_quantityController.text),
                            cost: double.parse(_costController.text),
                            discount: _discountController.text.isEmpty
                                ? 0.0
                                : double.parse(_discountController.text),
                            tax: _taxController.text.isEmpty
                                ? 0.0
                                : double.parse(_taxController.text),
                            price: _priceController.text.isEmpty
                                ? 0.0
                                : double.parse(_priceController.text),
                            date: DateTime.now().toIso8601String(),
                          ),
                        );

                        // Update search backup and recalculate totals
                        searchReservedSaleItems = List<SaleItem>.from(
                          saleItemList,
                        );
                        if (widget.isUpdate) {
                          isUpdatedList = true;
                        }
                        calculateTotals();
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: size.width / 2 - 270,
            child: CustomMouseCursor(
              child: CupertinoButton.filled(
                sizeStyle: .medium,
                borderRadius: .circular(10.0),
                color: CupertinoColors.systemRed,
                onPressed: isFormEmpty ? null : clearForm,
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.clear_circled_solid,
                      color: isFormEmpty
                          ? CupertinoColors.white.withOpacity(0.3)
                          : CupertinoColors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Clear form',
                      style: .new(
                        color: isFormEmpty
                            ? CupertinoColors.white.withOpacity(0.3)
                            : CupertinoColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: size.width / 2 - 125,
            child: CustomMouseCursor(
              child: CupertinoButton.filled(
                sizeStyle: .medium,
                borderRadius: .circular(10.0),
                color: CupertinoColors.systemRed,
                onPressed:
                    saleItemList.isEmpty && searchReservedSaleItems.isEmpty
                    ? null
                    : () {
                        saleItemList.clear();
                        searchReservedSaleItems.clear();
                        calculateTotals();
                        setState(() {});
                        if (widget.isUpdate) {
                          isUpdatedList = true;
                        }
                      },
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.clear_circled_solid,
                      color:
                          saleItemList.isNotEmpty ||
                              searchReservedSaleItems.isNotEmpty
                          ? CupertinoColors.white
                          : CupertinoColors.white.withOpacity(0.3),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Clear table',
                      style: .new(
                        color:
                            saleItemList.isNotEmpty ||
                                searchReservedSaleItems.isNotEmpty
                            ? CupertinoColors.white
                            : CupertinoColors.white.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            right: 0,
            child: CustomMouseCursor(
              child: CupertinoButton.filled(
                sizeStyle: .medium,
                borderRadius: .circular(8.0),
                child: Row(
                  children: [
                    const Text('Next'),
                    const Icon(CupertinoIcons.chevron_right),
                  ],
                ),
                onPressed: () {
                  // Prevent proceeding if cart is empty
                  if (saleItemList.isEmpty) {
                    ErrorDialog(
                      context: context,
                      error: 'Cart is empty',
                      storageSetter: widget.storageSetter,
                    );
                    return;
                  }

                  final _referenceNumber = TextEditingController();
                  final _paymentMethod = TextEditingController();
                  // final _totalTaxAmount = TextEditingController(
                  //   text: totalTax.toString(),
                  // );
                  var _totalDiscount = 0.0;

                  if (widget.isUpdate) {
                    final _p = widget.sale!;
                    _totalDiscount = _p.totalDiscount;
                    _referenceNumber.text = _p.referenceNumber ?? '';
                    _paymentMethod.text = _p.paymentMethod;
                    // _totalTaxAmount.text = _p.totalTax.toString();
                    setState(() {});
                  }

                  // Navigate to sale completion dialog
                  SaleDialog(
                    context: context,
                    storageSetter: widget.storageSetter,
                    isUpdate: widget.isUpdate,
                    isUpdatedList: isUpdatedList,
                    sale: widget.sale,
                    saleItemList: saleItemList,
                    totalDiscount: widget.isUpdate
                        ? _totalDiscount
                        : totalDiscount,
                    totalPriceBeforeTax: totalPriceBeforeTax,
                    onAdd: widget.onAdd,
                    paymentMethod: _paymentMethod,
                    referenceNumber: _referenceNumber,
                    totalTaxAmount: totalTax,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
