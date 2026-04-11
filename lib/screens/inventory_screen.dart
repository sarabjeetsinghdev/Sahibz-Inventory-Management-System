// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:sahibz_inventory_management_system/dialogs/core/coredialog_framework.dart';
import 'package:sahibz_inventory_management_system/dialogs/inventory_add_edit.dart';
import 'package:sahibz_inventory_management_system/services/inventory_service.dart';
import 'package:sahibz_inventory_management_system/shared/shared_screen/index.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/models/inventory.dart';
import 'package:flutter/cupertino.dart';

/// Inventory screen for managing product inventory.
///
/// This screen provides a complete interface for:
/// - Viewing all inventory items in a tabular format
/// - Adding new inventory items
/// - Editing existing inventory items
/// - Deleting inventory items with confirmation
/// - Searching and filtering inventory data
///
/// The screen uses [SharedScreen] for consistent UI layout and behavior,
/// including search functionality and action buttons.
///
/// Each inventory item has:
/// - Auto-generated unique label (8-character alphanumeric)
/// - Product name
/// - Company name
/// - Unit of measurement
/// - Creation date and optional update date
class InventoryScreen extends StatefulWidget {
  /// Creates the inventory screen widget.
  const InventoryScreen({super.key});

  @override
  State<StatefulWidget> createState() => _InventoryScreenState();
}

/// State class for [InventoryScreen].
///
/// Manages the inventory data state, form inputs, and CRUD operations.
class _InventoryScreenState extends State<InventoryScreen> {
  /// List of all inventory items currently displayed.
  List<Inventory> inventory = [];

  /// Backup list used for search filtering operations.
  ///
  /// This preserves the complete dataset while filtering for search queries.
  List<Inventory> searchReservedInventory = [];

  /// Controller for the product name input field in add/edit dialogs.
  final TextEditingController nameController = TextEditingController();

  /// Controller for the company name input field in add/edit dialogs.
  final TextEditingController companyController = TextEditingController();

  /// Controller for the unit of measurement input field in add/edit dialogs.
  final TextEditingController unitController = TextEditingController();

  /// Initializes the screen and loads inventory data.
  @override
  void initState() {
    super.initState();
    init();
  }

  /// Disposes of resources when the widget is removed.
  ///
  /// Cleans up all data lists and text controllers to prevent memory leaks.
  @override
  void dispose() {
    super.dispose();
    inventory.clear();
    searchReservedInventory.clear();
    nameController.clear();
    companyController.clear();
    unitController.clear();
  }

  /// Loads all inventory items from the database.
  ///
  /// Fetches records from the database, converts them to [Inventory] objects,
  /// and updates both the display list and search backup list.
  void init() async {

    // Copy existing data to avoid modifying the original list
    List<Inventory> _inventory = List<Inventory>.from(inventory);
    
    // Fetch inventory from database
    final _inventoryDb = await InventoryService().getAll();
    
    // Convert database records to Inventory model objects
    _inventory = _inventoryDb.map((ele) => Inventory.fromJson(ele)).toList();
    
    // Update state with new data
    setState(() {
      inventory = _inventory;
      searchReservedInventory = inventory;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SharedScreen(
      title: 'INVENTORY',
      toptitle: 'Inventory Screen',
      data: inventory.map((ele) => ele.toJson()).toList(),
      searchReserveddata: searchReservedInventory
          .map((ele) => ele.toJson())
          .toList(),
      onAdd: (onadd) {

        // Show add inventory dialog
        InventoryAddEdit(
          context: context,
          onDone: onadd,
          nameController: nameController,
          companyController: companyController,
          unitController: unitController,
        );
      },
      onUpdate: (onupdate, data) {

        // Show edit inventory dialog
        InventoryAddEdit(
          context: context,
          onDone: onupdate,
          inventory: Inventory.fromJson(data),
          nameController: nameController,
          companyController: companyController,
          unitController: unitController,
        );
      },
      onDelete: (ondelete, dataId) {

        // Show delete confirmation dialog
        CoreDialogFramework(
          context: context,
          title: 'Confirm',
          content: Text('Are you sure you want to delete this entry'),
          submitButton: CustomMouseCursor(
            child: CupertinoButton.filled(
              sizeStyle: .medium,
              color: CupertinoColors.systemRed,
              borderRadius: .circular(10.0),
              onPressed: () {
                InventoryService().delete(id: dataId);
                ondelete();
                Navigator.of(context).pop();
              },
              child: Text('Delete', style: .new(fontSize: 18.0, color: CupertinoColors.white)),
            ),
          ),
        );
      },
      onRefresh: init,
    );
  }
}
