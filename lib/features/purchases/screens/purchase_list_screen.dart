// ignore_for_file: use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:drift/drift.dart' as d;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahibz_inventory/core/extensions.dart';
import 'package:sahibz_inventory/database/database.dart';
import 'package:sahibz_inventory/features/purchases/models/purchase_model.dart';
import 'package:sahibz_inventory/features/purchases/providers/purchase_provider.dart';
import 'package:sahibz_inventory/features/purchases/repositories/purchase_repository.dart';
import 'package:sahibz_inventory/shared/app_colors.dart';
import 'package:sahibz_inventory/shared/custom_modal.dart';
import 'package:sahibz_inventory/shared/item_selector.dart';
import 'package:sahibz_inventory/shared/custom_mouse_pointer.dart';
import 'package:sahibz_inventory/shared/widgets/custom_action_sheet.dart';
import 'package:sahibz_inventory/shared/widgets/delete_confirmation_dialog.dart';
import 'package:sahibz_inventory/shared/widgets/filter_chip.dart';
import 'package:sahibz_inventory/shared/widgets/list_screen_template.dart';
import 'package:sahibz_inventory/themes/app_typography.dart';

class PurchaseListScreen extends ConsumerStatefulWidget {
  final bool showAppBar;

  const PurchaseListScreen({super.key, this.showAppBar = true});

