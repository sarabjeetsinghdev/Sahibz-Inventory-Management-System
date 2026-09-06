// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:easy_localization/easy_localization.dart';
import 'package:share_plus/share_plus.dart';

import 'package:sahibz_inventory/core/extensions.dart';
import 'package:sahibz_inventory/database/database.dart';
import 'package:sahibz_inventory/features/reports/models/report_models.dart';
import 'package:sahibz_inventory/features/reports/providers/report_provider.dart';
import 'package:sahibz_inventory/features/reports/screens/report_list_screen.dart';
import 'package:sahibz_inventory/features/settings/providers/settings_provider.dart';
import 'package:sahibz_inventory/exports/excel_exporter.dart';
import 'package:sahibz_inventory/exports/pdf_exporter.dart';
import 'package:sahibz_inventory/shared/app_colors.dart';
import 'package:sahibz_inventory/shared/custom_modal.dart';
import 'package:sahibz_inventory/shared/item_selector.dart';
import 'package:sahibz_inventory/shared/widgets/custom_action_sheet.dart';
import 'package:sahibz_inventory/shared/widgets/filter_chip.dart';
import 'package:sahibz_inventory/shared/custom_mouse_pointer.dart';
import 'package:sahibz_inventory/themes/app_typography.dart';

class ReportViewerScreen extends ConsumerStatefulWidget {
  final ReportTypeConfig config;

  const ReportViewerScreen({super.key, required this.config});

  @override
  ConsumerState<ReportViewerScreen> createState() => _ReportViewerScreenState();
}

