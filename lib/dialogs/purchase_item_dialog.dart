// ignore_for_file: no_leading_underscores_for_local_identifiers, deprecated_member_use, use_build_context_synchronously, non_constant_identifier_names

import 'package:sahibz_inventory_management_system/dialogs/core/coredialog_framework.dart';
import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/dialogs/purchase_dialog.dart';
import 'package:sahibz_inventory_management_system/dialogs/item_selector.dart';
import 'package:sahibz_inventory_management_system/services/core_service.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:sahibz_inventory_management_system/models/purchase_item.dart';
import 'package:sahibz_inventory_management_system/models/purchase.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sahibz_inventory_management_system/utils/suppliers_inventory_check.dart';

/// Purchase Item Dialog
///
/// This dialog allows users to add items to a purchase order. It provides functionality to:
/// - Select products from existing inventory
/// - Select suppliers from the supplier database
/// - Enter cost, quantity, and discount information
/// - View and manage a cart of purchase items
/// - Calculate totals and proceed to purchase completion
///
/// The dialog uses a two-step process:
/// 1. Add items to cart (this dialog)
/// 2. Complete purchase with invoice details (purchase_dialog.dart)

/// Entry point function to display the Purchase Item Dialog
///
/// This function creates and shows a dialog for adding items to a purchase order.
/// It wraps the actual dialog widget in the CoreDialogFramework for consistent styling.
///
/// Parameters:
/// - [context]: BuildContext for displaying the dialog
/// - [storageSetter]: Utility for accessing app settings and preferences
/// - [purchaseList]: List of existing purchases (for reference)
/// - [searchReservedPurchaseList]: Backup list for search functionality
/// - [purchaseItemList]: List of items currently in the purchase cart
/// - [searchReservedPurchaseItemList]: Backup list of cart items for search
/// - [isUpdate]: Whether this is an update operation
/// - [onAdd]: Callback function to be called when adding items
void PurchaseItemDialog({
  required BuildContext context,
  required FlutterStorageSetter storageSetter,
  required List<Purchase>? purchaseList,
  required List<Purchase>? searchReservedPurchaseList,
  required List<PurchaseItem>? purchaseItemList,
  required List<PurchaseItem>? searchReservedPurchaseItemList,
  required bool isUpdate,
  Purchase? purchase,
  VoidCallback? onAdd,
}) async {
  if (!(await suppliersInventoryCheck(
    context: context,
    storageSetter: storageSetter,
  ))) {
    return;
  }

  CoreDialogFramework(
    context: context,
    title: 'Add Purchase Items',
    storageSetter: storageSetter,
    content: _PurchaseItemDialog(
      context: context,
      storageSetter: storageSetter,
      purchaseList: purchaseList,
      searchReservedPurchaseList: searchReservedPurchaseList,
      purchaseItemList: purchaseItemList,
      searchReservedPurchaseItemList: searchReservedPurchaseItemList,
      isUpdate: isUpdate,
      purchase: purchase,
      onAdd: onAdd,
    ),
  );
}

/// Private StatefulWidget that implements the Purchase Item Dialog UI
///
/// This widget manages the state and UI for adding items to a purchase order.
/// It includes form fields for product selection, supplier selection, cost/quantity/discount entry,
/// and a table view of the current cart items.
class _PurchaseItemDialog extends StatefulWidget {
  /// BuildContext for widget operations
  final BuildContext context;

  /// Storage utility for accessing app preferences
  final FlutterStorageSetter storageSetter;

  /// List of existing purchases (reference data)
  final List<Purchase>? purchaseList;

  /// Backup list for purchase search functionality
  final List<Purchase>? searchReservedPurchaseList;

  /// List of items currently in the purchase cart
  final List<PurchaseItem>? purchaseItemList;

  /// Backup list of cart items for search functionality
  final List<PurchaseItem>? searchReservedPurchaseItemList;

  /// Whether this is an update operation
  final bool isUpdate;

  /// Purchase object for update operation
  final Purchase? purchase;

  /// Callback function to be called when adding items
  final VoidCallback? onAdd;

  const _PurchaseItemDialog({
    required this.context,
    required this.storageSetter,
    required this.purchaseList,
    required this.searchReservedPurchaseList,
    required this.purchaseItemList,
    required this.searchReservedPurchaseItemList,
    required this.isUpdate,
    this.purchase,
    this.onAdd,
  });

  @override
  State<_PurchaseItemDialog> createState() => _PurchaseItemDialogState();
}