  @override
  ConsumerState<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends ConsumerState<PurchaseListScreen> {
  final _searchController = TextEditingController();
  String? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(purchaseProvider.notifier).fetchAll(refresh: true);
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
    final state = ref.watch(purchaseProvider);

    final filterChips = <Widget>[];
    if (state.hasSearch) {
      filterChips.add(FilterChip(
        label: 'Search: ${state.searchQuery}',
        onDeleted: () {
          _searchController.clear();
          ref.read(purchaseProvider.notifier).search('');
        },
      ));
    }
    if (state.filterStatus != null) {
      filterChips.add(FilterChip(
        label: 'Status: ${state.filterStatus}',
        onDeleted: () {
          _selectedStatus = null;
          ref.read(purchaseProvider.notifier).applyFilters(status: null);
        },
      ));
    }
    if (state.filterStartDate != null) {
      filterChips.add(FilterChip(
        label: 'From: ${state.filterStartDate!.formattedDate}',
        onDeleted: () {
          _startDate = null;
          _endDate = null;
          ref.read(purchaseProvider.notifier).applyFilters(startDate: null, endDate: null);
        },
      ));
    }

    return ListScreenTemplate(
      showAppBar: widget.showAppBar,
      title: 'Purchase Orders',
      navTrailing: CustomPointer(child: GestureDetector(
        onTap: () => _showFilterDialog(context, state),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(CupertinoIcons.slider_horizontal_3),
        ),
      )),
      searchController: _searchController,
      searchPlaceholder: 'Search by order number or supplier...',
      hasSearch: state.hasSearch,
      onSearchChanged: (value) => ref.read(purchaseProvider.notifier).search(value),
      onClearSearch: () => ref.read(purchaseProvider.notifier).search(''),
      filterChips: filterChips.isNotEmpty ? filterChips : null,
      isLoading: state.isLoading && state.purchases.isEmpty,
      hasError: state.error != null && state.purchases.isEmpty,
      errorMessage: state.error,
      onRetry: () => ref.read(purchaseProvider.notifier).fetchAll(refresh: true),
      isEmpty: state.purchases.isEmpty,
      emptyIcon: 'cart',
      emptyMessage: 'No Purchase Orders\nCreate your first purchase order to get started',
      emptyActionLabel: 'New Purchase Order',
      onEmptyAction: () => _navigateToForm(context),
      hasMore: state.hasMore,
      onLoadMore: () => ref.read(purchaseProvider.notifier).loadMore(),
      totalCount: state.totalCount,
      countLabel: 'purchase orders',
      contentBuilder: (context, scrollController) {
        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: state.purchases.length + (state.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= state.purchases.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CupertinoActivityIndicator(),
                ),
              );
            }
            return _buildPurchaseCard(context, state.purchases[index]);
          },
        );
      },
      fab: CustomPointer(child: GestureDetector(
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
              Text('New Purchase Order', style: AppTypography.poppins(color: CupertinoColors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      )),
    );
  }


  Widget _buildPurchaseCard(BuildContext context, PurchaseModel purchase) {
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
      child: CustomPointer(child: GestureDetector(
        onTap: () => _navigateToForm(context, purchase: purchase),
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
                          purchase.orderNumber,
                          style: AppTypography.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: textC),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          purchase.supplierName ?? 'Unknown Supplier',
                          style: AppTypography.poppins(fontSize: 12, color: secondaryC),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        purchase.totalAmount.formattedCurrency,
                        style: AppTypography.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: primaryColor),
                      ),
                      const SizedBox(height: 4),
                      _buildStatusBadge(purchase.status),
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
                    purchase.orderDate?.formattedDate ?? '-',
                    style: AppTypography.poppins(fontSize: 12, color: secondaryC),
                  ),

                  const Spacer(),
                  Text(
                    '${purchase.items.length} items',
                    style: AppTypography.poppins(fontSize: 12, color: secondaryC),
                  ),
                  if (purchase.totalReceivedQuantity > 0) ...[
                    const SizedBox(width: 10),
                    Text(
                      'Received ${purchase.totalReceivedQuantity.toStringAsFixed(0)}/${purchase.totalOrderedQuantity.toStringAsFixed(0)}',
                      style: AppTypography.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: purchase.status == 'received'
                              ? CupertinoColors.systemGreen
                              : const Color(0xFF0D9488)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (purchase.canApprove)
                    _buildActionChip(context, 'approve'.tr(), CupertinoIcons.check_mark_circled, primaryColor, () => _approvePurchase(context, purchase)),
                  if (purchase.canReceive)
                    _buildActionChip(context, 'receive'.tr(), CupertinoIcons.cloud_download, CupertinoColors.systemBlue, () => _receivePurchase(context, purchase)),
                  if (purchase.canClose)
                    _buildActionChip(context, 'Close Order', CupertinoIcons.lock_circle, CupertinoColors.systemGrey, () => _closePurchase(context, purchase)),
                  if (purchase.canCancel)
                    _buildActionChip(context, 'cancel'.tr(), CupertinoIcons.clear_circled, CupertinoColors.destructiveRed, () => _cancelPurchase(context, purchase)),
                  CustomPointer(child: GestureDetector(
                    onTap: () => _showMoreMenu(context, purchase),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(CupertinoIcons.ellipsis, size: 20),
                    ),
                  ) ),
                ],
              ),
            ],
          ),
        ),
      ) ),
    );
  }

  Widget _buildActionChip(BuildContext context, String label, IconData icon, Color color, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: CustomPointer(child: GestureDetector(
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
              Text(label, style: AppTypography.poppins(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ) ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = status == 'pending' ? CupertinoColors.systemOrange
        : status == 'approved' ? CupertinoColors.systemBlue
        : status == 'partially_received' ? const Color(0xFF0D9488)
        : status == 'received' ? CupertinoColors.systemGreen
        : status == 'closed' ? CupertinoColors.systemGrey
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
        style: AppTypography.poppins(color: color, fontWeight: FontWeight.w600, fontSize: 10),
      ),
    );
  }



  Future<void> _showFilterDialog(BuildContext context, PurchaseState state) async {
    final result = await showCustomModal<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _PurchaseFilterDialog(
        initialStatus: state.filterStatus,
        initialStartDate: state.filterStartDate,
        initialEndDate: state.filterEndDate,
      ),
    );

    if (result != null) {
      _selectedStatus = result['status'] as String?;
      _startDate = result['startDate'] as DateTime?;
      _endDate = result['endDate'] as DateTime?;
      ref.read(purchaseProvider.notifier).applyFilters(
        status: _selectedStatus,
        startDate: _startDate,
        endDate: _endDate,
      );
    }
  }

  Future<void> _showMoreMenu(BuildContext context, PurchaseModel purchase) async {
    await showCustomActionSheet(
      context,
      title: 'Actions',
      items: [
        ActionSheetItem(
          label: 'edit'.tr(),
          onTap: () => _navigateToForm(context, purchase: purchase),
        ),
        ActionSheetItem(
          label: 'delete'.tr(),
          onTap: () => _showDeleteConfirmation(context, purchase),
          isDestructive: true,
        ),
      ],
    );
  }

  Future<void> _approvePurchase(BuildContext context, PurchaseModel purchase) async {
    final confirmed = await showConfirmDialog(
      context,
      icon: CupertinoIcons.check_mark_circled,
      iconColor: CupertinoColors.activeGreen,
      title: 'Approve Purchase Order',
      message: 'Approve purchase order "${purchase.orderNumber}"?',
      confirmLabel: 'approve'.tr(),
    );

    if (confirmed == true) {
      final error = await ref.read(purchaseProvider.notifier).approve(purchase.id, '');
      if (error != null && mounted) {
        _showError(context, error);
      }
    }
  }

  Future<void> _receivePurchase(BuildContext context, PurchaseModel purchase) async {
    final lines = await showCustomModal<List<ReceiptLine>>(
      context: context,
      builder: (ctx) => _ReceiveDialog(purchase: purchase),
    );

    if (lines == null || lines.isEmpty) return;

    final error = await ref.read(purchaseProvider.notifier).receive(purchase.id, lines: lines);
    if (error != null && mounted) {
      _showError(context, error);
    }
  }

  Future<void> _closePurchase(BuildContext context, PurchaseModel purchase) async {
    final confirmed = await showConfirmDialog(
      context,
      icon: CupertinoIcons.lock_circle,
      iconColor: CupertinoColors.systemGrey,
      title: 'Close Purchase Order',
      message:
          'Close "${purchase.orderNumber}" with the shortfall? Received stock stays in inventory. Nothing more can be received later.',
      confirmLabel: 'Close Order',
    );

    if (confirmed == true) {
      final error = await ref.read(purchaseProvider.notifier).closeOrder(purchase.id);
      if (error != null && mounted) {
        _showError(context, error);
      }
    }
  }

  Future<void> _cancelPurchase(BuildContext context, PurchaseModel purchase) async {
    final confirmed = await showConfirmDialog(
      context,
      icon: CupertinoIcons.xmark_circle,
      iconColor: CupertinoColors.destructiveRed,
      title: 'Cancel Purchase Order',
      message: 'Cancel purchase order "${purchase.orderNumber}"?',
      confirmLabel: 'Yes, Cancel',
      cancelLabel: 'no'.tr(),
    );

    if (confirmed == true) {
      final error = await ref.read(purchaseProvider.notifier).cancel(purchase.id);
      if (error != null && mounted) {
        _showError(context, error);
      }
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context, PurchaseModel purchase) async {
    final confirmed = await showConfirmDialog(
      context,
      icon: CupertinoIcons.delete_solid,
      iconColor: CupertinoColors.destructiveRed,
      title: 'Delete Purchase Order',
      message: 'Are you sure you want to delete "${purchase.orderNumber}"?',
      confirmLabel: 'delete'.tr(),
    );

    if (confirmed == true) {
      final error = await ref.read(purchaseProvider.notifier).delete(purchase.id);
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

  void _navigateToForm(BuildContext context, {PurchaseModel? purchase}) {
    context.push('/purchases/add', extra: purchase);
  }
}

class _PurchaseFilterDialog extends StatefulWidget {
  final String? initialStatus;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const _PurchaseFilterDialog({
    this.initialStatus,
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  State<_PurchaseFilterDialog> createState() => _PurchaseFilterDialogState();
}

class _PurchaseFilterDialogState extends State<_PurchaseFilterDialog> {
  String? _status;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
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
                  'startDate': null,
                  'endDate': null,
                }),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(CupertinoIcons.xmark, size: 22, color: CupertinoColors.destructiveRed),
                ),
              ),
            ),
          ),
          const Text('Filter Purchase Orders'),
          const SizedBox(height: 16),
          _buildDropdownField(context, 'status'.tr(), _status ?? 'All Statuses', [
            'All Statuses',
            'pending',
            'approved',
            'received',
            'cancelled',
          ], (v) {
            setState(() => _status = v == 'All Statuses' ? null : v);
          }),
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

  Widget _buildDropdownField(BuildContext context, String label, String currentValue, List<String> options, ValueChanged<String> onChanged) {
    return CustomPointer(child: GestureDetector(
      onTap: () => _showOptionsPicker(context, label, currentValue, options, onChanged),
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
                  Text(label, style: AppTypography.poppins(fontSize: 11, color: context.secondaryTextColor)),
                  const SizedBox(height: 2),
                  Text(currentValue, style: AppTypography.poppins(color: context.primaryTextColor)),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_down, size: 16, color: context.secondaryTextColor),
          ],
        ),
      ),
    ) );
  }

  Widget _buildDateField(BuildContext context, DateTime? date, String placeholder, ValueChanged<DateTime> onChanged) {
    return CustomPointer(
      child: CupertinoButton(
        onPressed: () => _showDatePickerModal(context, date ?? DateTime.now(), onChanged),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: context.borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(CupertinoIcons.calendar, size: 18, color: context.secondaryTextColor),
              const SizedBox(width: 8),
              Text(date?.formattedDate ?? placeholder, style: AppTypography.poppins(color: context.primaryTextColor)),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptionsPicker(BuildContext context, String label, String currentValue, List<String> options, ValueChanged<String> onChanged) {
    showCustomModal(
      context: context,
      builder: (_) => ItemSelector(
        items: options,
        initialValue: currentValue,
        onSelected: (value) => onChanged(value),
      ),
    );
  }

  void _showDatePickerModal(BuildContext context, DateTime initialDate, ValueChanged<DateTime> onChanged) {
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

class _ReceiveDialog extends ConsumerStatefulWidget {
  final PurchaseModel purchase;

  const _ReceiveDialog({required this.purchase});

  @override
  ConsumerState<_ReceiveDialog> createState() => _ReceiveDialogState();
}

class _ReceiveDialogState extends ConsumerState<_ReceiveDialog> {
  final Map<String, TextEditingController> _qtyControllers = {};
  final Map<String, bool> _isSubstitute = {};
  final Map<String, String?> _substituteProductId = {};
  final Map<String, String?> _substituteProductName = {};
  final Map<String, TextEditingController> _subQtyControllers = {};

  List<Product> _products = [];
  bool _isLoadingProducts = true;

  @override
  void initState() {
    super.initState();
    for (final item in widget.purchase.items) {
      final remaining = item.quantity - item.receivedQuantity;
      _qtyControllers[item.id] =
          TextEditingController(text: remaining > 0 ? _fmt(remaining) : '0');
      _subQtyControllers[item.id] = TextEditingController(text: '0');
      _isSubstitute[item.id] = false;
      _substituteProductId[item.id] = null;
      _substituteProductName[item.id] = null;
    }
    _loadProducts();
  }

  @override
  void dispose() {
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    for (final c in _subQtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  Future<void> _loadProducts() async {
    final db = ref.read(databaseProvider);
    try {
      final products = await (db.select(db.products)
            ..where((p) => p.isDeleted.equals(false) & p.status.equals('active'))
            ..orderBy([(p) => d.OrderingTerm.asc(p.name)]))
          .get();
      if (mounted) {
        setState(() {
          _products = products;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  List<ReceiptLine> _buildLines() {
    final lines = <ReceiptLine>[];
    for (final item in widget.purchase.items) {
      final isSub = _isSubstitute[item.id] == true;
      final qtyAsOrdered =
          double.tryParse(_qtyControllers[item.id]?.text.trim() ?? '') ?? 0.0;
      final subQty =
          double.tryParse(_subQtyControllers[item.id]?.text.trim() ?? '') ??
              0.0;

      if (isSub) {
        final subId = _substituteProductId[item.id];
        if (subId != null && subQty > 0) {
          lines.add(ReceiptLine(
            purchaseItemId: item.id,
            substituteProductId: subId,
            substituteQty: subQty,
          ));
        }
      } else if (qtyAsOrdered > 0) {
        lines.add(ReceiptLine(purchaseItemId: item.id, qtyAsOrdered: qtyAsOrdered));
      }
    }
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Receive: ${widget.purchase.orderNumber}',
              style: AppTypography.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Enter what actually arrived. Partial quantities are allowed.',
              textAlign: TextAlign.center,
              style: AppTypography.poppins(
                  fontSize: 11, color: context.secondaryTextColor)),
          const SizedBox(height: 14),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: widget.purchase.items.map((item) {
                  return _buildItemRow(context, item);
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomPointer(
                  child: CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('cancel'.tr()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton.filled(
                  onPressed: () {
                    final lines = _buildLines();
                    if (lines.isEmpty) return;
                    Navigator.pop(context, lines);
                  },
                  child: Text('receive'.tr()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(BuildContext context, PurchaseItemModel item) {
    final remaining = item.quantity - item.receivedQuantity;
    final isSub = _isSubstitute[item.id] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.productName ?? item.productId,
              style: AppTypography.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          Text(
            'Ordered ${_fmt(item.quantity)} \u2022 Received ${_fmt(item.receivedQuantity)} \u2022 Remaining ${_fmt(remaining)}',
            style: AppTypography.poppins(
                fontSize: 11, color: context.secondaryTextColor),
          ),
          if ((item.notes ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(item.notes!,
                  style: AppTypography.poppins(
                      fontSize: 10, color: CupertinoColors.systemOrange)),
            ),
          const SizedBox(height: 8),
          if (!isSub) ...[
            CupertinoTextField(
              controller: _qtyControllers[item.id],
              placeholder: 'Quantity received',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: context.borderColor),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ] else ...[
            CustomPointer(
              child: GestureDetector(
                onTap: () => _pickSubstituteProduct(item.id),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: context.borderColor),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _substituteProductName[item.id] ??
                              'Select received product',
                          style: AppTypography.poppins(
                              fontSize: 13,
                              color: _substituteProductId[item.id] != null
                                  ? context.primaryTextColor
                                  : context.secondaryTextColor),
                        ),
                      ),
                      Icon(CupertinoIcons.chevron_down,
                          size: 14, color: context.secondaryTextColor),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: _subQtyControllers[item.id],
              placeholder: 'Quantity received',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: context.borderColor),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _isSubstitute[item.id] = !isSub;
                if (_isSubstitute[item.id] == true) {
                  _qtyControllers[item.id]?.text = '0';
                } else {
                  _subQtyControllers[item.id]?.text = '0';
                  _substituteProductId[item.id] = null;
                  _substituteProductName[item.id] = null;
                }
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSub
                      ? CupertinoIcons.check_mark_circled_solid
                      : CupertinoIcons.circle,
                  size: 16,
                  color: isSub
                      ? CupertinoColors.systemOrange
                      : context.secondaryTextColor,
                ),
                const SizedBox(width: 6),
                Text('Different item was sent',
                    style: AppTypography.poppins(
                        fontSize: 11, color: context.secondaryTextColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _pickSubstituteProduct(String itemId) {
    showCustomModal(
      context: context,
      builder: (_) => ItemSelector(
        items: _products.map((p) => p.id).toList(),
        labels: _products.map((p) => '${p.name} (${p.sku})').toList(),
        initialValue: _substituteProductId[itemId],
        onSelected: (value) {
          final product = _products.firstWhere((p) => p.id == value);
          setState(() {
            _substituteProductId[itemId] = product.id;
            _substituteProductName[itemId] = product.name;
          });
        },
      ),
    );
  }
}
