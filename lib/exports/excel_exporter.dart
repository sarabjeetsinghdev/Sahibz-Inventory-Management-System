// ignore_for_file: prefer_single_quotes

import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;

import 'package:sahibz_inventory/core/exceptions.dart';
import 'package:sahibz_inventory/core/logger.dart';
import 'package:sahibz_inventory/core/paths.dart';
import 'package:sahibz_inventory/features/products/models/product_model.dart';
import 'package:sahibz_inventory/features/categories/models/category_model.dart';
import 'package:sahibz_inventory/features/suppliers/models/supplier_model.dart';
import 'package:sahibz_inventory/features/customers/models/customer_model.dart';
import 'package:sahibz_inventory/features/sales/models/sale_model.dart';
import 'package:sahibz_inventory/features/purchases/models/purchase_model.dart';
import 'package:sahibz_inventory/features/inventory/models/inventory_model.dart';

String _formatCellValue(dynamic val, String dateFormat, String timeFormat) {
  if (val == null) return '';
  if (val is DateTime) return _fmtDateTime(val, dateFormat, timeFormat);
  if (val is String) {
    try {
      return _fmtDateTime(DateTime.parse(val), dateFormat, timeFormat);
    } catch (_) {}
  }
  return val.toString();
}

String _fmtDateTime(DateTime dt, String dateFormat, String timeFormat) {
  if (dt.hour == 0 && dt.minute == 0 && dt.second == 0) {
    return DateFormat(dateFormat).format(dt);
  }
  return DateFormat('$dateFormat $timeFormat').format(dt);
}

class ExcelExporter {
  Future<String> exportProducts(List<ProductModel> products,
      {String? outputDir,
      String dateFormat = 'dd/MM/yyyy',
      String timeFormat = 'HH:mm'}) async {
    return exportReport(
        'Products',
        products.map((p) => p.toJson()).toList(),
        [
          'name',
          'sku',
          'barcode',
          'categoryName',
          'supplierName',
          'costPrice',
          'sellingPrice',
          'quantity',
          'reorderLevel',
          'unit',
          'status',
        ],
        outputDir: outputDir,
        dateFormat: dateFormat,
        timeFormat: timeFormat);
  }

  Future<String> exportCategories(List<CategoryModel> categories,
      {String? outputDir,
      String dateFormat = 'dd/MM/yyyy',
      String timeFormat = 'HH:mm'}) async {
    return exportReport(
        'Categories',
        categories.map((c) => c.toJson()).toList(),
        [
          'name',
          'description',
          'parentName',
          'status',
        ],
        outputDir: outputDir,
        dateFormat: dateFormat,
        timeFormat: timeFormat);
  }

  Future<String> exportSuppliers(List<SupplierModel> suppliers,
      {String? outputDir,
      String dateFormat = 'dd/MM/yyyy',
      String timeFormat = 'HH:mm'}) async {
    return exportReport(
        'Suppliers',
        suppliers.map((s) => s.toJson()).toList(),
        [
          'companyName',
          'contactPerson',
          'phone',
          'email',
          'city',
          'state',
          'tinNumber',
          'status',
        ],
        outputDir: outputDir,
        dateFormat: dateFormat,
        timeFormat: timeFormat);
  }

  Future<String> exportCustomers(List<CustomerModel> customers,
      {String? outputDir,
      String dateFormat = 'dd/MM/yyyy',
      String timeFormat = 'HH:mm'}) async {
    return exportReport(
        'Customers',
        customers.map((c) => c.toJson()).toList(),
        [
          'name',
          'phone',
          'email',
          'city',
          'state',
          'tinNumber',
          'status',
        ],
        outputDir: outputDir,
        dateFormat: dateFormat,
        timeFormat: timeFormat);
  }

  Future<String> exportInventory(List<InventoryTransactionModel> transactions,
      {String? outputDir,
      String dateFormat = 'dd/MM/yyyy',
      String timeFormat = 'HH:mm'}) async {
    return exportReport(
        'Inventory Transactions',
        transactions.map((t) => t.toJson()).toList(),
        [
          'transactionDate',
          'productName',
          'type',
          'quantity',
          'unitPrice',
          'totalPrice',
          'balanceAfter',
          'reference',
          'notes',
        ],
        outputDir: outputDir,
        dateFormat: dateFormat,
        timeFormat: timeFormat);
  }

