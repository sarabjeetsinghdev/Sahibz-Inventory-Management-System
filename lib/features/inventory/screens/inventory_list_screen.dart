// ignore_for_file: deprecated_member_use, unused_local_variable

import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahibz_inventory/features/inventory/models/inventory_model.dart';
import 'package:sahibz_inventory/features/inventory/providers/inventory_provider.dart';
import 'package:sahibz_inventory/features/inventory/screens/inventory_transaction_form.dart';
import 'package:sahibz_inventory/shared/app_colors.dart';
import 'package:sahibz_inventory/shared/custom_mouse_pointer.dart';
import 'package:sahibz_inventory/shared/widgets/custom_action_sheet.dart';
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
  String _viewMode = 'stock';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uri = GoRouterState.of(context).uri;
      final filter = uri.queryParameters['filter'];
      if (filter == 'low_stock') {
        ref.read(inventoryProvider.notifier).fetchLowStock();
      } else if (filter == 'out_of_stock') {
        ref.read(inventoryProvider.notifier).fetchOutOfStock();
      } else {
        ref.read(inventoryProvider.notifier).fetchCurrentStock(refresh: true);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StockSummaryModel> _getDisplayItems(InventoryState state) {
    if (state.lowStockItems.isNotEmpty) return state.lowStockItems;
    if (state.outOfStockItems.isNotEmpty) return state.outOfStockItems;
    return state.stockItems;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryProvider);
    final primaryColor = CupertinoTheme.of(context).primaryColor;

    final items = _getDisplayItems(state);
    final stockCount = items.length;
    final transactionCount = state.transactions.length;
    final totalCount = _viewMode == 'stock' ? stockCount : transactionCount;

    return ListScreenTemplate(
      showAppBar: widget.showAppBar,
      title: 'inventory'.tr(),
      navTrailing: CustomPointer(
          child: GestureDetector(
        onTap: () => _showFilterActions(context),
        child: const Icon(CupertinoIcons.ellipsis),
      )),
      searchController: _searchController,
      searchPlaceholder: 'Search by product name or SKU...',
      hasSearch: state.hasSearch,
      onSearchChanged: (value) =>
          ref.read(inventoryProvider.notifier).search(value),
      filterChips: [
        _buildViewToggleChips(context, primaryColor),
      ],
      isLoading: state.isLoading && totalCount == 0,
      hasError: state.error != null && totalCount == 0,
      errorMessage: state.error,
      onRetry: () =>
          ref.read(inventoryProvider.notifier).fetchCurrentStock(refresh: true),
      isEmpty: totalCount == 0,
      emptyIcon: 'cube',
      emptyMessage: 'No Inventory Data',
      emptyActionLabel: 'New Transaction',
      onEmptyAction: () => _showTransactionForm(context),
      hasMore: state.hasMore,
      onLoadMore: () {
        final notifier = ref.read(inventoryProvider.notifier);
        if (_viewMode == 'stock') {
          notifier.loadMoreStock();
        } else {
          notifier.loadMoreTransactions();
        }
      },
      totalCount: totalCount,
      countLabel: _viewMode == 'stock' ? 'items' : 'transactions',
      contentBuilder: (context, scrollController) {
        if (_viewMode == 'stock') {
          return _buildStockList(
              context, state, items, primaryColor, scrollController);
        } else {
          return _buildTransactionList(
              context, state, primaryColor, scrollController);
        }
      },
      fab: CustomPointer(
          child: GestureDetector(
        onTap: () => _showTransactionForm(context),
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
              Text('New Transaction',
                  style: AppTypography.poppins(color: CupertinoColors.white)),
            ],
          ),
        ),
      )),
    );
  }

  Future<void> _showFilterActions(BuildContext context) async {
    await showCustomActionSheet(
      context,
      title: 'filter_options'.tr(),
      items: [
        ActionSheetItem(
          label: 'low_stock_alerts'.tr(),
          onTap: () {
            ref.read(inventoryProvider.notifier).fetchLowStock();
          },
        ),
        ActionSheetItem(
          label: 'out_of_stock'.tr(),
          onTap: () {
            ref.read(inventoryProvider.notifier).fetchOutOfStock();
          },
        ),
      ],
    );
  }

  Widget _buildViewToggleChips(BuildContext context, Color primaryColor) {
    final isDark = context.isDarkTheme;
    final chipColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildViewChip(context, 'Stock', 'stock', chipColor, primaryColor),
        const SizedBox(width: 4),
        _buildViewChip(
            context, 'Transactions', 'transactions', chipColor, primaryColor),
      ],
    );
  }

  Widget _buildViewChip(BuildContext context, String label, String value,
      Color chipColor, Color primaryColor) {
    final isSelected = _viewMode == value;
    return CustomPointer(
        child: GestureDetector(
      onTap: () {
        if (isSelected) return;
        setState(() => _viewMode = value);
        final notifier = ref.read(inventoryProvider.notifier);
        if (value == 'transactions') {
          notifier.fetchTransactions(refresh: true);
        } else {
          notifier.fetchCurrentStock(refresh: true);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.15)
              : chipColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? primaryColor : chipColor),
        ),
        child: Text(
          label,
          style: AppTypography.poppins(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? primaryColor : context.primaryTextColor,
          ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              CupertinoIcons.square_grid_2x2_fill,
              size: 20,
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
                          width: 1, height: 10, color: context.borderColor),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
          const SizedBox(width: 4),
          CustomPointer(
              child: GestureDetector(
            onTap: () => _showItemActions(context, item, primaryColor),
            child: const Icon(CupertinoIcons.ellipsis, size: 18),
          )),
        ],
      ),
    );
  }

  Future<void> _showItemActions(
      BuildContext context, StockSummaryModel item, Color primaryColor) async {
    await showCustomActionSheet(
      context,
      items: [
        ActionSheetItem(
          label: 'stock_in'.tr(),
          icon: CupertinoIcons.add_circled,
          onTap: () {
            _showTransactionForm(context,
                initialProductId: item.productId, initialType: 'stock_in');
          },
        ),
        ActionSheetItem(
          label: 'stock_out'.tr(),
          icon: CupertinoIcons.minus_circled,
          onTap: () {
            _showTransactionForm(context,
                initialProductId: item.productId, initialType: 'stock_out');
          },
        ),
        ActionSheetItem(
          label: 'Adjust',
          icon: CupertinoIcons.slider_horizontal_3,
          onTap: () {
            _showTransactionForm(context,
                initialProductId: item.productId, initialType: 'adjustment');
          },
        ),
        ActionSheetItem(
          label: 'transfer'.tr(),
          icon: CupertinoIcons.arrow_right_arrow_left,
          onTap: () {
            _showTransactionForm(context,
                initialProductId: item.productId, initialType: 'transfer');
          },
        ),
      ],
    );
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

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
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
    );
  }

  Future<void> _showTransactionForm(
    BuildContext context, {
    String? initialProductId,
    String? initialType,
  }) async {
    final result = await Navigator.of(context).push<bool>(
      CupertinoPageRoute(
        builder: (context) => InventoryTransactionForm(
          initialProductId: initialProductId,
          initialType: initialType,
        ),
      ),
    );

    if (result == true && mounted) {
      ref.read(inventoryProvider.notifier).fetchCurrentStock(refresh: true);
    }
  }
}
