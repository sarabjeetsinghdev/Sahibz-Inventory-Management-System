// ignore_for_file: no_leading_underscores_for_local_identifiers, deprecated_member_use, must_be_immutable

import 'package:sahibz_inventory_management_system/sahibz_inventory_management_system.dart';
import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/utils/datetime_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';

/// Data table widget for displaying records with optional CRUD actions.
///
/// This widget renders a scrollable table with:
/// - Dynamic headers based on data keys
/// - Formatted date/time columns using user preferences
/// - Optional edit and delete action buttons
/// - Empty state handling with user feedback
///
/// The table automatically formats date columns using the user's selected
/// datetime format from settings. Headers are formatted using the
/// [customizeHeaderTableTitles] extension method.
///
/// Usage:
/// ```dart
/// TableData(
///   data: inventoryList,
///   onRefresh: refreshData,
///   onUpdate: (refresh, data) => showEditDialog(refresh, data),
///   onDelete: (refresh, id) => confirmDelete(refresh, id),
/// )
/// ```
class TableData extends ConsumerStatefulWidget {
  /// The data to display in the table.
  ///
  /// Each map represents one row, with keys as column headers.
  List<Map<String, dynamic>> data;

  /// Callback to refresh the data from the database.
  final void Function() onRefresh;

  /// Callback for edit action on a row.
  ///
  /// Receives a refresh callback and the row data.
  /// Null if edit operations are not supported.
  final void Function(VoidCallback onupdate, dynamic data)? onUpdate;

  /// Callback for delete action on a row.
  ///
  /// Receives a refresh callback and the row ID.
  /// Null if delete operations are not supported.
  final void Function(VoidCallback ondelete, int dataId)? onDelete;

  /// Creates a data table widget.
  TableData({
    super.key,
    this.onUpdate,
    this.onDelete,
    required this.onRefresh,
    required this.data,
  });

  @override
  ConsumerState<TableData> createState() => _TableDataState();
}

/// State class for [TableData] widget.
///
/// Manages the datetime format preference for displaying dates in the table.
class _TableDataState extends ConsumerState<TableData> {
  /// The user's selected datetime format for displaying dates.
  ///
  /// Loaded from secure storage on initialization. Null if not set.
  DateTimeParserEnum? parserEnum;

  /// Initializes the table state.
  ///
  /// Loads the user's datetime format preference from settings.
  @override
  void initState() {
    super.initState();
    init();
  }

  /// Loads the user's datetime format preference.
  ///
  /// Retrieves the selected format from secure storage and updates
  /// [parserEnum] for date column formatting.
  Future<void> init() async {
    if (mounted) {
      final flutterStorage = ref.read(flutterStorageProvider);
      final DateTimeParserEnum? _parserEnum = await flutterStorage
          .getDateTimeParserStorageEnum();
      setState(() {
        if (_parserEnum != null) {
          parserEnum = _parserEnum;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> keys = widget.data.isEmpty
        ? ['No Header']
        : widget.data.first.keys.toList();
    Size size = MediaQuery.of(context).size;
    // Table
    return Container(
      child: widget.data.isEmpty
          ? SizedBox(
              width: size.width,
              height: size.height - 240,
              child: Center(
                child: Text(
                  'No data found!',
                  style: GoogleFonts.archivo(
                    fontSize: 35.0,
                    letterSpacing: 2.0,
                    color: CupertinoColors.white.withOpacity(0.1),
                  ),
                ),
              ),
            )
          : SizedBox(
              width: size.width,
              height: size.height - 240,
              child: SingleChildScrollView(
                child: Table(
                  border: .new(
                    borderRadius: .circular(10.0),
                    top: .new(color: CupertinoColors.white, width: 0.1),
                    bottom: .new(color: CupertinoColors.white, width: 0.1),
                    left: .new(color: CupertinoColors.white, width: 0.1),
                    right: .new(color: CupertinoColors.white, width: 0.1),
                  ),
                  children: [
                    // Header
                    TableRow(
                      children: [
                        ...keys.map(
                          (ele) => TableCell(
                            verticalAlignment: .intrinsicHeight,
                            child: Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemFill,
                                border: .symmetric(
                                  vertical: .new(
                                    color: CupertinoColors.white,
                                    width: 0.1,
                                  ),
                                ),
                              ),
                              child: Center(
                                child: Text(ele.customizeHeaderTableTitles()),
                              ),
                            ),
                          ),
                        ),
                        if (widget.onUpdate != null && widget.onDelete != null)
                          TableCell(
                            verticalAlignment: .intrinsicHeight,
                            child: Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemFill,
                                border: .symmetric(
                                  vertical: .new(
                                    color: CupertinoColors.white,
                                    width: 0.1,
                                  ),
                                ),
                              ),
                              child: Center(child: Text('Actions')),
                            ),
                          ),
                      ],
                    ),

                    // Body Rows
                    ...widget.data.map(
                      (row) => TableRow(
                        children: [
                          ...row.values.map((value) {
                            return TableCell(
                              verticalAlignment: .intrinsicHeight,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: .all(
                                    color: CupertinoColors.white,
                                    width: 0.1,
                                  ),
                                  color: CupertinoColors.systemFill.withOpacity(
                                    0.1,
                                  ),
                                ),
                                padding: const EdgeInsets.all(12.0),
                                child: Center(
                                  child:
                                      DateTime.tryParse(value.toString()) !=
                                          null
                                      ? parserEnum != null
                                            ? Text(
                                                convertDateTimeString2Formatted(
                                                  DateTime.parse(
                                                    value.toString(),
                                                  ),
                                                  parserEnum!,
                                                ),
                                              )
                                            : Text(value.toString())
                                      : Text(value.toString()),
                                ),
                              ),
                            );
                          }),
                          if (widget.onUpdate != null &&
                              widget.onDelete != null)
                            TableCell(
                              verticalAlignment: .intrinsicHeight,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: .all(
                                    color: CupertinoColors.white,
                                    width: 0.1,
                                  ),
                                  color: CupertinoColors.systemFill.withOpacity(
                                    0.1,
                                  ),
                                ),
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  mainAxisAlignment: .center,
                                  spacing: 12.0,
                                  children: [
                                    CustomMouseCursor(
                                      child: GestureDetector(
                                        onTap: () {
                                          widget.onUpdate!(
                                            widget.onRefresh,
                                            row,
                                          );
                                        },
                                        child: Icon(
                                          CupertinoIcons.pencil,
                                          fontWeight: .bold,
                                        ),
                                      ),
                                    ),
                                    CustomMouseCursor(
                                      child: GestureDetector(
                                        onTap: () {
                                          widget.onDelete!(
                                            widget.onRefresh,
                                            row['id'],
                                          );
                                        },
                                        child: Icon(
                                          CupertinoIcons.delete,
                                          color: CupertinoColors.systemRed,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