/// State class for _PurchaseItemDialog
///
/// Manages the dialog's state including form controllers, data lists,
/// UI state flags, and calculated totals.
class _PurchaseItemDialogState extends State<_PurchaseItemDialog> {
  // Form controllers for user input fields
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _supplierIdController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // Data lists for managing purchases and items
  List<Purchase> purchaseList = []; // Current list of purchases
  List<Purchase> searchReservedPurchase = []; // Backup for search reset
  List<PurchaseItem> purchaseItemList = []; // Items in current cart
  List<PurchaseItem> searchReservedPurchaseItems = []; // Backup cart for search

  // UI state flags
  bool isDarkMode = false; // Dark mode toggle

  // Disable flags for preventing input during async operations
  bool isDisabledProductName =
      false; // Prevents product name input during selection
  bool isDisabledSupplierId =
      false; // Prevents supplier ID input during selection

  // Calculated totals for the purchase cart
  double totalQuantity = 0.0; // Sum of all item quantities
  double totalCost = 0.0; // Sum of all item costs
  double totalDiscount = 0.0; // Sum of all discounts
  double totaledTotal = 0.0; // Final total: (cost * quantity) - discount
  bool isUpdatedList = false; // Flag to check if purchase items are updated

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
    purchaseList = widget.purchaseList ?? [];
    searchReservedPurchase = widget.searchReservedPurchaseList ?? [];
    purchaseItemList = widget.purchaseItemList ?? [];
    searchReservedPurchaseItems = widget.searchReservedPurchaseItemList ?? [];
    isDarkMode = darkmode;

