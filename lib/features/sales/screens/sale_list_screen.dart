// ignore_for_file: use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahibz_inventory/core/extensions.dart';
import 'package:sahibz_inventory/features/sales/models/sale_model.dart';
import 'package:sahibz_inventory/features/sales/providers/sale_provider.dart';
import 'package:sahibz_inventory/shared/app_colors.dart';
import 'package:sahibz_inventory/shared/custom_modal.dart';
import 'package:sahibz_inventory/shared/item_selector.dart';
import 'package:sahibz_inventory/shared/custom_mouse_pointer.dart';
import 'package:sahibz_inventory/shared/widgets/custom_action_sheet.dart';
import 'package:sahibz_inventory/shared/widgets/delete_confirmation_dialog.dart';
import 'package:sahibz_inventory/shared/widgets/filter_chip.dart';
import 'package:sahibz_inventory/shared/widgets/list_screen_template.dart';
import 'package:sahibz_inventory/themes/app_typography.dart';

class SaleListScreen extends ConsumerStatefulWidget {
  final bool showAppBar;

  const SaleListScreen({super.key, this.showAppBar = true});

  @override
  ConsumerState<SaleListScreen> createState() => _SaleListScreenState();
}

class _SaleListScreenState extends ConsumerState<SaleListScreen> {
  final _searchController = TextEditingController();
  String? _selectedStatus;
  String? _selectedPaymentStatus;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(saleProvider.notifier).fetchAll(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _textColor(BuildContext c) {
    final isDark = CupertinoTheme.of(c).brightness == Brightness.dark;
    return isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
  }

  Color _secondaryTextColor(BuildContext c) {
    final isDark = CupertinoTheme.of(c).brightness == Brightness.dark;
    return isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  }

  Color _borderColor(BuildContext c) {
    final isDark = CupertinoTheme.of(c).brightness == Brightness.dark;
    return isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  }

  Color _surfaceColor(BuildContext c) {
    final isDark = CupertinoTheme.of(c).brightness == Brightness.dark;
    return isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(saleProvider);

    final filterChips = <Widget>[];
    if (state.hasSearch) {
      filterChips.add(FilterChip(
        label: 'Search: ${state.searchQuery}',
        onDeleted: () {
          _searchController.clear();
          ref.read(saleProvider.notifier).search('');
        },
      ));
    }
    if (state.filterStatus != null) {
      filterChips.add(FilterChip(
        label: 'Status: ${state.filterStatus}',
        onDeleted: () {
          _selectedStatus = null;
          ref.read(saleProvider.notifier).applyFilters(status: null);
        },
      ));
    }
    if (state.filterPaymentStatus != null) {
      filterChips.add(FilterChip(
        label: 'Payment: ${state.filterPaymentStatus}',
        onDeleted: () {
          _selectedPaymentStatus = null;
          ref.read(saleProvider.notifier).applyFilters(paymentStatus: null);
        },
      ));
    }
    if (state.filterStartDate != null) {
      filterChips.add(FilterChip(
        label: 'From: ${state.filterStartDate!.formattedDate}',
        onDeleted: () {
          _startDate = null;
          _endDate = null;
          ref
              .read(saleProvider.notifier)
              .applyFilters(startDate: null, endDate: null);
        },
      ));
    }

    return ListScreenTemplate(
      showAppBar: widget.showAppBar,
      title: 'Sales Invoices',
      navTrailing: CustomPointer(
          child: GestureDetector(
        onTap: () => _showFilterDialog(context, state),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(CupertinoIcons.slider_horizontal_3),
        ),
      )),
      searchController: _searchController,
      searchPlaceholder: 'Search by invoice number or customer...',
      hasSearch: state.hasSearch,
      onSearchChanged: (value) => ref.read(saleProvider.notifier).search(value),
      onClearSearch: () => ref.read(saleProvider.notifier).search(''),
      filterChips: filterChips.isNotEmpty ? filterChips : null,
      isLoading: state.isLoading && state.sales.isEmpty,
      hasError: state.error != null && state.sales.isEmpty,
      errorMessage: state.error,
      onRetry: () => ref.read(saleProvider.notifier).fetchAll(refresh: true),
      isEmpty: state.sales.isEmpty,
      emptyIcon: 'doc',
      emptyMessage:
          'No Sales Invoices\nCreate your first sales invoice to get started',
      emptyActionLabel: 'New Invoice',
      onEmptyAction: () => _navigateToForm(context),
      hasMore: state.hasMore,
      onLoadMore: () => ref.read(saleProvider.notifier).loadMore(),
      totalCount: state.totalCount,
      countLabel: 'invoices',
      contentBuilder: (context, scrollController) {
        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: state.sales.length + (state.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= state.sales.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CupertinoActivityIndicator(),
                ),
              );
            }
            return _buildSaleCard(context, state.sales[index]);
          },
        );
      },
      fab: CustomPointer(
          child: GestureDetector(
        onTap: () => _navigateToForm(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: CupertinoTheme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.add, color: CupertinoColors.white),
              const SizedBox(width: 8),
              Text('New Invoice',
                  style: AppTypography.poppins(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      )),
    );
  }

  Widget _buildSaleCard(BuildContext context, SaleModel sale) {
    final textC = _textColor(context);
    final secondaryC = _secondaryTextColor(context);
    final borderC = _borderColor(context);
    final surfaceC = _surfaceColor(context);
    final primaryColor = CupertinoTheme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: surfaceC,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderC),
      ),
      child: CustomPointer(
          child: GestureDetector(
        onTap: () => _navigateToForm(context, sale: sale),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.invoiceNumber,
                          style: AppTypography.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textC),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sale.customerName ?? 'Walk-in Customer',
                          style: AppTypography.poppins(
                              fontSize: 12, color: secondaryC),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        sale.totalAmount.formattedCurrency,
                        style: AppTypography.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: primaryColor),
                      ),
                      const SizedBox(height: 4),
                      _buildStatusBadge(sale.status),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(CupertinoIcons.calendar, size: 14, color: secondaryC),
                  const SizedBox(width: 4),
                  Text(
                    sale.saleDate?.formattedDate ?? '-',
                    style:
                        AppTypography.poppins(fontSize: 12, color: secondaryC),
                  ),
                  const Spacer(),
                  _buildPaymentStatusBadge(sale.paymentStatus, sale.status),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (sale.status == 'completed') ...[
                    Text(
                      'Paid: ${sale.paidAmount.formattedCurrency}',
                      style: AppTypography.poppins(
                          fontSize: 11, color: CupertinoColors.systemGreen),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Due: ${sale.dueAmount.formattedCurrency}',
                      style: AppTypography.poppins(
                        fontSize: 11,
                        color: sale.dueAmount > 0
                            ? CupertinoColors.destructiveRed
                            : CupertinoColors.systemGreen,
                      ),
                    ),
                  ] else if (sale.status == 'pending')
                    ...[
                      Text(
                      'Payment pending: ${sale.paidAmount.formattedCurrency}',
                      style: AppTypography.poppins(
                          fontSize: 11, color: CupertinoColors.systemYellow),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Due: ${sale.dueAmount.formattedCurrency}',
                      style: AppTypography.poppins(
                        fontSize: 11,
                        color: sale.dueAmount > 0
                            ? CupertinoColors.destructiveRed
                            : CupertinoColors.systemYellow,
                      ),
                    ),
                    ]
                  else ...[
                    Text(
                      'Cancelled',
                      style: AppTypography.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.destructiveRed,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (sale.canComplete)
                    _buildActionChip(
                        context,
                        'complete'.tr(),
                        CupertinoIcons.check_mark_circled,
                        primaryColor,
                        () => _completeSale(context, sale)),
                  if (sale.canCancel)
                    _buildActionChip(
                        context,
                        'cancel'.tr(),
                        CupertinoIcons.clear_circled,
                        CupertinoColors.destructiveRed,
                        () => _cancelSale(context, sale)),
                  if (sale.dueAmount > 0)
                    _buildActionChip(
                        context,
                        'Pay',
                        CupertinoIcons.money_dollar_circle,
                        CupertinoColors.systemGreen,
                        () => _recordPayment(context, sale)),
                  CustomPointer(
                      child: GestureDetector(
                    onTap: () => _showMoreMenu(context, sale),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(CupertinoIcons.ellipsis, size: 20),
                    ),
                  )),
                ],
              ),
            ],
          ),
        ),
      )),
    );
  }

  Widget _buildActionChip(BuildContext context, String label, IconData icon,
      Color color, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: CustomPointer(
          child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: AppTypography.poppins(
                      fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      )),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = status == 'pending'
        ? CupertinoColors.systemOrange
        : status == 'completed'
            ? CupertinoColors.systemGreen
            : CupertinoColors.destructiveRed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTypography.poppins(
            color: color, fontWeight: FontWeight.w600, fontSize: 10),
      ),
    );
  }

  Widget _buildPaymentStatusBadge(String paymentStatus, String saleStatus) {
    if (saleStatus == 'pending') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: CupertinoColors.systemYellow.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Pending Payment',
          style: AppTypography.poppins(
              color: CupertinoColors.systemYellow, fontWeight: FontWeight.w600, fontSize: 9),
        ),
      );
    }
    if (saleStatus == 'cancelled') {
      return const SizedBox.shrink();
    }
    final color = paymentStatus == 'paid'
        ? CupertinoColors.systemGreen
        : paymentStatus == 'partial'
            ? CupertinoColors.systemOrange
            : CupertinoColors.destructiveRed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        paymentStatus.toUpperCase(),
        style: AppTypography.poppins(
            color: color, fontWeight: FontWeight.w600, fontSize: 9),
      ),
    );
  }

  Future<void> _showFilterDialog(BuildContext context, SaleState state) async {
    final result = await showCustomModal<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _SaleFilterDialog(
        initialStatus: state.filterStatus,
        initialPaymentStatus: state.filterPaymentStatus,
        initialStartDate: state.filterStartDate,
        initialEndDate: state.filterEndDate,
      ),
    );

    if (result != null) {
      _selectedStatus = result['status'] as String?;
      _selectedPaymentStatus = result['paymentStatus'] as String?;
      _startDate = result['startDate'] as DateTime?;
      _endDate = result['endDate'] as DateTime?;
      ref.read(saleProvider.notifier).applyFilters(
            status: _selectedStatus,
            paymentStatus: _selectedPaymentStatus,
            startDate: _startDate,
            endDate: _endDate,
          );
    }
  }

  Future<void> _showMoreMenu(BuildContext context, SaleModel sale) async {
    await showCustomActionSheet(
      context,
      title: 'Actions',
      items: [
        ActionSheetItem(
          label: 'edit'.tr(),
          onTap: () => _navigateToForm(context, sale: sale),
        ),
        ActionSheetItem(
          label: 'Print Invoice',
          onTap: () => _printInvoice(context, sale),
        ),
        ActionSheetItem(
          label: 'delete'.tr(),
          onTap: () => _showDeleteConfirmation(context, sale),
          isDestructive: true,
        ),
      ],
    );
  }

  Future<void> _completeSale(BuildContext context, SaleModel sale) async {
    final confirmed = await showConfirmDialog(
      context,
      icon: CupertinoIcons.check_mark_circled,
      iconColor: CupertinoColors.activeGreen,
      title: 'Complete Sale',
      message: 'Mark invoice "${sale.invoiceNumber}" as completed?',
      confirmLabel: 'complete'.tr(),
    );

    if (confirmed == true) {
      final error = await ref.read(saleProvider.notifier).complete(sale.id);
      if (error != null && mounted) {
        _showError(context, error);
      }
    }
  }

  Future<void> _cancelSale(BuildContext context, SaleModel sale) async {
    final confirmed = await showConfirmDialog(
      context,
      icon: CupertinoIcons.xmark_circle,
      iconColor: CupertinoColors.destructiveRed,
      title: 'Cancel Sale',
      message:
          'Cancel invoice "${sale.invoiceNumber}"? This will restore inventory.',
      confirmLabel: 'Yes, Cancel',
      cancelLabel: 'no'.tr(),
    );

    if (confirmed == true) {
      final error = await ref.read(saleProvider.notifier).cancel(sale.id);
      if (error != null && mounted) {
        _showError(context, error);
      }
    }
  }

  Future<void> _recordPayment(BuildContext context, SaleModel sale) async {
    final amountCtrl = TextEditingController();
    final result = await showCustomModal<double>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.money_dollar_circle,
                size: 48, color: CupertinoColors.activeGreen),
            const SizedBox(height: 16),
            const Text('Record Payment'),
            const SizedBox(height: 8),
            Text('Invoice: ${sale.invoiceNumber}'),
            Text('Due Amount: ${sale.dueAmount.formattedCurrency}'),
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: amountCtrl,
              placeholder: 'Payment Amount',
              prefix: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text('${CurrencyFormatter.symbol} '),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: CupertinoColors.systemGrey4),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                    child: CustomPointer(
                        child: CupertinoButton(
                            child: Text('cancel'.tr()),
                            onPressed: () => Navigator.pop(ctx)))),
                const SizedBox(width: 12),
                Expanded(
                  child: CupertinoButton.filled(
                    onPressed: () {
                      final amount =
                          double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                      if (amount > 0) {
                        Navigator.pop(ctx, amount);
                      }
                    },
                    child: const Text('Record Payment'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    amountCtrl.dispose();

    if (result != null && result > 0) {
      final error = await ref.read(saleProvider.notifier).updatePayment(
            id: sale.id,
            paidAmount: result,
          );
      if (error != null && mounted) {
        _showError(context, error);
      }
    }
  }

  Future<void> _printInvoice(BuildContext context, SaleModel sale) async {
    _showError(context, 'Printing invoice ${sale.invoiceNumber}...');
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, SaleModel sale) async {
    final confirmed = await showConfirmDialog(
      context,
      icon: CupertinoIcons.delete_solid,
      iconColor: CupertinoColors.destructiveRed,
      title: 'Delete Invoice',
      message: 'Are you sure you want to delete "${sale.invoiceNumber}"?',
      confirmLabel: 'delete'.tr(),
    );

    if (confirmed == true) {
      final error = await ref.read(saleProvider.notifier).delete(sale.id);
      if (error != null && mounted) {
        _showError(context, error);
      }
    }
  }

  void _showError(BuildContext context, String message) {
    showMessageDialog(
      context,
      icon: CupertinoIcons.exclamationmark_circle,
      iconColor: CupertinoColors.destructiveRed,
      message: message,
    );
  }

  void _navigateToForm(BuildContext context, {SaleModel? sale}) {
    context.push('/sales/add', extra: sale);
  }
}

class _SaleFilterDialog extends StatefulWidget {
  final String? initialStatus;
  final String? initialPaymentStatus;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const _SaleFilterDialog({
    this.initialStatus,
    this.initialPaymentStatus,
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  State<_SaleFilterDialog> createState() => _SaleFilterDialogState();
}

class _SaleFilterDialogState extends State<_SaleFilterDialog> {
  String? _status;
  String? _paymentStatus;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _paymentStatus = widget.initialPaymentStatus;
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: CustomPointer(
              child: GestureDetector(
                onTap: () => Navigator.pop(context, {
                  'status': null,
                  'paymentStatus': null,
                  'startDate': null,
                  'endDate': null,
                }),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(CupertinoIcons.xmark,
                      size: 22, color: CupertinoColors.destructiveRed),
                ),
              ),
            ),
          ),
          const Text('Filter Sales Invoices'),
          const SizedBox(height: 16),
          _buildDropdownField(
              context, 'status'.tr(), _status ?? 'All Statuses', [
            'All Statuses',
            'pending',
            'completed',
            'cancelled',
          ], (v) {
            setState(() => _status = v == 'All Statuses' ? null : v);
          }, [
            'All Statuses',
            'pending'.tr(),
            'completed'.tr(),
            'cancelled'.tr(),
          ]),
          const SizedBox(height: 16),
          _buildDropdownField(context, 'Payment Status',
              _paymentStatus ?? 'All Payment Statuses', [
            'All Payment Statuses',
            'unpaid',
            'partial',
            'paid',
          ], (v) {
            setState(
                () => _paymentStatus = v == 'All Payment Statuses' ? null : v);
          }, [
            'All Payment Statuses',
            'unpaid'.tr(),
            'partial'.tr(),
            'paid'.tr(),
          ]),
          const SizedBox(height: 16),
          _buildDateField(context, _startDate, 'select_start_date'.tr(), (d) {
            setState(() => _startDate = d);
          }),
          const SizedBox(height: 12),
          _buildDateField(context, _endDate, 'select_end_date'.tr(), (d) {
            setState(() => _endDate = d);
          }),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: CustomPointer(
                  child: CupertinoButton(
                    onPressed: () => Navigator.pop(context, {
                      'status': null,
                      'paymentStatus': null,
                      'startDate': null,
                      'endDate': null,
                    }),
                    child: const Text('Clear All'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton.filled(
                  onPressed: () => Navigator.pop(context, {
                    'status': _status,
                    'paymentStatus': _paymentStatus,
                    'startDate': _startDate,
                    'endDate': _endDate,
                  }),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(
      BuildContext context,
      String label,
      String currentValue,
      List<String> values,
      ValueChanged<String> onChanged,
      List<String> displayLabels) {
    return CustomPointer(
        child: GestureDetector(
      onTap: () => _showOptionsPicker(
          context, label, currentValue, values, displayLabels, onChanged),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: context.borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTypography.poppins(
                          fontSize: 11, color: context.secondaryTextColor)),
                  const SizedBox(height: 2),
                  Text(currentValue.replaceAll('_', ' '),
                      style: AppTypography.poppins(
                          color: context.primaryTextColor)),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_down,
                size: 16, color: context.secondaryTextColor),
          ],
        ),
      ),
    ));
  }

  Widget _buildDateField(BuildContext context, DateTime? date,
      String placeholder, ValueChanged<DateTime> onChanged) {
    return CustomPointer(
      child: CupertinoButton(
        onPressed: () =>
            _showDatePickerModal(context, date ?? DateTime.now(), onChanged),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: context.borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(CupertinoIcons.calendar,
                  size: 18, color: context.secondaryTextColor),
              const SizedBox(width: 8),
              Text(date?.formattedDate ?? placeholder,
                  style:
                      AppTypography.poppins(color: context.primaryTextColor)),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptionsPicker(
      BuildContext context,
      String label,
      String currentValue,
      List<String> values,
      List<String> displayLabels,
      ValueChanged<String> onChanged) {
    showCustomModal(
      context: context,
      builder: (_) => ItemSelector(
        items: values,
        labels: displayLabels,
        initialValue: currentValue,
        onSelected: (value) => onChanged(value),
      ),
    );
  }

  void _showDatePickerModal(BuildContext context, DateTime initialDate,
      ValueChanged<DateTime> onChanged) {
    showCustomModal(
      context: context,
      builder: (ctx) {
        DateTime current = initialDate;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: CustomPointer(
                child: CupertinoButton(
                  child: Text('done'.tr()),
                  onPressed: () {
                    onChanged(current);
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ),
            SizedBox(
              height: 200,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initialDate,
                onDateTimeChanged: (d) => current = d,
              ),
            ),
          ],
        );
      },
    );
  }
}
