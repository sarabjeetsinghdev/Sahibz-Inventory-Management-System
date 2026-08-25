import 'package:sahibz_inventory/features/reports/providers/report_provider.dart';
import 'package:sahibz_inventory/features/reports/models/report_models.dart';
import 'package:sahibz_inventory/shared/widgets/list_screen_template.dart';
import 'package:sahibz_inventory/shared/custom_mouse_pointer.dart';
import 'package:sahibz_inventory/themes/app_typography.dart';
import 'package:sahibz_inventory/shared/custom_modal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sahibz_inventory/shared/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/cupertino.dart';

class ReportListScreen extends ConsumerStatefulWidget {
  const ReportListScreen({super.key});

  @override
  ConsumerState<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends ConsumerState<ReportListScreen> {
  ReportFilter? _appliedFilter;
  final _searchController = TextEditingController();

  static const _reportTypes = [
    ReportTypeConfig('Inventory Report', CupertinoIcons.square_list_fill,
        'inventory', 'Current stock levels and values for all products'),
    ReportTypeConfig('Inventory Valuation', CupertinoIcons.building_2_fill,
        'valuation', 'Stock valuation by product'),
    ReportTypeConfig('Stock Movement', CupertinoIcons.arrow_left_right_circle,
        'stock_movement', 'All inventory transactions with details'),
    ReportTypeConfig('Sales Report', CupertinoIcons.cart_fill, 'sales',
        'Sales orders with aggregations'),
    ReportTypeConfig('Purchase Report', CupertinoIcons.doc_plaintext,
        'purchases', 'Purchase orders with aggregations'),
    ReportTypeConfig('Supplier Report', CupertinoIcons.building_2_fill,
        'suppliers', 'Supplier performance and metrics'),
    ReportTypeConfig('Customer Report', CupertinoIcons.person_2_fill,
        'customers', 'Customer activity and analytics'),
    ReportTypeConfig('Financial Summary', CupertinoIcons.chart_bar_fill,
        'financial', 'Profit/loss summary and financial metrics'),
    ReportTypeConfig('Audit Report', CupertinoIcons.shield_fill, 'audit',
        'System audit log entries'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListScreenTemplate(
      showAppBar: true,
      title: 'reports'.tr(),
      navTrailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_appliedFilter != null)
            CustomPointer(
                child: GestureDetector(
              onTap: () {
                setState(() => _appliedFilter = null);
                ref.read(reportProvider.notifier).clearFilter();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(CupertinoIcons.slash_circle,
                    color: context.primaryColor),
              ),
            )),
          CustomPointer(
              child: GestureDetector(
            onTap: () => _showFilterDialog(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(CupertinoIcons.line_horizontal_3_decrease_circle,
                  color: context.primaryColor),
            ),
          )),
        ],
      ),
      searchController: _searchController,
      searchPlaceholder: null,
      hasSearch: false,
      onSearchChanged: (_) {},
      filterChips: _appliedFilter != null
          ? [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: context.primaryColor.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.calendar,
                        size: 16, color: context.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _dateRangeText(_appliedFilter!),
                        style: AppTypography.poppins(
                            fontSize: 13, color: context.primaryColor),
                      ),
                    ),
                    CustomPointer(
                        child: GestureDetector(
                      onTap: () {
                        setState(() => _appliedFilter = null);
                        ref.read(reportProvider.notifier).clearFilter();
                      },
                      child: Icon(CupertinoIcons.xmark,
                          size: 16, color: context.primaryColor),
                    )),
                  ],
                ),
              ),
            ]
          : null,
      isLoading: false,
      hasError: false,
      isEmpty: false,
      emptyIcon: 'tray',
      emptyMessage: 'No reports',
      hasMore: false,
      onLoadMore: () {},
      totalCount: _reportTypes.length,
      countLabel: 'reports'.tr(),
      contentBuilder: (context, scrollController) {
        final width = MediaQuery.of(context).size.width;
        final crossAxisCount =
            width >= 1200 ? 4 : (width >= 800 ? 3 : (width >= 500 ? 2 : 1));
        return CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildReportCard(context, _reportTypes[index]),
                  childCount: _reportTypes.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReportCard(BuildContext context, ReportTypeConfig config) {
    return CustomPointer(
      onTap: () => _generateAndNavigate(config),
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderColor),
          boxShadow: [
            BoxShadow(
              color: context.borderColor.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(config.icon, color: context.primaryColor, size: 24),
              ),
              const SizedBox(height: 12),
              Text(config.title,
                  style: AppTypography.poppins(
                      fontWeight: FontWeight.w600,
                      color: context.primaryTextColor),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(config.description,
                  style: AppTypography.poppins(
                      fontSize: 11, color: context.secondaryTextColor),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateAndNavigate(ReportTypeConfig config) async {
    final notifier = ref.read(reportProvider.notifier);
    notifier.clearData();

    switch (config.key) {
      case 'inventory':
        await notifier.generateInventoryReport(filters: _appliedFilter);
        break;
      case 'valuation':
        await notifier.generateValuationReport();
        break;
      case 'stock_movement':
        await notifier.generateStockMovementReport(filters: _appliedFilter);
        break;
      case 'sales':
        await notifier.generateSalesReport(filters: _appliedFilter);
        break;
      case 'purchases':
        await notifier.generatePurchaseReport(filters: _appliedFilter);
        break;
      case 'suppliers':
        await notifier.generateSupplierReport(filters: _appliedFilter);
        break;
      case 'customers':
        await notifier.generateCustomerReport(filters: _appliedFilter);
        break;
      case 'financial':
        await notifier.generateFinancialSummary(filters: _appliedFilter);
        break;
      case 'audit':
        await notifier.generateAuditReport(filters: _appliedFilter);
        break;
    }

    if (mounted) {
      context.push('/reports/viewer', extra: config);
    }
  }

  String _dateRangeText(ReportFilter filter) {
    final start = filter.startDate != null
        ? '${filter.startDate!.day}/${filter.startDate!.month}/${filter.startDate!.year}'
        : 'Start';
    final end = filter.endDate != null
        ? '${filter.endDate!.day}/${filter.endDate!.month}/${filter.endDate!.year}'
        : 'End';
    return '$start - $end';
  }

  Future<void> _showFilterDialog(BuildContext context) async {
    final result = await showCupertinoDialog<ReportFilter>(
      context: context,
      builder: (ctx) => _ReportFilterDialog(currentFilter: _appliedFilter),
    );

    if (result != null) {
      setState(() => _appliedFilter = result);
      ref.read(reportProvider.notifier).setFilter(result);
    }
  }
}

class ReportTypeConfig {
  final String title;
  final IconData icon;
  final String key;
  final String description;

  const ReportTypeConfig(this.title, this.icon, this.key, this.description);

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'icon': icon,
      'key': key,
      'description': description,
    };
  }
}

class _ReportFilterDialog extends StatefulWidget {
  final ReportFilter? currentFilter;

  const _ReportFilterDialog({this.currentFilter});

  @override
  State<_ReportFilterDialog> createState() => _ReportFilterDialogState();
}

class _ReportFilterDialogState extends State<_ReportFilterDialog> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.currentFilter?.startDate;
    _endDate = widget.currentFilter?.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text('date_range_filter'.tr()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPointer(
              child: GestureDetector(
            onTap: () => _pickDate(context, true),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: context.borderColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.calendar, color: context.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                      _startDate != null
                          ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                          : 'Start Date',
                      style: AppTypography.poppins(
                          color: _startDate != null
                              ? context.primaryTextColor
                              : context.secondaryTextColor)),
                  const Spacer(),
                  Icon(CupertinoIcons.chevron_right,
                      size: 16, color: context.secondaryTextColor),
                ],
              ),
            ),
          )),
          const SizedBox(height: 12),
          CustomPointer(
              child: GestureDetector(
            onTap: () => _pickDate(context, false),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: context.borderColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.calendar, color: context.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                      _endDate != null
                          ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                          : 'End Date',
                      style: AppTypography.poppins(
                          color: _endDate != null
                              ? context.primaryTextColor
                              : context.secondaryTextColor)),
                  const Spacer(),
                  Icon(CupertinoIcons.chevron_right,
                      size: 16, color: context.secondaryTextColor),
                ],
              ),
            ),
          )),
        ],
      ),
      actions: [
        CustomPointer(
          child: CupertinoButton(
            onPressed: () => Navigator.pop(context,
                ReportFilter(startDate: _startDate, endDate: _endDate)),
            child: Text('apply'.tr()),
          ),
        ),
      ],
    );
  }

  void _pickDate(BuildContext context, bool isStart) {
    showCustomModal(
      context: context,
      builder: (ctx) => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomPointer(
                child: CupertinoButton(
                  child: Text('done'.tr()),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: isStart
                  ? (_startDate ?? DateTime.now())
                  : (_endDate ?? DateTime.now()),
              minimumDate: DateTime(2020),
              maximumDate: DateTime.now().add(const Duration(days: 365)),
              onDateTimeChanged: (date) {
                setState(() {
                  if (isStart) {
                    _startDate = date;
                  } else {
                    _endDate = date;
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
