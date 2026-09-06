// ignore_for_file: deprecated_member_use, unused_local_variable

import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sahibz_inventory/core/extensions.dart';
import 'package:sahibz_inventory/features/inventory/models/inventory_model.dart';
import 'package:sahibz_inventory/features/inventory/providers/inventory_provider.dart';
import 'package:sahibz_inventory/features/inventory/screens/inventory_transaction_form.dart';
import 'package:sahibz_inventory/features/settings/providers/settings_provider.dart';
import 'package:sahibz_inventory/shared/app_colors.dart';
import 'package:sahibz_inventory/shared/custom_mouse_pointer.dart';
import 'package:sahibz_inventory/shared/custom_modal.dart';
import 'package:sahibz_inventory/shared/widgets/custom_action_sheet.dart';
import 'package:sahibz_inventory/shared/widgets/delete_confirmation_dialog.dart';
import 'package:sahibz_inventory/shared/widgets/hover_card.dart';
import 'package:sahibz_inventory/shared/widgets/list_screen_template.dart';
import 'package:sahibz_inventory/themes/app_typography.dart';

class InventoryListScreen extends ConsumerStatefulWidget {
  final bool showAppBar;

  const InventoryListScreen({super.key, this.showAppBar = true});

  @override
  ConsumerState<InventoryListScreen> createState() =>
      _InventoryListScreenState();
}

class _InventoryListScreenState extends ConsumerState<InventoryListScreen> {
  final _searchController = TextEditingController();
  String _activeTab = 'stock';

  static const _inventoryTabs = [
    ('stock', 'Stock'),
    ('stock_in', 'Stock In'),
    ('stock_out', 'Stock Out'),
  ];

