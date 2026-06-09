// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:sahibz_inventory_management_system/database_helper.dart';
import 'package:sahibz_inventory_management_system/dialogs/error_dialog.dart';
import 'package:sahibz_inventory_management_system/sahibz_inventory_management_system.dart';
import 'package:sahibz_inventory_management_system/utils/datetime_formatter.dart';
import 'package:sahibz_inventory_management_system/utils/flutter_storage_setter.dart';
import 'package:flutter/cupertino.dart';

/// Export data to excel
///
/// This function exports data from the specified table to an excel file.
///
/// Parameters:
/// - `tableName`: The name of the table to export data from.
/// - `storageSetter`: The storage setter for writing the excel file.
///
/// Returns a [Future] that completes with the path of the exported excel file.
Future<void> exportToExcel({
  required BuildContext context,
  required String fileName,
  required List<Map<String, dynamic>> data,
  required DatabaseTableNames tableName,
  required FlutterStorageSetter storageSetter,
}) async {
  if (data.isEmpty) {
    ErrorDialog(
      context: context,
      error: 'No data found to export',
      storageSetter: storageSetter,
    );
    return;
  }
  final DateTimeParserEnum? parserEnum = await storageSetter
      .getDateTimeParserStorageEnum();

  if (parserEnum == null) {
    ErrorDialog(
      context: context,
      error: 'DateTime parser enum not found',
      storageSetter: storageSetter,
    );
    return;
  }

  final excel = Excel.createExcel();
  final sheet = excel.sheets['Sheet1'];

  if (sheet == null) {
    ErrorDialog(
      context: context,
      error: 'Sheet not found',
      storageSetter: storageSetter,
    );
    return;
  }

  sheet.appendRow(
    data.first.keys
        .map(
          (key) =>
              TextCellValue(key.toUpperCase().customizeHeaderTableTitles()),
        )
        .toList(),
  );

  final headerStyle = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString('#F8CBAD'),
    verticalAlign: .Center,
    horizontalAlign: .Center,
    fontSize: 12,
    leftBorder: .new(borderStyle: .Thin, borderColorHex: .black),
    rightBorder: .new(borderStyle: .Thin, borderColorHex: .black),
    topBorder: .new(borderStyle: .Thin, borderColorHex: .black),
    bottomBorder: .new(borderStyle: .Thin, borderColorHex: .black),
  );

  for (var i = 0; i < data.first.keys.length; i++) {
    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .cellStyle =
        headerStyle;
    sheet.setColumnWidth(i, 25);
    sheet.setRowHeight(0, 20);
  }

  final dataStyle = CellStyle(
    verticalAlign: .Center,
    horizontalAlign: .Center,
    fontSize: 12,
    leftBorder: .new(borderStyle: .Thin, borderColorHex: .black),
    rightBorder: .new(borderStyle: .Thin, borderColorHex: .black),
    topBorder: .new(borderStyle: .Thin, borderColorHex: .black),
    bottomBorder: .new(borderStyle: .Thin, borderColorHex: .black),
  );

  for (var i = 0; i < data.length; i++) {
    sheet.appendRow(
      data[i].values
          .map(
            (value) => TextCellValue(
              value.toString().isEmpty
                  ? 'null'
                  : DateTime.tryParse(value.toString()) != null
                  ? convertDateTimeString2Formatted(
                      DateTime.parse(value.toString()),
                      parserEnum,
                    )
                  : value.toString(),
            ),
          )
          .toList(),
    );
  }

  for (var i = 0; i < data.first.keys.length; i++) {
    for (var j = 0; j < data.length; j++) {
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: j + 1))
              .cellStyle =
          dataStyle;
      sheet.setColumnAutoFit(i);
      sheet.setRowHeight(j + 1, 20);
    }
  }

  final filePath = './$fileName.xlsx';
  final file = File(filePath);
  file.writeAsBytesSync(excel.encode()!);
}
