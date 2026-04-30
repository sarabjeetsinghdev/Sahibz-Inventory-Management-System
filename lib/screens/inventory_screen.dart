// ignore_for_file: use_build_context_synchronously, no_leading_underscores_for_local_identifiers

import 'package:sahibz_inventory_management_system/dialogs/delete_confirm_dialog.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:sahibz_inventory_management_system/dialogs/inventory_add_edit.dart';
import 'package:sahibz_inventory_management_system/services/core_service.dart';
import 'package:sahibz_inventory_management_system/shared/shared_screen/index.dart';
import 'package:sahibz_inventory_management_system/models/inventory.dart';
import 'package:flutter/cupertino.dart';
import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';

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
  final FlutterStorageSetter flutterStorage;

  /// Creates the inventory screen widget.
  const InventoryScreen({super.key, required this.flutterStorage});


  @override
  State<StatefulWidget> createState() => _InventoryScreenState();
}

/// Service for managing inventory database operations.
final CoreService coreService = CoreService(tableName: .inventory);

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
  
  // Flutter storage setter for secure storage operations
  late FlutterStorageSetter flutterStorageSetter;

  /// Initializes the screen and loads inventory data.
  @override
  void initState() {
    super.initState();
    flutterStorageSetter = widget.flutterStorage;
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
  }

  /// Loads all inventory items from the database.
  ///
  /// Fetches records from the database, converts them to [Inventory] objects,
  /// and updates both the display list and search backup list.
  void init() async {
    try {
      // Copy existing data to avoid modifying the original list
      List<Inventory> _inventory = List<Inventory>.from(inventory);

      // Fetch inventory from database
      final _inventoryDb = await coreService.getAll();

      // Convert database records to Inventory model objects
      _inventory = _inventoryDb.map((ele) => Inventory.fromJson(ele)).toList();

      // Update state with new data
      setState(() {
        inventory = _inventory;
        searchReservedInventory = inventory;
      });
    } catch (e) {
      ErrorDialog(context: context, error: e.toString(), storageSetter: flutterStorageSetter);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SharedScreen(
      storageSetter: flutterStorageSetter,
      title: 'INVENTORY',
      toptitle: 'Inventory Screen',
      dbTableName: .inventory,
      isDefaultHeader: true,
      data: inventory.map((ele) => ele.toJson()).toList(),
      searchReserveddata: searchReservedInventory
          .map((ele) => ele.toJson())
          .toList(),
      onAdd: (onadd) {
        // Show add inventory dialog
        InventoryAddEdit(
          context: context,
          onDone: onadd,
          storageSetter: flutterStorageSetter,
        );
      },
      onUpdate: (onupdate, data) {
        // Show edit inventory dialog
        InventoryAddEdit(
          context: context,
          onDone: onupdate,
          storageSetter: flutterStorageSetter,
          inventory: Inventory.fromJson(data),
        );
      },
      onDelete: (ondelete, dataId, purchaseId, saleId) {
        // Show delete confirmation dialog
        DeleteConfirmDialog(
          context: context,
          storageSetter: flutterStorageSetter,
          ondelete: () async {
            try {
              await coreService.delete(id: dataId, type: .inventoryAdded);
              ondelete();
              Navigator.of(context).pop();
            } catch (e) {
              ErrorDialog(context: context, error: e.toString(), storageSetter: flutterStorageSetter);
              rethrow;
            }
          },
        );
      },
      onRefresh: init,
    );
  }
}