  bool get _isStockTab => _activeTab == 'stock';

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '-';
    final settings = ref.read(settingsProvider).settings;
    return DateFormat('${settings.dateFormat} ${settings.timeFormat}')
        .format(dt);
  }

  String get _fabLabel {
    switch (_activeTab) {
      case 'stock_in':
        return 'Stock In';
      case 'stock_out':
        return 'Stock Out';
      default:
        return 'New Inventory';
    }
  }

  String? get _fabInitialType => _isStockTab ? null : _activeTab;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inventoryProvider.notifier).fetchCurrentStock(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StockSummaryModel> _getDisplayItems(InventoryState state) {
    return state.stockItems;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryProvider);
    final primaryColor = CupertinoTheme.of(context).primaryColor;

    final items = _getDisplayItems(state);
    final stockCount = items.length;
    final transactionCount = state.transactions.length;
    final totalCount = _isStockTab ? stockCount : transactionCount;

    return ListScreenTemplate(
      showAppBar: widget.showAppBar,
      title: 'inventory'.tr(),
      searchController: _searchController,
      searchPlaceholder: 'Search by product name or SKU...',
      hasSearch: state.hasSearch,
      onSearchChanged: (value) =>
          ref.read(inventoryProvider.notifier).search(value),
      filterChips: [
        _buildInventoryTabs(context, primaryColor),
      ],
      isLoading: state.isLoading && totalCount == 0,
      hasError: state.error != null && totalCount == 0,
      errorMessage: state.error,
      onRetry: () =>
          ref.read(inventoryProvider.notifier).fetchCurrentStock(refresh: true),
      isEmpty: totalCount == 0,
      emptyIcon: 'cube',
      emptyMessage: 'No Inventory Data',
      emptyActionLabel: _fabLabel,
      onEmptyAction: () =>
          _showTransactionForm(context, initialType: _fabInitialType),
      hasMore: state.hasMore,
      onLoadMore: () {
        final notifier = ref.read(inventoryProvider.notifier);
        if (_isStockTab) {
          notifier.loadMoreStock();
        } else {
          notifier.loadMoreTransactions();
        }
      },
      totalCount: totalCount,
      countLabel: _isStockTab ? 'Items: ' : 'Transactions: ',
      contentBuilder: (context, scrollController) {
        if (_isStockTab) {
          return _buildStockList(
              context, state, items, primaryColor, scrollController);
        } else {
          return _buildTransactionList(
              context, state, primaryColor, scrollController);
        }
      },
      fab: CustomPointer(
          child: GestureDetector(
        onTap: () =>
            _showTransactionForm(context, initialType: _fabInitialType),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0x00000000).withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.add, color: CupertinoColors.white),
              const SizedBox(width: 8),
              Text(_fabLabel,
                  style: AppTypography.poppins(color: CupertinoColors.white)),
            ],
          ),
        ),
      )),
    );
  }

  static const _inventoryTabIcons = {
    'stock': CupertinoIcons.square_grid_2x2_fill,
    'stock_in': CupertinoIcons.add_circled,
    'stock_out': CupertinoIcons.minus_circled,
  };

  Widget _buildInventoryTabs(BuildContext context, Color primaryColor) {
    final isDark = context.isDarkTheme;
    final chipColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < _inventoryTabs.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _buildInventoryTab(context, _inventoryTabs[i].$2,
                  _inventoryTabs[i].$1, chipColor, primaryColor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryTab(BuildContext context, String label, String value,
      Color chipColor, Color primaryColor) {
    final isSelected = _activeTab == value;
    final icon = _inventoryTabIcons[value] ?? CupertinoIcons.circle;
    return CustomPointer(
        child: GestureDetector(
      onTap: () {
        if (isSelected) return;
        setState(() => _activeTab = value);
        final notifier = ref.read(inventoryProvider.notifier);
        if (value == 'stock') {
          notifier.fetchCurrentStock(refresh: true);
        } else {
          notifier.setTransactionTypeFilter(value);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : context.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? primaryColor : chipColor, width: 1.5),
          // boxShadow: isSelected
          //     ? [
          //         BoxShadow(
          //           color: primaryColor.withValues(alpha: 0.35),
          //           blurRadius: 8,
          //           offset: const Offset(0, 3),
          //         ),
          //       ]
          //     : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? CupertinoColors.white
                  : context.secondaryTextColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? CupertinoColors.white
                    : context.primaryTextColor,
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildStockList(
      BuildContext context,
      InventoryState state,
      List<StockSummaryModel> items,
      Color primaryColor,
      ScrollController scrollController) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          return const Center(
            child: Padding(
                padding: EdgeInsets.all(16),
                child: CupertinoActivityIndicator()),
          );
        }
        return _buildStockItemCard(context, items[index], primaryColor);
      },
    );
  }

  Widget _buildStockItemCard(
      BuildContext context, StockSummaryModel item, Color primaryColor) {
    final isLow = item.isLowStock;
    final isOut = item.isOutOfStock;

    final Color cardColor;
    final Color iconBgColor;
    final Color statusColor;

    if (isOut) {
      cardColor = CupertinoColors.destructiveRed
          .withValues(alpha: context.isDarkTheme ? 0.12 : 0.08);
      iconBgColor = CupertinoColors.destructiveRed
          .withValues(alpha: context.isDarkTheme ? 0.2 : 0.15);
      statusColor = CupertinoColors.destructiveRed;
    } else if (isLow) {
      cardColor = CupertinoTheme.of(context)
          .primaryColor
          .withValues(alpha: context.isDarkTheme ? 0.12 : 0.08);
      iconBgColor = CupertinoTheme.of(context)
          .primaryColor
          .withValues(alpha: context.isDarkTheme ? 0.12 : 0.08);
      statusColor = CupertinoTheme.of(context).primaryColor;
    } else {
      cardColor = context.surfaceColor;
      iconBgColor = CupertinoTheme.of(context)
          .primaryColor
          .withValues(alpha: context.isDarkTheme ? 0.2 : 0.15);
      statusColor = CupertinoTheme.of(context).primaryColor;
    }
    final statusText = isOut
        ? 'Out of Stock'
        : isLow
            ? 'Low Stock'
            : 'In Stock';

    return HoverCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      borderRadius: 12,
      color: cardColor,
      hoverColor: statusColor.withValues(alpha: 0.14),
      child: CustomPointer(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showStockActions(context, item),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      CupertinoIcons.square_grid_2x2_fill,
                      size: 22,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: AppTypography.poppins(
                            fontWeight: FontWeight.w600,
                            color: context.primaryTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (item.productSku != null)
                              Text(
                                item.productSku!,
                                style: AppTypography.poppins(
                                  color: context.secondaryTextColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            if (item.productSku != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                  width: 1,
                                  height: 10,
                                  color: context.borderColor),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              statusText,
                              style: AppTypography.poppins(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          item.totalQuantity.toStringAsFixed(0),
                          style: AppTypography.poppins(
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                        if (item.reorderLevel > 0)
                          Text(
                            'min: ${item.reorderLevel.toStringAsFixed(0)}',
                            style: AppTypography.poppins(
                              color: context.secondaryTextColor,
                              fontSize: 9,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildMetaItem('Cost', item.costPrice.formattedCurrency,
                        context.primaryTextColor),
                    _buildMetaDivider(),
                    _buildMetaItem('Value', item.stockValue.formattedCurrency,
                        statusColor),
                    _buildMetaDivider(),
                    _buildMetaItem(
                        'Updated',
                        item.lastUpdated != null
                            ? _formatDateTime(item.lastUpdated)
                            : '-',
                        context.primaryTextColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaItem(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTypography.poppins(
                  color: context.secondaryTextColor, fontSize: 9)),
          const SizedBox(height: 2),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: valueColor)),
        ],
      ),
    );
  }

  Widget _buildMetaDivider() {
    return Container(
        width: 1,
        height: 26,
        color: context.borderColor,
        margin: const EdgeInsets.symmetric(horizontal: 8));
  }

  Future<void> _showStockActions(
      BuildContext context, StockSummaryModel item) async {
    await showCustomActionSheet(
      context,
      title: item.productName,
      items: [
        ActionSheetItem(
          label: 'edit'.tr(),
          icon: CupertinoIcons.pencil,
          onTap: () => _editStockQuantity(context, item),
        ),
        ActionSheetItem(
          label: 'delete'.tr(),
          icon: CupertinoIcons.delete,
          onTap: () => _deleteStock(context, item),
          isDestructive: true,
        ),
      ],
    );
  }

  Future<void> _editStockQuantity(
      BuildContext context, StockSummaryModel item) async {
    final qtyCtrl = TextEditingController(
        text: item.totalQuantity.toStringAsFixed(
            item.totalQuantity == item.totalQuantity.roundToDouble() ? 0 : 2));
    final reasonCtrl = TextEditingController();
    final result = await showCustomModal<bool>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Edit Stock',
                style: AppTypography.poppins(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(item.productName,
                style: AppTypography.poppins(
                    fontSize: 13, color: context.secondaryTextColor)),
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: qtyCtrl,
              placeholder: 'New quantity',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              padding: const EdgeInsets.all(12),
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: reasonCtrl,
              placeholder: 'Reason (optional)',
              padding: const EdgeInsets.all(12),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text('cancel'.tr()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CupertinoButton.filled(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text('save'.tr()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    final qtyText = qtyCtrl.text.trim();
    final reasonText = reasonCtrl.text.trim();
    qtyCtrl.dispose();
    reasonCtrl.dispose();
    if (result != true || !mounted) return;

    final newQty = double.tryParse(qtyText);
    if (newQty == null || newQty < 0) {
      _showListError('Please enter a valid quantity (0 or more).');
      return;
    }
    if (newQty == item.totalQuantity) {
      _showListError('No change. Quantity is already '
          '${item.totalQuantity.toStringAsFixed(0)} units.');
      return;
    }
    final error = await ref.read(inventoryProvider.notifier).adjustStock(
          productId: item.productId,
          newQuantity: newQty,
          reason: reasonText.isEmpty ? 'Manual edit' : reasonText,
        );
    if (!mounted) return;
    if (error != null) {
      _showListError(error);
    } else {
      ref.read(inventoryProvider.notifier).fetchCurrentStock(refresh: true);
    }
  }

  Future<void> _deleteStock(
      BuildContext context, StockSummaryModel item) async {
    final confirmed = await showConfirmDialog(
      context,
      icon: CupertinoIcons.delete,
      iconColor: CupertinoColors.destructiveRed,
      title: 'Delete Stock',
      message:
          'Remove all inventory records for "${item.productName}"? This cannot be undone.',
      confirmLabel: 'delete'.tr(),
      cancelLabel: 'cancel'.tr(),
    );
    if (confirmed != true || !mounted) return;
    final error = await ref
        .read(inventoryProvider.notifier)
        .deleteProductInventory(item.productId);
    if (!mounted) return;
    if (error != null) {
      _showListError(error);
    } else {
      ref.read(inventoryProvider.notifier).fetchCurrentStock(refresh: true);
    }
  }

  Widget _buildTransactionList(BuildContext context, InventoryState state,
      Color primaryColor, ScrollController scrollController) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: state.transactions.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.transactions.length) {
          return const Center(
            child: Padding(
                padding: EdgeInsets.all(16),
                child: CupertinoActivityIndicator()),
          );
        }
        return _buildTransactionCard(
            context, state.transactions[index], primaryColor);
      },
    );
  }

  Widget _buildTransactionCard(
      BuildContext context, InventoryTransactionModel tx, Color primaryColor) {
    final isIn = tx.isStockIn;
    final isOut = tx.isStockOut;
    final isAdj = tx.isAdjustment;

    IconData icon;
    Color iconColor;
    String sign;
    Color qtyColor;

    if (isIn) {
      icon = CupertinoIcons.add_circled_solid;
      iconColor = primaryColor;
      sign = '+';
      qtyColor = primaryColor;
    } else if (isOut) {
      icon = CupertinoIcons.minus_circle;
      iconColor = CupertinoColors.destructiveRed;
      sign = '-';
      qtyColor = CupertinoColors.destructiveRed;
    } else if (isAdj) {
      icon = CupertinoIcons.slider_horizontal_3;
      iconColor = CupertinoColors.systemOrange;
      sign = tx.quantity >= 0 ? '+' : '';
      qtyColor = CupertinoColors.systemOrange;
    } else {
      icon = CupertinoIcons.arrow_right_arrow_left;
      iconColor = CupertinoColors.systemGrey;
      sign = tx.type == 'transfer_in' ? '+' : '-';
      qtyColor = CupertinoColors.systemGrey;
    }

    return HoverCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      borderRadius: 12,
      color: context.surfaceColor,
      border: Border.all(color: context.borderColor),
      child: CustomPointer(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showTransactionActions(context, tx, primaryColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 20, color: iconColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.productName ?? 'Unknown Product',
                          style: AppTypography.poppins(
                              fontWeight: FontWeight.w600,
                              color: context.primaryTextColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: iconColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tx.typeLabel,
                                style: AppTypography.poppins(
                                  color: iconColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (tx.transactionDate != null)
                              Text(
                                _formatDateTime(tx.transactionDate),
                                style: AppTypography.poppins(
                                  color: context.secondaryTextColor,
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$sign${tx.quantity.abs().toStringAsFixed(0)}',
                        style: AppTypography.poppins(
                          fontWeight: FontWeight.w700,
                          color: qtyColor,
                        ),
                      ),
                      Text(
                        'Bal: ${tx.balanceAfter.toStringAsFixed(0)}',
                        style: AppTypography.poppins(
                            color: context.secondaryTextColor, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildMetaItem(
                        'Unit',
                        tx.unitPrice == 0
                            ? '-'
                            : tx.unitPrice.formattedCurrency,
                        context.primaryTextColor),
                    _buildMetaDivider(),
                    _buildMetaItem(
                        'Total',
                        tx.totalPrice == 0
                            ? '-'
                            : tx.totalPrice.formattedCurrency,
                        context.primaryTextColor),
                    _buildMetaDivider(),
                    _buildMetaItem(
                        'Balance',
                        '${tx.balanceBefore.toStringAsFixed(0)} → ${tx.balanceAfter.toStringAsFixed(0)}',
                        context.primaryTextColor),
                  ],
                ),
              ),
              if ((tx.batchNumber ?? '').isNotEmpty ||
                  (tx.serialNumber ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  [
                    if ((tx.batchNumber ?? '').isNotEmpty)
                      'Batch: ${tx.batchNumber}',
                    if ((tx.serialNumber ?? '').isNotEmpty)
                      'Serial: ${tx.serialNumber}',
                  ].join('   •   '),
                  style: AppTypography.poppins(
                      color: context.secondaryTextColor, fontSize: 11),
                ),
              ],
              if (tx.notes != null && tx.notes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  tx.notes!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.poppins(
                      color: context.secondaryTextColor, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static const _lockedReferenceTypes = {'sale', 'sale_cancel', 'purchase'};

  Future<void> _showTransactionActions(BuildContext context,
      InventoryTransactionModel tx, Color primaryColor) async {
    if (tx.referenceType != null &&
        _lockedReferenceTypes.contains(tx.referenceType)) {
      _showLockedMessage(context);
      return;
    }
    await showCustomActionSheet(
      context,
      title: tx.productName ?? 'Transaction',
      items: [
        ActionSheetItem(
          label: 'edit'.tr(),
          icon: CupertinoIcons.pencil,
          onTap: () => _showTransactionForm(context, editTransaction: tx),
        ),
        ActionSheetItem(
          label: 'delete'.tr(),
          icon: CupertinoIcons.delete,
          onTap: () => _deleteTransaction(context, tx),
          isDestructive: true,
        ),
      ],
    );
  }

  void _showLockedMessage(BuildContext context) {
    showCustomModal(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.lock_fill,
                size: 44, color: CupertinoColors.systemGrey),
            const SizedBox(height: 12),
            const Text('Linked Transaction',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'This entry was created by a sale or purchase. Reverse it there instead of editing here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: context.secondaryTextColor),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                child: Text('ok'.tr()),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTransaction(
      BuildContext context, InventoryTransactionModel tx) async {
    final confirmed = await showConfirmDialog(
      context,
      icon: CupertinoIcons.delete,
      iconColor: CupertinoColors.destructiveRed,
      title: 'Delete Transaction',
      message:
          'Delete this ${tx.typeLabel} entry? Later balances will be recalculated.',
      confirmLabel: 'delete'.tr(),
      cancelLabel: 'cancel'.tr(),
    );
    if (confirmed != true || !mounted) return;
    final error =
        await ref.read(inventoryProvider.notifier).deleteTransaction(tx.id);
    if (!mounted) return;
    if (error != null) {
      _showListError(error);
    } else {
      final notifier = ref.read(inventoryProvider.notifier);
      if (_isStockTab) {
        notifier.fetchCurrentStock(refresh: true);
      } else {
        notifier.setTransactionTypeFilter(_activeTab);
      }
    }
  }

  void _showListError(String message) {
    showCustomModal(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.exclamationmark_circle,
                size: 44, color: CupertinoColors.destructiveRed),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                child: Text('ok'.tr()),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTransactionForm(
    BuildContext context, {
    String? initialProductId,
    String? initialType,
    InventoryTransactionModel? editTransaction,
  }) async {
    final result = await Navigator.of(context).push<bool>(
      CupertinoPageRoute(
        builder: (context) => InventoryTransactionForm(
          initialProductId: initialProductId,
          initialType: initialType,
          editTransaction: editTransaction,
        ),
      ),
    );

    if (result == true && mounted) {
      final notifier = ref.read(inventoryProvider.notifier);
      if (_isStockTab) {
        notifier.fetchCurrentStock(refresh: true);
      } else {
        notifier.setTransactionTypeFilter(_activeTab);
      }
    }
  }
}
