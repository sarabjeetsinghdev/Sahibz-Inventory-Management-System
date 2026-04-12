// ignore_for_file: must_be_immutable, implementation_imports

import 'package:sahibz_inventory_management_system/shared/shared_screen/refresh_button.dart';
import 'package:sahibz_inventory_management_system/shared/shared_screen/search_field.dart';
import 'package:sahibz_inventory_management_system/shared/shared_screen/table_data.dart';
import 'package:sahibz_inventory_management_system/shared/shared_screen/add_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';

/// Reusable screen layout component for data management screens.
///
/// This widget provides a consistent layout for screens that display tabular data
/// with search, add, refresh, and CRUD operations. It's used by [InventoryScreen],
/// [ExpenseScreen], and [RecentactivityScreen].
///
/// The layout consists of:
/// - A header row with title, search field, refresh button, and optional add button
/// - A data table displaying the records
/// - Built-in search filtering functionality
///
/// Features:
/// - Real-time search filtering across all columns
/// - Refresh functionality to reload data
/// - Optional add/update/delete operations
/// - Consistent styling across all data screens
///
/// Usage:
/// ```dart
/// SharedScreen(
///   title: 'INVENTORY',
///   toptitle: 'Inventory Screen',
///   data: inventoryData,
///   searchReserveddata: backupData,
///   onAdd: (refresh) => showAddDialog(refresh),
///   onUpdate: (refresh, data) => showEditDialog(refresh, data),
///   onDelete: (refresh, id) => showDeleteConfirmation(refresh, id),
///   onRefresh: loadData,
/// )
/// ```
class SharedScreen extends StatefulWidget {
  /// Title displayed at the top of the screen.
  final String toptitle;

  /// Main heading displayed in the header row.
  final String title;

  /// Current data to display in the table.
  ///
  /// This list is modified during search operations to show filtered results.
  List<Map<String, dynamic>> data;

  /// Backup of the complete dataset for search filtering.
  ///
  /// This preserves all records so search can be reset to show everything.
  List<Map<String, dynamic>> searchReserveddata;

  /// Callback for adding new records.
  ///
  /// Receives a callback function that should be called after successful addition
  /// to refresh the data display. Null if add operation is not supported.
  final void Function(VoidCallback onadd)? onAdd;

  /// Callback for updating existing records.
  ///
  /// Receives a refresh callback and the record data to update.
  /// Null if update operation is not supported.
  final void Function(VoidCallback onupdate, dynamic data)? onUpdate;

  /// Callback for deleting records.
  ///
  /// Receives a refresh callback and the record ID to delete.
  /// Null if delete operation is not supported.
  final void Function(VoidCallback ondelete, int dataId)? onDelete;

  /// Callback to refresh the data from the database.
  final void Function() onRefresh;

  /// Controls the outer padding of the screen content.
  ///
  /// If true or null, uses 24.0 padding. If false, uses 12.0 padding.
  final bool? isOuterPadding;

  /// Creates a shared screen layout widget.
  SharedScreen({
    super.key,
    required this.toptitle,
    required this.title,
    required this.data,
    required this.searchReserveddata,
    this.onAdd,
    this.onUpdate,
    this.onDelete,
    required this.onRefresh,
    this.isOuterPadding,
  });

  @override
  State<StatefulWidget> createState() => _SharedScreenState();
}

class _SharedScreenState extends State<SharedScreen> {
  // Search controller for Search functionality
  final TextEditingController searchController = TextEditingController();

  // Search data based on query
  void searchData(String query) {
    // Initialize empty data list
    List<Map<String, dynamic>> data = [];

    // Check if query is empty
    if (query.isEmpty) {
      // If query is empty, use all data
      data = widget.searchReserveddata;
    } else {
      // If query is not empty, filter data
      data = widget.searchReserveddata.where((item) {
        return item.values.any(
          (value) =>
              value.toString().toLowerCase().contains(query.toLowerCase()),
        );
      }).toList();
    }

    // Update the data and UI
    setState(() {
      widget.data.clear();
      widget.data.addAll(data);
    });
  }

  // Refresh data and update UI with new data
  void refreshData() {
    // Check if search controller has text
    if (searchController.text.isNotEmpty) {
      // Search data based on query
      searchData(searchController.text);
    } else {
      // Refresh data
      widget.onRefresh();

      // Update UI with new data
      setState(() {
        widget.data.clear();
        widget.data.addAll(widget.searchReserveddata);
      });
    }
  }

  // Function to perform after adding data
  void addData() {
    // Check if onAdd callback is provided
    if (widget.onAdd == null) {
      return;
    }

    // Call the onAdd callback with refresh function
    widget.onAdd!(widget.onRefresh);
  }

  // Function to perform after updating data
  void updateData(VoidCallback onupdate, dynamic data) {
    // Check if onUpdate callback is provided
    if (widget.onUpdate == null) {
      return;
    }

    // Call the onUpdate callback with update function and data
    widget.onUpdate!(onupdate, data);
  }

  // Function to perform after deleting data
  void deleteData(VoidCallback ondelete, int dataId) {
    // Check if onDelete callback is provided
    if (widget.onDelete == null) {
      return;
    }

    // Call the onDelete callback with delete function and data ID
    widget.onDelete!(ondelete, dataId);
  }

  @override
  void dispose() {
    super.dispose();

    // Dispose search controller after widget is disposed
    searchController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.isOuterPadding == true || widget.isOuterPadding == null
          ? EdgeInsets.all(24.0)
          : EdgeInsets.all(12.0),
      child: Column(
        children: [
          // Row
          Row(
            spacing: 16.0,
            children: [
              // Title
              Text(widget.title, style: GoogleFonts.robotoSlab(fontSize: 50.0)),
              // Searchbar
              Expanded(
                child: SearchField(
                  controller: searchController,
                  onChanged: (query) => searchData(query),
                ),
              ),
              // Refresh button
              RefreshButton(onRefresh: refreshData),
              // Add Button
              if (widget.onAdd != null) AddButton(onAdd: addData),
            ],
          ),
          // SizedBox
          SizedBox(height: 25.0),
          // Table
          TableData(
            data: widget.data,
            onUpdate: widget.onUpdate != null ? updateData : null,
            onDelete: widget.onDelete != null ? deleteData : null,
            onRefresh: widget.onRefresh,
          ),
        ],
      ),
    );
  }
}