  Future<String> exportSales(List<SaleModel> sales,
      {String? outputDir,
      String dateFormat = 'dd/MM/yyyy',
      String timeFormat = 'HH:mm'}) async {
    return exportReport(
        'Sales',
        sales.map((s) => s.toJson()).toList(),
        [
          'invoiceNumber',
          'saleDate',
          'customerName',
          'subtotal',
          'taxAmount',
          'discountAmount',
          'totalAmount',
          'paidAmount',
          'dueAmount',
          'paymentStatus',
          'status',
        ],
        outputDir: outputDir,
        dateFormat: dateFormat,
        timeFormat: timeFormat);
  }

  Future<String> exportPurchases(List<PurchaseModel> purchases,
      {String? outputDir,
      String dateFormat = 'dd/MM/yyyy',
      String timeFormat = 'HH:mm'}) async {
    return exportReport(
        'Purchases',
        purchases.map((p) => p.toJson()).toList(),
        [
          'orderNumber',
          'orderDate',
          'supplierName',
          'subtotal',
          'taxAmount',
          'discountAmount',
          'shippingAmount',
          'totalAmount',
          'paymentStatus',
          'status',
        ],
        outputDir: outputDir,
        dateFormat: dateFormat,
        timeFormat: timeFormat);
  }

  Future<String> exportReport(
    String title,
    List<Map<String, dynamic>> data,
    List<String> columns, {
    String? outputDir,
    String dateFormat = 'dd/MM/yyyy',
    String timeFormat = 'HH:mm',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final excel = Excel.createExcel();
      final sheet = excel['Report'];

      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      final colCount = columns.length;
      int rowIdx = 0;

      final borderStyle = Border(
        borderStyle: BorderStyle.Thin,
        borderColorHex: ExcelColor.fromHexString('#DEE2E6'),
      );

      // Title row
      for (var ci = 0; ci < colCount; ci++) {
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: ci, rowIndex: rowIdx));
        cell.value = ci == 0
            ? TextCellValue(" ${title.toUpperCase()}")
            : TextCellValue('');
      }

      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx),
        CellIndex.indexByColumnRow(columnIndex: colCount - 1, rowIndex: rowIdx),
      );

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
          .cellStyle = CellStyle(
        bold: true,
        fontSize: 14,
        verticalAlign: VerticalAlign.Center,
        backgroundColorHex: ExcelColor.fromHexString('#2d2e30'),
        fontColorHex: ExcelColor.fromHexString('#ffffff'),
        leftBorder: borderStyle,
        rightBorder: borderStyle,
        topBorder: borderStyle,
        bottomBorder: borderStyle,
      );
      sheet.setRowHeight(rowIdx, 36);
      rowIdx++;

      // Generated timestamp row
      for (var ci = 0; ci < colCount; ci++) {
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx));
        cell.value = TextCellValue(
            ' Generated: ${DateFormat('$dateFormat $timeFormat').format(now)}');
        if (ci == 0) {
          sheet.merge(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx),
            CellIndex.indexByColumnRow(
                columnIndex: colCount - 1, rowIndex: rowIdx),
          );
        }
        cell.cellStyle = CellStyle(
          fontSize: 11,
          fontColorHex: ExcelColor.fromHexString('#475569'),
          backgroundColorHex: ExcelColor.fromHexString('#F1F5F9'),
          horizontalAlign: HorizontalAlign.Left,
          verticalAlign: VerticalAlign.Center,
          leftBorder: borderStyle,
          rightBorder: borderStyle,
          bottomBorder: borderStyle,
        );
      }
      sheet.setRowHeight(rowIdx, 22);
      rowIdx++;

      // Period row
      if (startDate != null || endDate != null) {
        final periodStr =
            'Period: ${startDate != null ? DateFormat(dateFormat).format(startDate) : '...'} - ${endDate != null ? DateFormat(dateFormat).format(endDate) : '...'}';
        for (var ci = 0; ci < colCount; ci++) {
          final cell = sheet.cell(
              CellIndex.indexByColumnRow(columnIndex: ci, rowIndex: rowIdx));
          cell.value = ci == 0 ? TextCellValue(periodStr) : TextCellValue('');
          cell.cellStyle = CellStyle(
            fontSize: 10,
            fontFamily: getFontFamily(FontFamily.Calibri),
            fontColorHex: ExcelColor.fromHexString('#475569'),
            backgroundColorHex: ExcelColor.fromHexString('#F1F5F9'),
            verticalAlign: VerticalAlign.Center,
            leftBorder: borderStyle,
            rightBorder: borderStyle,
            bottomBorder: borderStyle,
          );
        }
        sheet.setRowHeight(rowIdx, 22);
        rowIdx++;
      }

      rowIdx++;

      final headerRow = rowIdx;
      final headerStyle = CellStyle(
        bold: true,
        fontSize: 10,
        fontColorHex: ExcelColor.white,
        backgroundColorHex: ExcelColor.fromHexString('#1134A6'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        leftBorder: borderStyle,
        rightBorder: borderStyle,
        topBorder: borderStyle,
        bottomBorder: borderStyle,
      );
      for (var ci = 0; ci < colCount; ci++) {
        final header = columns[ci]
            .replaceAllMapped(RegExp('([A-Z])'), (m) => ' ${m.group(1)}')
            .trim()
            .toUpperCase();
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: ci, rowIndex: headerRow));
        cell.value = TextCellValue(header);
        cell.cellStyle = headerStyle;
      }
      sheet.setRowHeight(headerRow, 28.0);
      rowIdx = headerRow + 1;

      for (var ri = 0; ri < data.length; ri++) {
        final record = data[ri];
        final isEven = ri % 2 == 0;
        final curRow = rowIdx + ri;
        for (var ci = 0; ci < colCount; ci++) {
          final val = record[columns[ci]];
          final cell = sheet.cell(
              CellIndex.indexByColumnRow(columnIndex: ci, rowIndex: curRow));
          final isNumber = val is num;
          if (val is double) {
            cell.value = DoubleCellValue(val);
          } else if (val is int) {
            cell.value = IntCellValue(val);
          } else {
            cell.value =
                TextCellValue(_formatCellValue(val, dateFormat, timeFormat));
          }
          cell.cellStyle = CellStyle(
            backgroundColorHex:
                ExcelColor.fromHexString(isEven ? '#F8F9FA' : '#FFFFFF'),
            fontFamily: getFontFamily(FontFamily.Calibri),
            fontSize: 12,
            verticalAlign: VerticalAlign.Center,
            leftBorder: borderStyle,
            rightBorder: borderStyle,
            topBorder: borderStyle,
            bottomBorder: borderStyle,
          );
          if (isNumber) {
            cell.cellStyle!.numberFormat = NumFormat.standard_4;
          }
        }
        sheet.setRowHeight(curRow, 25);
      }
      rowIdx += data.length;

      final colWidths = List<int>.filled(colCount, 0);
      for (var ci = 0; ci < colCount; ci++) {
        final header = columns[ci]
            .replaceAllMapped(RegExp('([A-Z])'), (m) => ' ${m.group(1)}')
            .trim()
            .toUpperCase();
        colWidths[ci] = header.length;
      }

      for (var ri = 0; ri < data.length; ri++) {
        final record = data[ri];
        for (var ci = 0; ci < colCount; ci++) {
          final val =
              _formatCellValue(record[columns[ci]], dateFormat, timeFormat);
          if (val.length > colWidths[ci]) colWidths[ci] = val.length;
        }
      }
      for (var ci = 0; ci < colCount; ci++) {
        sheet.setColumnWidth(ci, (colWidths[ci] + 3).clamp(10, 60).toDouble() + 5.0);
      }

      final dir = outputDir ?? await AppPaths.exportsDir;
      final fileName =
          '${title.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = p.join(dir, fileName);

      final fileBytes = excel.encode();
      if (fileBytes == null) {
        throw const ExportException('Failed to encode Excel file');
      }
      await File(filePath).writeAsBytes(fileBytes);

      AppLogger.i('Excel exported: $filePath');
      return filePath;
    } on ExportException {
      rethrow;
    } catch (e, stack) {
      AppLogger.e('Failed to export Excel', e, stack);
      throw ExportException('Failed to export Excel: $e',
          originalError: e, stackTrace: stack);
    }
  }

  Future<void> openFile(String filePath) async {
    await OpenFile.open(filePath);
  }
}