class _ReportViewerScreenState extends ConsumerState<ReportViewerScreen> {
  bool _noDataModalShown = false;
  String? _selectedCategoryId;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCategories());
  }

  Future<void> _loadCategories() async {
    try {
      final db = ref.read(databaseProvider);
      final cats = await (db.select(db.categories)
            ..where((c) => c.isDeleted.equals(false))
            ..orderBy([(c) => OrderingTerm.asc(c.name)]))
          .get();
      if (mounted) setState(() => _categories = cats);
    } catch (_) {}
  }

  List<InventoryValuationRow> _valuationRows(ReportState state) {
    final list = state.valuationReport ?? const <InventoryValuationRow>[];
    if (_selectedCategoryId == null) return list;
    return list.where((r) => r.categoryId == _selectedCategoryId).toList();
  }

  String? get _selectedCategoryName {
    if (_selectedCategoryId == null) return null;
    for (final c in _categories) {
      if (c.id == _selectedCategoryId) return c.name;
    }
    return null;
  }

  void _showCategoryFilter(BuildContext context) {
    showCustomModal(
      context: context,
      builder: (_) => ItemSelector(
        items: ['all', ..._categories.map((c) => c.id)],
        labels: ['All Categories', ..._categories.map((c) => c.name)],
        initialValue: _selectedCategoryId ?? 'all',
        onSelected: (value) {
          setState(
              () => _selectedCategoryId = value == 'all' ? null : value);
        },
      ),
    );
  }

  bool _isEmptyReport(ReportState state) {
    if (state.inventoryReport != null) return state.inventoryReport!.isEmpty;
    if (state.valuationReport != null) return state.valuationReport!.isEmpty;
    if (state.stockMovementReport != null) {
      return state.stockMovementReport!.isEmpty;
    }
    if (state.salesReport != null) return state.salesReport!.isEmpty;
    if (state.purchaseReport != null) return state.purchaseReport!.isEmpty;
    if (state.supplierReport != null) return state.supplierReport!.isEmpty;
    if (state.customerReport != null) return state.customerReport!.isEmpty;
    if (state.auditReport != null) return state.auditReport!.isEmpty;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportProvider);

    if (!state.isLoading &&
        state.error == null &&
        state.hasData &&
        _isEmptyReport(state) &&
        !_noDataModalShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _noDataModalShown) return;
        _noDataModalShown = true;
        _showNoDataModal(context);
      });
    }

    final showCategoryFilter = state.valuationReport != null;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.config.title),
        trailing: state.hasData
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showCategoryFilter)
                    CustomPointer(
                        child: GestureDetector(
                      onTap: () => _showCategoryFilter(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _selectedCategoryId != null
                              ? context.primaryColor
                              : context.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.slider_horizontal_3,
                              size: 14,
                              color: _selectedCategoryId != null
                                  ? CupertinoColors.white
                                  : context.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Category',
                              style: AppTypography.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _selectedCategoryId != null
                                    ? CupertinoColors.white
                                    : context.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                  CustomPointer(
                      child: GestureDetector(
                    onTap: () => _showExportMenu(context, ref),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(CupertinoIcons.share,
                          color: context.primaryColor),
                    ),
                  )),
                ],
              )
            : null,
      ),
      child: state.isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : state.error != null
              ? _buildError(context, state.error!)
              : _buildReportContent(context, state),
    );
  }

  void _showNoDataModal(BuildContext ctx) {
    showCustomModal(
      context: ctx,
      builder: (c) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.doc_text_search,
                size: 48, color: context.primaryColor),
            const SizedBox(height: 16),
            Text('no_data_available'.tr(),
                style: AppTypography.poppins(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('no_records_for_report'.tr(),
                style: AppTypography.poppins(
                    fontSize: 14, color: context.secondaryTextColor),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                child: Text('ok'.tr()),
                onPressed: () => Navigator.of(c).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportMenu(BuildContext context, WidgetRef ref) {
    showCustomActionSheet(
      context,
      items: [
        ActionSheetItem(
          label: 'export_excel'.tr(),
          onTap: () => _handleExport(context, ref, 'excel'),
        ),
        ActionSheetItem(
          label: 'export_pdf'.tr(),
          onTap: () => _handleExport(context, ref, 'pdf'),
        ),
        ActionSheetItem(
          label: 'print'.tr(),
          onTap: () => _handleExport(context, ref, 'print'),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.exclamationmark_circle,
                size: 64, color: CupertinoColors.destructiveRed),
            const SizedBox(height: 16),
            Text(error, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildReportContent(BuildContext context, ReportState state) {
    final sections = <Widget>[];

    if (state.currentFilter != null &&
        (state.currentFilter!.startDate != null ||
            state.currentFilter!.endDate != null)) {
      final f = state.currentFilter!;
      final startStr = f.startDate != null
          ? '${f.startDate!.day}/${f.startDate!.month}/${f.startDate!.year}'
          : '...';
      final endStr = f.endDate != null
          ? '${f.endDate!.day}/${f.endDate!.month}/${f.endDate!.year}'
          : '...';
      sections.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: context.primaryColor.withValues(alpha: 0.1),
          child: Row(
            children: [
              Icon(CupertinoIcons.calendar,
                  size: 16, color: context.primaryColor),
              const SizedBox(width: 8),
              Text('Period: $startStr - $endStr',
                  style: AppTypography.poppins(
                      fontSize: 13, color: context.primaryColor)),
            ],
          ),
        ),
      );
    }

    if (state.valuationReport != null && _selectedCategoryId != null) {
      sections.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: FilterChip(
            label: 'Category: ${_selectedCategoryName ?? ''}',
            onDeleted: () => setState(() => _selectedCategoryId = null),
          ),
        ),
      );
    }

    sections.add(_buildSummarySection(context, state));
    sections.add(Expanded(child: _buildTable(context, state)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections,
    );
  }

  Widget _buildSummarySection(BuildContext context, ReportState state) {
    if (state.inventoryReport != null) {
      final data = state.inventoryReport!;
      final totalValue = data.fold(0.0, (sum, r) => sum + r.stockValue);
      final totalRevenue = data.fold(0.0, (sum, r) => sum + r.potentialRevenue);
      final totalQty = data.fold(0.0, (sum, r) => sum + r.quantity);
      return _summaryCard([
        _summaryItem(context, 'Total Products', '${data.length}',
            CupertinoIcons.square_list_fill),
        _summaryItem(context, 'Total Qty', totalQty.toIntSafe.toString(),
            CupertinoIcons.number),
        _summaryItem(context, 'Stock Value', totalValue.formattedCurrency,
            CupertinoIcons.money_dollar),
        _summaryItem(context, 'Potential Revenue',
            totalRevenue.formattedCurrency, CupertinoIcons.chart_bar),
      ]);
    }

    if (state.valuationReport != null) {
      final data = _valuationRows(state);
      final totalVal = data.fold(0.0, (s, r) => s + r.totalValue);
      return _summaryCard([
        _summaryItem(context, 'Items', '${data.length}',
            CupertinoIcons.square_list_fill),
        _summaryItem(context, 'Total Value', totalVal.formattedCurrency,
            CupertinoIcons.money_dollar),
      ]);
    }

    if (state.stockMovementReport != null) {
      final data = state.stockMovementReport!;
      final totalIn = data
          .where((r) => r.type == 'stock_in' || r.type == 'transfer_in')
          .fold(0.0, (s, r) => s + r.quantity);
      final totalOut = data
          .where((r) => r.type == 'stock_out' || r.type == 'transfer_out')
          .fold(0.0, (s, r) => s + r.quantity.abs());
      return _summaryCard([
        _summaryItem(context, 'Transactions', '${data.length}',
            CupertinoIcons.arrow_left_right),
        _summaryItem(context, 'Stock In', totalIn.toIntSafe.toString(),
            CupertinoIcons.arrow_down),
        _summaryItem(context, 'Stock Out', totalOut.toIntSafe.toString(),
            CupertinoIcons.arrow_up),
        _summaryItem(
            context,
            'Total Value',
            data.fold(0.0, (s, r) => s + r.totalPrice).formattedCurrency,
            CupertinoIcons.money_dollar),
      ]);
    }

    if (state.salesReport != null) {
      final data = state.salesReport!;
      final totalAmount = data.fold(0.0, (s, r) => s + r.totalAmount);
      final totalPaid = data.fold(0.0, (s, r) => s + r.paidAmount);
      final totalDue = data.fold(0.0, (s, r) => s + r.dueAmount);
      return _summaryCard([
        _summaryItem(
            context, 'Sales', '${data.length}', CupertinoIcons.cart_fill),
        _summaryItem(context, 'Total', totalAmount.formattedCurrency,
            CupertinoIcons.money_dollar),
        _summaryItem(context, 'Paid', totalPaid.formattedCurrency,
            CupertinoIcons.checkmark_circle),
        _summaryItem(
            context, 'Due', totalDue.formattedCurrency, CupertinoIcons.clock),
      ]);
    }

    if (state.purchaseReport != null) {
      final data = state.purchaseReport!;
      final total = data.fold(0.0, (s, r) => s + r.totalAmount);
      return _summaryCard([
        _summaryItem(context, 'Purchases', '${data.length}',
            CupertinoIcons.doc_plaintext),
        _summaryItem(context, 'Total', total.formattedCurrency,
            CupertinoIcons.money_dollar),
      ]);
    }

    if (state.supplierReport != null) {
      final data = state.supplierReport!;
      final totalPurchases = data.fold(0, (s, r) => s + r.totalPurchases);
      final totalAmount = data.fold(0.0, (s, r) => s + r.totalAmount);
      return _summaryCard([
        _summaryItem(context, 'Suppliers', '${data.length}',
            CupertinoIcons.building_2_fill),
        _summaryItem(
            context, 'Orders', '$totalPurchases', CupertinoIcons.doc_plaintext),
        _summaryItem(context, 'Total Spent', totalAmount.formattedCurrency,
            CupertinoIcons.money_dollar),
      ]);
    }

    if (state.customerReport != null) {
      final data = state.customerReport!;
      final totalSales = data.fold(0, (s, r) => s + r.totalSales);
      final totalAmount = data.fold(0.0, (s, r) => s + r.totalAmount);
      final totalDue = data.fold(0.0, (s, r) => s + r.totalDue);
      return _summaryCard([
        _summaryItem(context, 'Customers', '${data.length}',
            CupertinoIcons.person_2_fill),
        _summaryItem(
            context, 'Orders', '$totalSales', CupertinoIcons.cart_fill),
        _summaryItem(context, 'Revenue', totalAmount.formattedCurrency,
            CupertinoIcons.money_dollar),
        _summaryItem(
            context, 'Due', totalDue.formattedCurrency, CupertinoIcons.clock),
      ]);
    }

    if (state.financialSummary != null) {
      final f = state.financialSummary!;
      return _summaryCard([
        _summaryItem(context, 'Revenue', f.totalRevenue.formattedCurrency,
            CupertinoIcons.chart_bar),
        _summaryItem(context, 'Cost', f.totalCost.formattedCurrency,
            CupertinoIcons.money_dollar),
        _summaryItem(context, 'Gross Profit', f.grossProfit.formattedCurrency,
            CupertinoIcons.chart_bar_fill),
        _summaryItem(context, 'Net Profit', f.netProfit.formattedCurrency,
            CupertinoIcons.chart_pie_fill),
        _summaryItem(context, 'Margin', '${f.netMargin.toStringAsFixed(1)}%',
            CupertinoIcons.percent),
        _summaryItem(
            context,
            'Receivables',
            f.outstandingReceivables.formattedCurrency,
            CupertinoIcons.doc_plaintext),
        _summaryItem(
            context,
            'Payables',
            f.outstandingPayables.formattedCurrency,
            CupertinoIcons.money_dollar),
      ]);
    }

    if (state.auditReport != null) {
      return _summaryCard([
        _summaryItem(context, 'Entries', '${state.auditReport!.length}',
            CupertinoIcons.shield_fill),
      ]);
    }

    return const SizedBox.shrink();
  }

  Widget _summaryCard(List<Widget> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      child: Wrap(spacing: 8, runSpacing: 8, children: items),
    );
  }

  Widget _summaryItem(
      BuildContext context, String label, String value, IconData icon) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: context.isDarkTheme
                ? const Color(0xFF334155)
                : const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTypography.poppins(
                        fontSize: 11, color: context.secondaryTextColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(value,
                    style: AppTypography.poppins(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context, ReportState state) {
    if (state.inventoryReport != null) {
      return _dataTable(
        context: context,
        columns: [
          'Product',
          'SKU',
          'Category',
          'Qty',
          'Cost Price',
          'Sell Price',
          'Stock Value',
          'Revenue'
        ],
        rows: state.inventoryReport!
            .map((r) => [
                  r.productName,
                  r.sku,
                  r.categoryName ?? '-',
                  '${r.quantity.toIntSafe}',
                  r.costPrice.formattedCurrency,
                  r.sellingPrice.formattedCurrency,
                  r.stockValue.formattedCurrency,
                  r.potentialRevenue.formattedCurrency,
                ])
            .toList(),
      );
    }
    if (state.valuationReport != null) {
      return _dataTable(
        context: context,
        columns: [
          'Product',
          'SKU',
          'Category',
          'Qty',
          'Unit Cost',
          'Total Value'
        ],
        rows: _valuationRows(state)
            .map((r) => [
                  r.productName ?? '-',
                  r.sku ?? '-',
                  r.categoryName ?? '-',
                  '${r.quantity.toIntSafe}',
                  r.unitCost.formattedCurrency,
                  r.totalValue.formattedCurrency,
                ])
            .toList(),
      );
    }
    if (state.stockMovementReport != null) {
      return _dataTable(
        context: context,
        columns: [
          'Date',
          'Product',
          'SKU',
          'Type',
          'Qty',
          'Unit Price',
          'Total'
        ],
        rows: state.stockMovementReport!
            .map((r) => [
                  r.date != null
                      ? '${r.date!.day}/${r.date!.month}/${r.date!.year}'
                      : '-',
                  r.productName,
                  r.sku,
                  r.type,
                  r.quantity.toStringAsFixed(2),
                  r.unitPrice.formattedCurrency,
                  r.totalPrice.formattedCurrency,
                ])
            .toList(),
      );
    }
    if (state.salesReport != null) {
      return _dataTable(
        context: context,
        columns: [
          'Invoice',
          'Date',
          'Customer',
          'Subtotal',
          'Tax',
          'Discount',
          'Total',
          'Paid',
          'Due',
          'Status'
        ],
        rows: state.salesReport!
            .map((r) => [
                  r.invoiceNumber,
                  r.saleDate != null
                      ? '${r.saleDate!.day}/${r.saleDate!.month}/${r.saleDate!.year}'
                      : '-',
                  r.customerName ?? '-',
                  r.subtotal.formattedCurrency,
                  r.taxAmount.formattedCurrency,
                  r.discountAmount.formattedCurrency,
                  r.totalAmount.formattedCurrency,
                  r.paidAmount.formattedCurrency,
                  r.dueAmount.formattedCurrency,
                  r.status,
                ])
            .toList(),
      );
    }
    if (state.purchaseReport != null) {
      return _dataTable(
        context: context,
        columns: [
          'Order No',
          'Date',
          'Supplier',
          'Subtotal',
          'Tax',
          'Total',
          'Status'
        ],
        rows: state.purchaseReport!
            .map((r) => [
                  r.orderNumber,
                  r.orderDate != null
                      ? '${r.orderDate!.day}/${r.orderDate!.month}/${r.orderDate!.year}'
                      : '-',
                  r.supplierName ?? '-',
                  r.subtotal.formattedCurrency,
                  r.taxAmount.formattedCurrency,
                  r.totalAmount.formattedCurrency,
                  r.status,
                ])
            .toList(),
      );
    }
    if (state.supplierReport != null) {
      return _dataTable(
        context: context,
        columns: [
          'Company',
          'Contact',
          'Phone',
          'Orders',
          'Total Amount',
          'Avg Order',
          'Items'
        ],
        rows: state.supplierReport!
            .map((r) => [
                  r.companyName,
                  r.contactPerson ?? '-',
                  r.phone ?? '-',
                  '${r.totalPurchases}',
                  r.totalAmount.formattedCurrency,
                  r.averageOrderValue.formattedCurrency,
                  '${r.totalItems}',
                ])
            .toList(),
      );
    }
    if (state.customerReport != null) {
      return _dataTable(
        context: context,
        columns: [
          'Name',
          'Phone',
          'Email',
          'Orders',
          'Total',
          'Avg Order',
          'Paid',
          'Due'
        ],
        rows: state.customerReport!
            .map((r) => [
                  r.name,
                  r.phone ?? '-',
                  r.email ?? '-',
                  '${r.totalSales}',
                  r.totalAmount.formattedCurrency,
                  r.averageOrderValue.formattedCurrency,
                  r.totalPaid.formattedCurrency,
                  r.totalDue.formattedCurrency,
                ])
            .toList(),
      );
    }
    if (state.auditReport != null) {
      return _dataTable(
        context: context,
        columns: ['Date', 'User', 'Action', 'Entity', 'Details'],
        rows: state.auditReport!
            .map((r) => [
                  r.performedAt != null
                      ? '${r.performedAt!.day}/${r.performedAt!.month}/${r.performedAt!.year}'
                      : '-',
                  r.userName ?? '-',
                  r.action,
                  r.entityType,
                  r.details ?? '-',
                ])
            .toList(),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.doc_text_search,
                size: 64,
                color: context.secondaryTextColor.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('no_data_available'.tr(),
                style: AppTypography.poppins(
                    fontSize: 16, color: context.secondaryTextColor)),
            const SizedBox(height: 8),
            Text('no_records_for_report'.tr(),
                style: AppTypography.poppins(
                    fontSize: 13,
                    color: context.secondaryTextColor.withValues(alpha: 0.7)),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _dataTable(
      {required BuildContext context,
      required List<String> columns,
      required List<List<String>> rows}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: context.primaryColor.withValues(alpha: 0.1),
              child: Row(
                children: columns
                    .map((c) => Container(
                          width: 120,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(c,
                              style: AppTypography.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: context.primaryTextColor)),
                        ))
                    .toList(),
              ),
            ),
            ...rows.map((row) => Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: context.borderColor)),
                  ),
                  child: Row(
                    children: row
                        .map((cell) => Container(
                              width: 120,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(cell,
                                  style: AppTypography.poppins(
                                      fontSize: 12,
                                      color: context.primaryTextColor)),
                            ))
                        .toList(),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _handleExport(
      BuildContext context, WidgetRef ref, String format) async {
    final state = ref.read(reportProvider);

    if (!state.hasData) {
      _showMessage(context, 'No data to export');
      return;
    }

    try {
      if (format == 'print') {
        await _printReport(context, state, widget.config.title);
        if (mounted) _showMessage(context, 'Print job sent');
        return;
      }

      String? filePath;

      if (format == 'excel') {
        filePath = await _exportExcel(context, state, widget.config.title);
      } else if (format == 'pdf') {
        filePath = await _exportPdf(context, state, widget.config.title);
      }

      if (filePath != null) {
        _showExportSuccess(context, format, filePath);
      }
    } catch (e) {
      _showMessage(context, 'Export failed: $e');
    }
  }

  Future<void> _printReport(
      BuildContext context, ReportState state, String title) async {
    final pdf = PdfExporter();
    final (data, columns) = _extractFlatData(state);
    if (data.isEmpty) return;
    final settings = ref.read(settingsProvider);
    await pdf.printDocument(title, columns, data,
        dateFormat: settings.settings.dateFormat,
        timeFormat: settings.settings.timeFormat);
  }

  void _showMessage(BuildContext ctx, String msg) {
    showCustomModal(
      context: ctx,
      builder: (c) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.info_circle_fill,
                size: 48, color: context.primaryColor),
            const SizedBox(height: 16),
            Text('information'.tr(),
                style: AppTypography.poppins(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(msg,
                style: AppTypography.poppins(
                    fontSize: 14, color: context.secondaryTextColor),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                child: Text('ok'.tr()),
                onPressed: () => Navigator.of(c).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportSuccess(BuildContext ctx, String format, String filePath) {
    showCustomModal(
      context: ctx,
      builder: (c) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.checkmark_circle_fill,
                size: 48, color: CupertinoColors.systemGreen),
            const SizedBox(height: 16),
            Text('export_successful'.tr(),
                style: AppTypography.poppins(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('$format exported: $filePath',
                style: AppTypography.poppins(
                    fontSize: 14, color: context.secondaryTextColor),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: CustomPointer(
                    child: CupertinoButton.filled(
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.share, size: 20),
                          const SizedBox(width: 8),
                          Text('share'.tr()),
                        ],
                      ),
                      onPressed: () {
                        Navigator.of(c).pop();
                        SharePlus.instance
                            .share(ShareParams(files: [XFile(filePath)]));
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomPointer(
                    child: CupertinoButton.filled(
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.checkmark, size: 20),
                          const SizedBox(width: 8),
                          Text('ok'.tr()),
                        ],
                      ),
                      onPressed: () => Navigator.of(c).pop(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _exportExcel(
      BuildContext context, ReportState state, String title) async {
    final excel = ExcelExporter();
    final (data, columns) = _extractFlatData(state);
    if (data.isEmpty) return null;
    final settings = ref.read(settingsProvider);

    final tmpPath = await excel.exportReport(title, data, columns,
        dateFormat: settings.settings.dateFormat,
        timeFormat: settings.settings.timeFormat,
        startDate: state.currentFilter?.startDate,
        endDate: state.currentFilter?.endDate);
    final tmpFile = File(tmpPath);
    final bytes = await tmpFile.readAsBytes();

    final result = await FilePicker.saveFile(
      dialogTitle: 'Save Excel Report',
      fileName: p.basename(tmpPath),
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      bytes: bytes,
    );
    if (result == null) return null;
    tmpFile.delete().ignore();
    return result;
  }

  Future<String?> _exportPdf(
      BuildContext context, ReportState state, String title) async {
    final pdf = PdfExporter();
    final (data, columns) = _extractFlatData(state);
    if (data.isEmpty) return null;
    final settings = ref.read(settingsProvider);

    final bytes = await pdf.generatePdfBytes(title, columns, data,
        dateFormat: settings.settings.dateFormat,
        timeFormat: settings.settings.timeFormat);

    final result = await FilePicker.saveFile(
      dialogTitle: 'Save PDF Report',
      fileName:
          '${title.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_')}.pdf',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      bytes: bytes,
    );
    if (result == null) return null;
    return result;
  }

  (List<Map<String, dynamic>> data, List<String> columns) _extractFlatData(
      ReportState state) {
    if (state.inventoryReport != null) {
      final list = state.inventoryReport!;
      return (
        list.map((r) => r.toJson()).toList(),
        [
          'productName',
          'sku',
          'categoryName',
          'quantity',
          'costPrice',
          'sellingPrice',
          'stockValue',
          'potentialRevenue'
        ]
      );
    }
    if (state.valuationReport != null) {
      final list = _valuationRows(state);
      return (
        list.map((r) => r.toJson()).toList(),
        [
          'productName',
          'sku',
          'categoryName',
          'quantity',
          'unitCost',
          'totalValue'
        ]
      );
    }
    if (state.stockMovementReport != null) {
      final list = state.stockMovementReport!;
      return (
        list.map((r) => r.toJson()).toList(),
        [
          'date',
          'productName',
          'sku',
          'type',
          'quantity',
          'unitPrice',
          'totalPrice',
          'balanceAfter',
          'reference'
        ]
      );
    }
    if (state.salesReport != null) {
      final list = state.salesReport!;
      return (
        list.map((r) => r.toJson()).toList(),
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
          'status'
        ]
      );
    }
    if (state.purchaseReport != null) {
      final list = state.purchaseReport!;
      return (
        list.map((r) => r.toJson()).toList(),
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
          'status'
        ]
      );
    }
    if (state.supplierReport != null) {
      final list = state.supplierReport!;
      return (
        list.map((r) => r.toJson()).toList(),
        [
          'companyName',
          'contactPerson',
          'phone',
          'email',
          'totalPurchases',
          'totalAmount',
          'averageOrderValue',
          'totalItems',
          'status'
        ]
      );
    }
    if (state.customerReport != null) {
      final list = state.customerReport!;
      return (
        list.map((r) => r.toJson()).toList(),
        [
          'name',
          'phone',
          'email',
          'totalSales',
          'totalAmount',
          'averageOrderValue',
          'totalPaid',
          'totalDue',
          'status'
        ]
      );
    }
    if (state.auditReport != null) {
      final list = state.auditReport!;
      return (
        list.map((r) => r.toJson()).toList(),
        [
          'performedAt',
          'action',
          'entityType',
          'entityId',
          'details'
        ]
      );
    }
    return ([], []);
  }
}
