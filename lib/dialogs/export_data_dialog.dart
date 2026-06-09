// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:sahibz_inventory_management_system/database_helper.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:sahibz_inventory_management_system/dialogs/item_selector.dart';
import 'package:sahibz_inventory_management_system/utils/custom_mouse_cursor.dart';
import 'package:sahibz_inventory_management_system/utils/export_data/data2excel.dart';
import 'package:sahibz_inventory_management_system/utils/export_data/data2pdf.dart';
import 'package:sahibz_inventory_management_system/utils/export_data/data_selection_layer.dart';
import 'package:sahibz_inventory_management_system/utils/export_timings_enum.dart';
import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';
import 'package:sahibz_inventory_management_system/utils/picker_container.dart';

class ExportDataDialog extends StatefulWidget {
  final FlutterStorageSetter storageSetter;
  final bool darkMode;
  final DatabaseTableNames? tableName;
  const ExportDataDialog({
    super.key,
    required this.storageSetter,
    required this.darkMode,
    this.tableName,
  });

  @override
  State<ExportDataDialog> createState() => _ExportDataDialogState();
}

class _ExportDataDialogState extends State<ExportDataDialog> {
  final List<String> tableNames = DatabaseTableNames.values
      .map((e) => e.value)
      .toList();
  final exportType = ['.xlsx', '.pdf']; // default
  final timeRange = [...ExportTimingsEnum.values];
  int? _hoverIndexExportType;
  int? _selectedExportType;
  int? _hoverIndexTimeRange;
  int? _selectedTimeRange;
  final TextEditingController _tableController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tableController.text = widget.tableName?.value ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PickerContainer(
          isDarkMode: widget.darkMode,
          controller: _tableController,
          placeholder: _tableController.text.isEmpty
              ? 'Select Table'
              : _tableController.text,
          onDone: () {},
          onTapp: () async {
            // Show table selector dialog
            List<dynamic> selected = await itemSelector(
              context: context,
              items: tableNames,
              specialHeaderTitle: true,
              isSingleSelector: true,
              storageSetter: widget.storageSetter,
            );
            if (selected.isNotEmpty) {
              _tableController.text = selected.first;
            }
            setState(() {});
          },
          getProductNames: () async => tableNames,
          storageSetter: widget.storageSetter,
        ),
        SizedBox(height: 16),
        Row(
          mainAxisSize: .min,
          mainAxisAlignment: .start,
          crossAxisAlignment: .start,
          children: [
            Expanded(
              child: Padding(
                padding: .all(8.0),
                child: Column(
                  children: [
                    Text(
                      'Select export type',
                      style: .new(
                        color: widget.darkMode
                            ? CupertinoColors.white.withOpacity(0.6)
                            : CupertinoColors.black.withOpacity(0.6),
                      ),
                    ),
                    SizedBox(height: 16),
                    ...exportType.asMap().entries.map(
                      (entry) => CustomMouseCursor(
                        onEnter: (p0) {
                          _hoverIndexExportType = entry.key;
                          setState(() {});
                        },
                        onExit: (p0) {
                          _hoverIndexExportType = null;
                          setState(() {});
                        },
                        child: CupertinoListTile(
                          key: ValueKey(entry.key),
                          title: Text(
                            entry.value,
                            style: .new(
                              color: widget.darkMode
                                  ? CupertinoColors.white
                                  : CupertinoColors.black,
                            ),
                          ),
                          backgroundColor: _selectedExportType == entry.key
                              ? CupertinoColors.systemBlue.withOpacity(0.1)
                              : _hoverIndexExportType == entry.key
                              ? CupertinoColors.systemGrey.withOpacity(0.1)
                              : null,
                          onTap: () {
                            if (_selectedExportType != entry.key) {
                              _selectedExportType = entry.key;
                            } else {
                              _selectedExportType = null;
                            }
                            setState(() {});
                          },
                          leading: _selectedExportType == entry.key
                              ? Icon(CupertinoIcons.check_mark_circled_solid)
                              : Icon(
                                  CupertinoIcons.circle,
                                  color: widget.darkMode
                                      ? CupertinoColors.white
                                      : CupertinoColors.black,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 1,
              height: 440,
              decoration: BoxDecoration(color: CupertinoColors.systemGrey5),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: .all(8.0),
                child: Column(
                  children: [
                    Text(
                      'Select time range',
                      style: .new(
                        color: widget.darkMode
                            ? CupertinoColors.white.withOpacity(0.6)
                            : CupertinoColors.black.withOpacity(0.6),
                      ),
                    ),
                    SizedBox(height: 16),
                    ...timeRange.asMap().entries.map(
                      (entry) => CustomMouseCursor(
                        onEnter: (p0) {
                          _hoverIndexTimeRange = entry.key;
                          setState(() {});
                        },
                        onExit: (p0) {
                          _hoverIndexTimeRange = null;
                          setState(() {});
                        },
                        child: CupertinoListTile(
                          key: ValueKey(entry.key),
                          title: Text(
                            entry.value.displayName,
                            style: .new(
                              color: widget.darkMode
                                  ? CupertinoColors.white
                                  : CupertinoColors.black,
                            ),
                          ),
                          backgroundColor: _selectedTimeRange == entry.key
                              ? CupertinoColors.systemBlue.withOpacity(0.1)
                              : _hoverIndexTimeRange == entry.key
                              ? CupertinoColors.systemGrey.withOpacity(0.1)
                              : null,
                          onTap: () {
                            if (_selectedTimeRange != entry.key) {
                              _selectedTimeRange = entry.key;
                            } else {
                              _selectedTimeRange = null;
                            }
                            setState(() {});
                          },
                          leading: _selectedTimeRange == entry.key
                              ? Icon(CupertinoIcons.check_mark_circled_solid)
                              : Icon(
                                  CupertinoIcons.circle,
                                  color: widget.darkMode
                                      ? CupertinoColors.white
                                      : CupertinoColors.black,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: CustomMouseCursor(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 5.0, right: 10.0),
              child: CupertinoButton.filled(
                sizeStyle: .medium,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Text('Export'),
                onPressed: () async {
                  if (_tableController.text.isEmpty) {
                    ErrorDialog(
                      context: context,
                      error: 'Please select a table to export',
                      storageSetter: widget.storageSetter,
                    );
                    return;
                  }
                  if (_selectedExportType == null) {
                    ErrorDialog(
                      context: context,
                      error: 'Please select an export type',
                      storageSetter: widget.storageSetter,
                    );
                    return;
                  }
                  if (_selectedTimeRange == null) {
                    ErrorDialog(
                      context: context,
                      error: 'Please select a time range to export',
                      storageSetter: widget.storageSetter,
                    );
                    return;
                  }
                  final DatabaseTableNames tableName = DatabaseTableNames.values
                      .firstWhere(
                        (element) => element.value == _tableController.text,
                      );

                  final ExportTimingsEnum timing = ExportTimingsEnum.values
                      .firstWhere(
                        (element) =>
                            element.name == timeRange[_selectedTimeRange!].name,
                      );
                  if (_selectedExportType != null &&
                      exportType[_selectedExportType!] == exportType[0]) {
                    await exportToExcel(
                      context: context,
                      fileName: tableName.name,
                      data: await DataLayer(
                        tableName: tableName,
                        timings: timing,
                      ),
                      tableName: tableName,
                      storageSetter: widget.storageSetter,
                    );
                  }
                  if (_selectedExportType != null &&
                      exportType[_selectedExportType!] == exportType[1]) {
                    await exportToPdf(
                      context: context,
                      fileName: tableName.name,
                      tableName: tableName,
                      rows: await DataLayer(
                        tableName: tableName,
                        timings: timing,
                      ),
                      storageSetter: widget.storageSetter,
                    );
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