    // Calculate totals if there are existing items
    if (purchaseItemList.isNotEmpty) {
      calculateTotals();
    }
    setState(() {});
  }

  /// Calculate and update all totals for the purchase cart
  ///
  /// Computes:
  /// - Total quantity: Sum of all item quantities
  /// - Total cost: Sum of all item costs
  /// - Total discount: Sum of all item discounts
  /// - Grand total: (total cost * total quantity) - total discount
  ///
  /// Updates the UI after calculation.
  void calculateTotals() {
    totalQuantity = purchaseItemList.fold(
      0.0,
      (sum, item) => sum + item.quantity,
    );
    totalCost = purchaseItemList.fold(0.0, (sum, item) => sum + item.cost);
    totalDiscount = purchaseItemList.fold(
      0.0,
      (sum, item) => sum + item.discount,
    );
    totaledTotal = totalCost * totalQuantity - totalDiscount;
    setState(() {});
  }

  /// Validate numeric input fields (Cost, Quantity, Discount)
  ///
  /// Checks that the cost, quantity, and discount fields contain valid numbers.
  /// If invalid numbers are found, clears the field and shows an error dialog.
  ///
  /// Returns:
  /// - true: All fields are valid or empty
  /// - false: Invalid numbers found and error shown
  bool validateCostQtyDiscount() {
    final List<String> errors = [];

    // Check each numeric field for valid number format
    for (var entry in {
      'Cost': _costController,
      'Quantity': _quantityController,
      'Discount': _discountController,
    }.entries) {
      if (entry.value.text.isNotEmpty &&
          double.tryParse(entry.value.text) == null) {
        entry.value.clear(); // Clear invalid input
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

  /// Retrieve all product names from the inventory
  ///
  /// Fetches all items from the inventory table and extracts their names.
  /// Used for product selection dropdown.
  ///
  /// Returns:
  /// - List of product names available in inventory
  Future<List<String>> getProductNames() async {
    final items = (await CoreService(tableName: .inventory).getAll());
    return items.map((e) => e['name'] as String).toList();
  }

  /// Validate that the entered product name exists in inventory
  ///
  /// Checks if the product name entered by the user exists in the inventory.
  /// Shows an error dialog if the product is not found.
  ///
  /// Returns:
  /// - true: Product exists or field is empty
  /// - false: Product doesn't exist and error shown
  Future<bool> validateProductName() async {
    final productName = _productNameController.text.trim();
    final productNames = await getProductNames();

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

  @override
  void dispose() {
    super.dispose();

    // Clean up all text controllers to prevent memory leaks
    [
      _productNameController,
      _supplierIdController,
      _costController,
      _quantityController,
      _discountController,
    ].map((controller) {
      controller.dispose();
    });
    isUpdatedList = false;
  }

  @override
  Widget build(BuildContext context) {
    // Map of numeric field names to their controllers for easy iteration
    final data = {
      'Cost': _costController,
      'Quantity': _quantityController,
      'Discount': _discountController,
    };

    // Get screen dimensions for responsive sizing
    Size size = MediaQuery.of(context).size;

    return SizedBox(
      width: size.width * 0.75,
      height: size.height * 0.85,
      child: Stack(
        children: [
          Column(
            spacing: 8.0,
            children: [
              Row(
                spacing: 12.0,
                children: [
                  Expanded(
                    child: CupertinoTextField(
                      controller: _productNameController,
                      placeholder: 'Product Name',
                      padding: .all(12.0),
                      enabled:
                          !isDisabledProductName, // Disable during selection
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
                      onTap: () async {
                        // Disable field during selection to prevent manual input
                        isDisabledProductName = true;
                        setState(() {});

                        // Get product names
                        final productNames = await getProductNames();

                        if (productNames.isEmpty) {
                          ErrorDialog(
                            context: context,
                            error: "No products found",
                            storageSetter: widget.storageSetter,
                          );
                          isDisabledProductName = false;
                          setState(() {});
                          return;
                        }

                        // Show product selector dialog
                        List<dynamic> selected = await itemSelector(
                          context: context,
                          items: productNames,
                          isSingleSelector: true,
                          storageSetter: widget.storageSetter,
                        );

                        // Set selected product name
                        if (selected.isNotEmpty) {
                          _productNameController.text = selected.first;
                        }

                        // Re-enable field
                        isDisabledProductName = false;
                        setState(() {});
                      },
                    ),
                  ),
                  Expanded(
                    child: CupertinoTextField(
                      controller: _supplierIdController,
                      placeholder: 'Supplier ID',
                      enabled: !isDisabledSupplierId,
                      padding: .all(12.0),
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
                      onTap: () async {
                        // Disable field during selection
                        isDisabledSupplierId = true;
                        setState(() {});

                        // Fetch all suppliers from database
                        final items = (await CoreService(
                          tableName: .supplier,
                        ).getAll());

                        // Show ErrorDialog if no suppliers found
                        if (items.isEmpty) {
                          ErrorDialog(
                            context: context,
                            error: "No suppliers found",
                            storageSetter: widget.storageSetter,
                          );
                          isDisabledSupplierId = false;
                          setState(() {});
                          return;
                        }

                        // Extract supplier names for selection
                        final namedItems = items
                            .map((e) => e['name'] as String)
                            .toList();

                        // Show supplier selector dialog
                        List<dynamic> selected = await itemSelector(
                          context: context,
                          items: namedItems,
                          isSingleSelector: true,
                          storageSetter: widget.storageSetter,
                        );

                        // Set supplier ID based on selected supplier name
                        if (selected.isNotEmpty) {
                          final selectedSupplier = items.firstWhere(
                            (e) => e['name'] == selected.first,
                          );
                          _supplierIdController.text =
                              selectedSupplier['supplier_id'] as String;
                        }

                        // Re-enable field
                        isDisabledSupplierId = false;
                        setState(() {});
                      },
                    ),
                  ),

                  ...data.entries.map(
                    (entry) => Expanded(
                      child: CupertinoTextField(
                        controller: entry.value,
                        placeholder: entry.key,
                        padding: .all(12.0),
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
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(),

              CupertinoSearchTextField(
                controller: _searchController,
                placeholder: purchaseItemList.isEmpty
                    ? 'Disabled because no items in cart'
                    : 'Search...',
                enabled:
                    purchaseItemList.isNotEmpty ||
                    _searchController.text.isNotEmpty,
                itemColor: isDarkMode
                    ? purchaseItemList.isEmpty
                          ? CupertinoColors.white.withOpacity(0.2)
                          : CupertinoColors.white
                    : purchaseItemList.isEmpty
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
                  // Filter purchase items based on search query
                  // Searches across all fields of each item (case-insensitive)
                  purchaseItemList = searchReservedPurchaseItems
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

              // Show empty cart message or item table based on cart contents
              purchaseItemList.isEmpty
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
                              size: 48,
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
                        // Limit table height to 50% of screen height
                        maxHeight:
                            MediaQuery.of(widget.context).size.height * 0.5,
                      ),
                      child: SingleChildScrollView(
                        child: Table(
                          // Table border styling
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
                            // Table header row
                            TableRow(
                              children: [
                                ...[
                                  'Product Name',
                                  'Supplier ID',
                                  'Quantity',
                                  'Cost',
                                  'Discount',
                                  'Total',
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
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Data rows for each purchase item
                            ...purchaseItemList.map(
                              (item) => TableRow(
                                children: [
                                  ...[
                                    item.productName,
                                    item.supplierId,
                                    item.quantity.toString(),
                                    item.cost.toString(),
                                    item.discount.toString(),
                                    // Calculate item total: (quantity * cost) - discount
                                    (item.quantity * item.cost - item.discount)
                                        .toString(),
                                  ].map(
                                    (value) => TableCell(
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
                                        child: Text(
                                          value,
                                          textAlign: .center,
                                          style: .new(
                                            color: isDarkMode
                                                ? CupertinoColors.white
                                                : CupertinoColors.black,
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
                                          purchaseItemList.removeAt(
                                            purchaseItemList.indexOf(item),
                                          );
                                          searchReservedPurchaseItems.removeAt(
                                            searchReservedPurchaseItems.indexOf(
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
                            // Totals row at bottom of table
                            TableRow(
                              children: [
                                // Empty cells for Product Name and Supplier ID columns
                                TableCell(
                                  child: Container(
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
                                    padding: .all(8.0),
                                    child: Text(''),
                                  ),
                                ),
                                TableCell(
                                  child: Container(
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
                                    padding: .all(8.0),
                                    child: Text(''),
                                  ),
                                ),

                                // Total values for Quantity, Cost, and Discount columns
                                ...[
                                  totalQuantity,
                                  totalCost,
                                  totalDiscount,
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
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Grand total in the Total column
                                TableCell(
                                  child: Container(
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
                                    padding: .all(8.0),
                                    child: Text(
                                      totaledTotal.toString(),
                                      textAlign: .center,
                                      style: .new(
                                        fontWeight: .bold,
                                        color: isDarkMode
                                            ? CupertinoColors.white
                                            : CupertinoColors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                TableCell(
                                  child: Container(
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
                                    padding: .all(8.0),
                                    child: Text(
                                      '',
                                      textAlign: .center,
                                      style: .new(
                                        fontWeight: .bold,
                                        color: isDarkMode
                                            ? CupertinoColors.white
                                            : CupertinoColors.black,
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

                        // Collect all form data for validation
                        final dataa = {
                          'Supplier ID': _supplierIdController.text,
                          'Product Name': _productNameController.text,
                          'Quantity': _quantityController.text,
                          'Cost': _costController.text,
                          'Discount': _discountController.text,
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
                        if (!validateCostQtyDiscount()) {
                          return;
                        }

                        // Validate product exists in inventory
                        if (!(await validateProductName())) {
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
                        if (purchaseItemList.any(
                          (item) =>
                              item.productName == _productNameController.text,
                        )) {
                          // Update existing item
                          final index = purchaseItemList.indexWhere(
                            (item) =>
                                item.productName == _productNameController.text,
                          );
                          purchaseItemList[index] = purchaseItemList[index]
                              .copyWith(
                                quantity: double.parse(
                                  _quantityController.text,
                                ),
                                cost: double.parse(_costController.text),
                                discount: _discountController.text.isEmpty
                                    ? 0.0
                                    : double.parse(_discountController.text),
                              );
                          if (widget.isUpdate) {
                            isUpdatedList = true;
                          }
                          calculateTotals();
                          setState(() {});
                          return;
                        }

                        // Add new item to cart
                        purchaseItemList.add(
                          PurchaseItem(
                            id: 0, // Temporary ID, will be set by database
                            purchaseId:
                                '', // Will be set when purchase is created
                            productName: _productNameController.text,
                            supplierId: _supplierIdController.text,
                            quantity: double.parse(_quantityController.text),
                            cost: double.parse(_costController.text),
                            discount: _discountController.text.isEmpty
                                ? 0.0
                                : double.parse(_discountController.text),
                            date: DateTime.now().toIso8601String(),
                          ),
                        );

                        // Update search backup and recalculate totals
                        searchReservedPurchaseItems = List.from(
                          purchaseItemList,
                        );
                        calculateTotals();
                        if (widget.isUpdate) {
                          isUpdatedList = true;
                        }
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
                  if (purchaseItemList.isEmpty) {
                    ErrorDialog(
                      context: context,
                      error: 'Cart is empty',
                      storageSetter: widget.storageSetter,
                    );
                    return;
                  }

                  final _invoice = TextEditingController();
                  final _paymentMethod = TextEditingController();
                  final _totalTaxAmount = TextEditingController();
                  var _totalDiscount = 0.0;

                  if (widget.isUpdate) {
                    final _p = widget.purchase!;
                    _totalDiscount = _p.totalDiscount;
                    _invoice.text = _p.invoiceNumber;
                    _paymentMethod.text = _p.paymentMethod;
                    _totalTaxAmount.text = _p.totalTaxAmount.toString();
                    setState(() {});
                  }

                  // Navigate to purchase completion dialog
                  PurchaseDialog(
                    context: context,
                    storageSetter: widget.storageSetter,
                    totalCostBeforeTax: totaledTotal,
                    totalDiscount: widget.isUpdate
                        ? _totalDiscount
                        : totalDiscount,
                    purchaseItemList: purchaseItemList,
                    isUpdate: widget.isUpdate,
                    isUpdatedList: isUpdatedList,
                    purchase: widget.purchase,
                    onAdd: widget.onAdd,
                    invoiceNumber: _invoice,
                    paymentMethod: _paymentMethod,
                    totalTaxAmount: _totalTaxAmount,
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
