// ignore_for_file: no_leading_underscores_for_local_identifiers, library_private_types_in_public_api, must_be_immutable, implementation_imports

import 'package:sahibz_inventory_management_system/shared/shared_screen/default_header.dart';
import 'package:sahibz_inventory_management_system/shared/shared_screen/refresh_button.dart';
import 'package:sahibz_inventory_management_system/shared/shared_screen/search_field.dart';
import 'package:sahibz_inventory_management_system/shared/shared_screen/table_data.dart';
import 'package:sahibz_inventory_management_system/shared/shared_screen/add_button.dart';
import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';
import 'package:sahibz_inventory_management_system/utils/animations.dart';
import 'package:sahibz_inventory_management_system/database_helper.dart';
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

/// Global key for accessing the state of the SharedScreen widget.
// final GlobalKey<_SharedScreenState> sharedScreenKey =
//     GlobalKey<_SharedScreenState>();

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

  /// Callback to set the storage for the screen.
  final FlutterStorageSetter storageSetter;

  /// Callback for deleting records.
  ///
  /// Receives a refresh callback and the record ID to delete.
  /// Null if delete operation is not supported.
  final void Function(
    VoidCallback ondelete,
    int dataId,
    String? purchaseId,
    String? saleId,
  )?
  onDelete;

  /// Callback to refresh the data from the database.
  final void Function() onRefresh;

  /// Callback when a row is tapped.
  final void Function(Map<String, dynamic> row)? onRowTap;

  /// Controls the outer padding of the screen content.
  ///
  /// If true or null, uses 24.0 padding. If false, uses 12.0 padding.
  final bool? isOuterPadding;

  /// Header widget to display above the table.
  final Widget? header;

  /// Should show default header?
  final bool? isDefaultHeader;

  /// Database name
  final DatabaseTableNames dbTableName;

  /// Back button
  final Widget? backButton;

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
    this.onRowTap,
    this.isOuterPadding,
    this.header,
    this.isDefaultHeader,
    required this.dbTableName,
    this.backButton,
    required this.storageSetter,
  });

  @override
  State<StatefulWidget> createState() => _SharedScreenState();
}

class _SharedScreenState extends State<SharedScreen> {
  // Search controller for Search functionality
  final TextEditingController searchController = TextEditingController();

  // Is dark mode
  bool isDarkMode = false;

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

      // if (defaultHeaderKey.currentState != null) {
      //   defaultHeaderKey.currentState!.setState(() {
      //     defaultHeaderKey.currentState!.selectedChip = '';
      //   });
      // }
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
  void deleteData(
    VoidCallback ondelete,
    int dataId,
    String? purchaseId,
    String? saleId,
  ) {
    // Check if onDelete callback is provided
    if (widget.onDelete == null) {
      return;
    }

    // Call the onDelete callback with delete function and data ID
    widget.onDelete!(ondelete, dataId, purchaseId, saleId);
  }

  @override
  void dispose() {
    super.dispose();

    // Dispose search controller after widget is disposed
    searchController.dispose();
  }

  @override
  void initState() {
    super.initState();
    init();
  }


  @override
  void didUpdateWidget(SharedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    init();
  }

  /// Initialize any state here
  void init() async {
    final FlutterStorageSetter flutterStorageSetter = FlutterStorageSetter();
    final _isDarkMode = await flutterStorageSetter.getDarkMode() ?? false;
    setState(() {
      isDarkMode = _isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeInAnimation(
      delay: Duration(milliseconds: 100),
      duration: Duration(milliseconds: 400),
      child: Container(
        padding: widget.isOuterPadding == true || widget.isOuterPadding == null
            ? EdgeInsets.all(24.0)
            : EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Row
            Row(
              children: [
                // Back button
                widget.backButton != null
                    ? widget.backButton!
                    : SizedBox.shrink(),

                // Spacer
                widget.backButton != null
                    ? SizedBox(width: 12.0)
                    : SizedBox.shrink(),

                // Title
                Text(
                  widget.title,
                  style: GoogleFonts.robotoSlab(
                    fontSize: 50.0,
                    color: isDarkMode == true
                        ? CupertinoColors.white
                        : CupertinoColors.black,
                  ),
                ),

                // Spacer
                SizedBox(width: 12.0),

                // Searchbar
                Expanded(
                  child: SearchField(
                    controller: searchController,
                    isDarkMode: isDarkMode,
                    onChanged: (query) => searchData(query),
                  ),
                ),

                // Spacer
                SizedBox(width: 12.0),

                // Refresh button
                RefreshButton(onRefresh: refreshData, isDarkMode: isDarkMode),

                // Spacer
                if (widget.onAdd != null) SizedBox(width: 12.0),

                // Add Button
                if (widget.onAdd != null)
                  AddButton(onAdd: addData, isDarkMode: isDarkMode),
              ],
            ),

            // SizedBox
            SizedBox(height: 12.0),

            // Header
            widget.header != null
                ? widget.header!
                : widget.isDefaultHeader == true
                ? SlideInAnimation(
                    delay: Duration(milliseconds: 200),
                    child: DefaultHeader(
                      refresh: widget.onRefresh,
                      tableName: widget.dbTableName,
                      storageSetter: widget.storageSetter,
                      data: widget.data,
                      ascDscOrdering:
                      (stringOrder) {
                          setState(() {
                            widget.data.sort(
                              (a, b) => a['date']!.toString().compareTo(
                                b['date']!.toString(),
                              ),
                            );
                            if (stringOrder == 'DESC') {
                              widget.data = widget.data.reversed.toList();
                            }
                          });
                        },
                      clickFunc: (data) {
                        setState(() {
                          widget.data.clear();
                          widget.data.addAll(data);
                        });
                      },
                    ),
                  )
                : SizedBox(),

            SizedBox(height: 12.0),

            // Table
            SlideInAnimation(
              delay: Duration(milliseconds: 300),
              child: TableData(
                data: widget.data,
                isDarkMode: isDarkMode,
                onUpdate: widget.onUpdate != null ? updateData : null,
                onDelete: widget.onDelete != null ? deleteData : null,
                onRefresh: widget.onRefresh,
                onRowTap: widget.onRowTap != null
                    ? (row) => widget.onRowTap!(row)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
