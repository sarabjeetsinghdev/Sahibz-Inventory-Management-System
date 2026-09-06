import 'package:sahibz_inventory/features/purchases/models/purchase_model.dart';
import 'package:sahibz_inventory/features/sales/models/sale_model.dart';
import 'package:sahibz_inventory/core/exceptions.dart';
import 'package:sahibz_inventory/core/logger.dart';
import 'package:sahibz_inventory/core/paths.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'dart:io';

class PdfExporter {
  static final PdfColor _primaryColor = PdfColor.fromHex('#2d2e30');
  static const PdfColor _accentColor = PdfColor.fromInt(0xFF3949AB);
  static const PdfColor _darkGray = PdfColor.fromInt(0xFF616161);

  Future<String> generateReport(
    String title,
    List<String> headers,
    List<Map<String, dynamic>> data, {
    String? outputDir,
    Uint8List? logo,
    Map<String, dynamic>? summary,
    DateTime? startDate,
    DateTime? endDate,
    bool openAfterExport = false,
    String dateFormat = 'dd/MM/yyyy',
    String timeFormat = 'HH:mm',
  }) async {
    try {
      final now = DateTime.now();
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildHeader(context, title, logo: logo),
          footer: (context) => _buildFooter(context),
          build: (context) => [
            if (startDate != null || endDate != null)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 16),
                child: pw.Text(
                  'Period: ${startDate != null ? _fmtDate(startDate, dateFormat, timeFormat) : '...'} - ${endDate != null ? _fmtDate(endDate, dateFormat, timeFormat) : '...'}',
                  style: const pw.TextStyle(color: _darkGray, fontSize: 10),
                ),
              ),
            _buildTable(context, headers, data,
                dateFormat: dateFormat, timeFormat: timeFormat),
            if (summary != null && summary.isNotEmpty) ...[
              pw.SizedBox(height: 24),
              _buildSummaryTable(context, summary),
            ],
            pw.SizedBox(height: 16),
            pw.Text(
              'Generated on: ${DateFormat('$dateFormat $timeFormat').format(now)}',
              style: const pw.TextStyle(color: _darkGray, fontSize: 8),
            ),
          ],
        ),
      );

      final dir = outputDir ?? await AppPaths.exportsDir;
      final fileName =
          '${title.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = p.join(dir, fileName);

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      AppLogger.i('PDF exported: $filePath');

      if (openAfterExport) {
        await OpenFile.open(filePath);
      }

      return filePath;
    } catch (e, stack) {
      AppLogger.e('Failed to generate PDF', e, stack);
      throw ExportException('Failed to generate PDF: $e',
          originalError: e, stackTrace: stack);
    }
  }

  Future<String> generateInvoice(
    SaleModel sale, {
    String? outputDir,
    Uint8List? logo,
    bool openAfterExport = false,
    String dateFormat = 'dd/MM/yyyy',
    String timeFormat = 'HH:mm',
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildHeader(context, 'INVOICE', logo: logo),
          footer: (context) => _buildFooter(context),
          build: (context) => [
            _buildInvoiceInfo(sale,
                dateFormat: dateFormat, timeFormat: timeFormat),
            pw.SizedBox(height: 16),
            _buildInvoiceItems(sale),
            pw.SizedBox(height: 16),
            _buildInvoiceTotals(sale),
            pw.SizedBox(height: 24),
            _buildInvoicePaymentInfo(sale),
          ],
        ),
      );

      final dir = outputDir ?? await AppPaths.exportsDir;
      final fileName =
          'Invoice_${sale.invoiceNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = p.join(dir, fileName);

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      AppLogger.i('Invoice PDF exported: $filePath');

      if (openAfterExport) {
        await OpenFile.open(filePath);
      }

      return filePath;
    } catch (e, stack) {
      AppLogger.e('Failed to generate invoice PDF', e, stack);
      throw ExportException('Failed to generate invoice: $e',
          originalError: e, stackTrace: stack);
    }
  }

  Future<String> generatePurchaseOrder(
    PurchaseModel purchase, {
    String? outputDir,
    Uint8List? logo,
    bool openAfterExport = false,
    String dateFormat = 'dd/MM/yyyy',
    String timeFormat = 'HH:mm',
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) =>
              _buildHeader(context, 'PURCHASE ORDER', logo: logo),
          footer: (context) => _buildFooter(context),
          build: (context) => [
            _buildPurchaseInfo(purchase,
                dateFormat: dateFormat, timeFormat: timeFormat),
            pw.SizedBox(height: 16),
            _buildPurchaseItems(purchase),
            pw.SizedBox(height: 16),
            _buildPurchaseTotals(purchase),
            pw.SizedBox(height: 24),
            _buildPurchaseTerms(purchase,
                dateFormat: dateFormat, timeFormat: timeFormat),
          ],
        ),
      );

      final dir = outputDir ?? await AppPaths.exportsDir;
      final fileName =
          'PO_${purchase.orderNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = p.join(dir, fileName);

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      AppLogger.i('Purchase Order PDF exported: $filePath');

      if (openAfterExport) {
        await OpenFile.open(filePath);
      }

      return filePath;
    } catch (e, stack) {
      AppLogger.e('Failed to generate purchase order PDF', e, stack);
      throw ExportException('Failed to generate purchase order: $e',
          originalError: e, stackTrace: stack);
    }
  }

  pw.Widget _buildHeader(pw.Context context, String title, {Uint8List? logo}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Row(
              children: [
                if (logo != null)
                  pw.Image(pw.MemoryImage(logo), width: 48, height: 48)
                else
                  pw.Container(
                    width: 42,
                    height: 42,
                    decoration: pw.BoxDecoration(
                      color: _primaryColor,
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Center(
                      child: pw.Text('SZ',
                          style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 18)),
                    ),
                  ),
                pw.SizedBox(width: 12),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('SahibZ Enterprise',
                        style: pw.TextStyle(
                            color: _primaryColor,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 16)),
                    pw.Text('Inventory Management System',
                        style:
                            const pw.TextStyle(color: _darkGray, fontSize: 9)),
                  ],
                ),
              ],
            ),
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: pw.BoxDecoration(
                color: _primaryColor,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(title,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                      color: PdfColors.white)),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(height: 2, color: _primaryColor),
        pw.SizedBox(height: 6),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Container(height: 1, color: _primaryColor),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('SahibZ Enterprise',
                style: const pw.TextStyle(color: _darkGray, fontSize: 8)),
            pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(color: _darkGray, fontSize: 8)),
          ],
        ),
      ],
    );
  }

  String _fmtDateTime(DateTime dt, String dateFormat, String timeFormat) {
    if (dt.hour == 0 && dt.minute == 0 && dt.second == 0) {
      return DateFormat(dateFormat).format(dt);
    }
    return DateFormat('$dateFormat $timeFormat').format(dt);
  }

  String _fmtDate(dynamic val, String dateFormat, String timeFormat) {
    if (val == null) return '';
    if (val is DateTime) return _fmtDateTime(val, dateFormat, timeFormat);
    if (val is String) {
      try {
        return _fmtDateTime(DateTime.parse(val), dateFormat, timeFormat);
      } catch (_) {}
    }
    return val.toString();
  }

  String _formatCellValue(dynamic val, String dateFormat, String timeFormat) {
    if (val is double) return val.toStringAsFixed(2);
    if (val is int) return val.toString();
    if (val is bool) return val ? 'Yes' : 'No';
    return _fmtDate(val, dateFormat, timeFormat);
  }

  pw.Widget _buildTable(
      pw.Context context, List<String> headers, List<Map<String, dynamic>> data,
      {String dateFormat = 'dd/MM/yyyy', String timeFormat = 'HH:mm'}) {
    final formattedHeaders = headers
        .map((h) => h
            .replaceAllMapped(RegExp('([A-Z])'), (match) {
              return ' ${match[0]}'; // Adds a space before the matched uppercase letter
            })
            .trim()
            .toUpperCase())
        .toList();
    final colWidths = <int, double>{};
    for (var i = 0; i < headers.length; i++) {
      colWidths[i] = i == 0 ? 2.5 : 1.0;
    }

    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: pw.BoxDecoration(color: PdfColor.fromHex('#2d2e30')),
        children: formattedHeaders
            .map((h) => pw.Container(
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#2d2e30'),
                  ),
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(h,
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          fontSize: 10)),
                ))
            .toList(),
      ),
    ];

    for (var i = 0; i < data.length; i++) {
      final row = data[i];
      final isEven = i % 2 == 0;
      rows.add(pw.TableRow(
        decoration: pw.BoxDecoration(
          color: isEven ? PdfColors.grey50 : PdfColors.white,
        ),
        children: headers.map((h) {
          final val = row[h];
          final isNumber = val is num;
          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(
              _formatCellValue(val, dateFormat, timeFormat),
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight:
                    isNumber ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ));
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        for (var i = 0; i < headers.length; i++)
          i: pw.FlexColumnWidth(colWidths[i]!)
      },
      children: rows,
    );
  }

  pw.Widget _buildSummaryTable(
      pw.Context context, Map<String, dynamic> summary) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _primaryColor, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(color: _primaryColor),
            child: pw.Text('Summary',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 12)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              children: summary.entries.map((e) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                          e.key.replaceAll(RegExp(r'([A-Z])'), r' $1').trim(),
                          style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(
                        e.value is num
                            ? (e.value as num).toStringAsFixed(2)
                            : e.value.toString(),
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInvoiceInfo(SaleModel sale,
      {String dateFormat = 'dd/MM/yyyy', String timeFormat = 'HH:mm'}) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Invoice Details',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 11)),
              pw.SizedBox(height: 4),
              pw.Text('Invoice #: ${sale.invoiceNumber}',
                  style: const pw.TextStyle(fontSize: 10)),
              pw.Text(
                  'Date: ${sale.saleDate != null ? _fmtDate(sale.saleDate, dateFormat, timeFormat) : 'N/A'}',
                  style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Status: ${sale.status.toUpperCase()}',
                  style: pw.TextStyle(
                      fontSize: 10,
                      color: sale.status == 'completed'
                          ? PdfColors.green
                          : PdfColors.orange)),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Customer Details',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 11)),
              pw.SizedBox(height: 4),
              pw.Text(sale.customerName ?? 'Walk-in Customer',
                  style: const pw.TextStyle(fontSize: 10)),
              if (sale.billingAddress != null)
                pw.Text(sale.billingAddress!,
                    style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildInvoiceItems(SaleModel sale) {
    final headers = [
      '#',
      'Product',
      'Qty',
      'Unit Price',
      'Tax',
      'Discount',
      'Total'
    ];
    final data = sale.items.asMap().entries.map((entry) {
      final item = entry.value;
      return [
        '${entry.key + 1}',
        item.productName ?? 'Unknown',
        item.quantity.toStringAsFixed(2),
        item.unitPrice.toStringAsFixed(2),
        item.taxAmount.toStringAsFixed(2),
        item.discountAmount.toStringAsFixed(2),
        item.totalPrice.toStringAsFixed(2),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headerCount: headers.length,
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(
          fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: _accentColor),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
    );
  }

  pw.Widget _buildInvoiceTotals(SaleModel sale) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _totalRow('Subtotal', sale.subtotal),
          _totalRow('Tax', sale.taxAmount),
          _totalRow('Discount', sale.discountAmount, isNegative: true),
          pw.Container(height: 1, color: PdfColors.grey400),
          _totalRow('Total', sale.totalAmount, isBold: true),
          pw.SizedBox(height: 4),
          _totalRow('Paid', sale.paidAmount),
          _totalRow('Due', sale.dueAmount, isBold: true, color: PdfColors.red),
        ],
      ),
    );
  }

  pw.Widget _buildInvoicePaymentInfo(SaleModel sale) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Payment Information',
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
          pw.SizedBox(height: 4),
          pw.Text('Payment Method: ${sale.paymentMethod ?? 'N/A'}',
              style: const pw.TextStyle(fontSize: 10)),
          pw.Text('Payment Status: ${sale.paymentStatus.toUpperCase()}',
              style: pw.TextStyle(
                  fontSize: 10,
                  color: sale.paymentStatus == 'paid'
                      ? PdfColors.green
                      : PdfColors.orange)),
          if (sale.notes != null && sale.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text('Notes: ${sale.notes}',
                style: const pw.TextStyle(fontSize: 10)),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildPurchaseInfo(PurchaseModel purchase,
      {String dateFormat = 'dd/MM/yyyy', String timeFormat = 'HH:mm'}) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Order Details',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 11)),
              pw.SizedBox(height: 4),
              pw.Text('PO #: ${purchase.orderNumber}',
                  style: const pw.TextStyle(fontSize: 10)),
              pw.Text(
                  'Date: ${purchase.orderDate != null ? _fmtDate(purchase.orderDate, dateFormat, timeFormat) : 'N/A'}',
                  style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Status: ${purchase.status.toUpperCase()}',
                  style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Supplier Details',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 11)),
              pw.SizedBox(height: 4),
              pw.Text(purchase.supplierName ?? 'Unknown',
                  style: const pw.TextStyle(fontSize: 10)),
              if (purchase.shippingAddress != null)
                pw.Text(purchase.shippingAddress!,
                    style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPurchaseItems(PurchaseModel purchase) {
    final headers = [
      '#',
      'Product',
      'Qty',
      'Unit Price',
      'Tax',
      'Discount',
      'Total'
    ];
    final data = purchase.items.asMap().entries.map((entry) {
      final item = entry.value;
      return [
        '${entry.key + 1}',
        item.productName ?? 'Unknown',
        item.quantity.toStringAsFixed(2),
        item.unitPrice.toStringAsFixed(2),
        item.taxAmount.toStringAsFixed(2),
        item.discountAmount.toStringAsFixed(2),
        item.totalPrice.toStringAsFixed(2),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headerCount: headers.length,
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(
          fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: _accentColor),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
    );
  }

  pw.Widget _buildPurchaseTotals(PurchaseModel purchase) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _totalRow('Subtotal', purchase.subtotal),
          _totalRow('Tax', purchase.taxAmount),
          _totalRow('Discount', purchase.discountAmount, isNegative: true),
          _totalRow('Shipping', purchase.shippingAmount),
          pw.Container(height: 1, color: PdfColors.grey400),
          _totalRow('Total', purchase.totalAmount, isBold: true),
        ],
      ),
    );
  }

  pw.Widget _buildPurchaseTerms(PurchaseModel purchase,
      {String dateFormat = 'dd/MM/yyyy', String timeFormat = 'HH:mm'}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Terms & Information',
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
          pw.SizedBox(height: 4),
          pw.Text('Payment Method: ${purchase.paymentMethod ?? 'N/A'}',
              style: const pw.TextStyle(fontSize: 10)),
          pw.Text('Payment Status: ${purchase.paymentStatus.toUpperCase()}',
              style: const pw.TextStyle(fontSize: 10)),
          if (purchase.expectedDelivery != null)
            pw.Text(
                'Expected Delivery: ${_fmtDate(purchase.expectedDelivery, dateFormat, timeFormat)}',
                style: const pw.TextStyle(fontSize: 10)),
          if (purchase.notes != null && purchase.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text('Notes: ${purchase.notes}',
                style: const pw.TextStyle(fontSize: 10)),
          ],
        ],
      ),
    );
  }

  pw.Widget _totalRow(String label, double amount,
      {bool isBold = false, bool isNegative = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight:
                      isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.SizedBox(width: 32),
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              '${isNegative ? '-' : ''}${amount.toStringAsFixed(2)}',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: color ?? (isNegative ? PdfColors.red : null),
              ),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List> generatePdfBytes(
    String title,
    List<String> headers,
    List<Map<String, dynamic>> data, {
    Uint8List? logo,
    Map<String, dynamic>? summary,
    String dateFormat = 'dd/MM/yyyy',
    String timeFormat = 'HH:mm',
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(context, title, logo: logo),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildTable(context, headers, data,
              dateFormat: dateFormat, timeFormat: timeFormat),
          if (summary != null && summary.isNotEmpty) ...[
            pw.SizedBox(height: 24),
            _buildSummaryTable(context, summary),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  Future<void> printDocument(
      String title, List<String> headers, List<Map<String, dynamic>> data,
      {Uint8List? logo,
      String dateFormat = 'dd/MM/yyyy',
      String timeFormat = 'HH:mm'}) async {
    try {
      final bytes = await generatePdfBytes(title, headers, data,
          logo: logo, dateFormat: dateFormat, timeFormat: timeFormat);
      await Printing.layoutPdf(
        onLayout: (_) => bytes,
      );
    } catch (e, stack) {
      AppLogger.e('Failed to print document', e, stack);
      throw PrintException('Failed to print document: $e',
          originalError: e, stackTrace: stack);
    }
  }

  Future<void> openFile(String filePath) async {
    await OpenFile.open(filePath);
  }
}
