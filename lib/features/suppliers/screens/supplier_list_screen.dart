// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahibz_inventory/core/extensions.dart';
import 'package:sahibz_inventory/features/suppliers/models/supplier_model.dart';
import 'package:sahibz_inventory/features/suppliers/providers/supplier_provider.dart';
import 'package:sahibz_inventory/features/suppliers/repositories/supplier_repository.dart';
import 'package:sahibz_inventory/shared/app_colors.dart';
import 'package:sahibz_inventory/shared/widgets/custom_action_sheet.dart';
import 'package:sahibz_inventory/shared/widgets/filter_chip.dart';
import 'package:sahibz_inventory/shared/widgets/list_screen_template.dart';
import 'package:sahibz_inventory/themes/app_typography.dart';
import 'package:sahibz_inventory/shared/custom_mouse_pointer.dart';

class SupplierListScreen extends ConsumerStatefulWidget {
  final bool showAppBar;

  const SupplierListScreen({super.key, this.showAppBar = true});

  @override
  ConsumerState<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends ConsumerState<SupplierListScreen> {
  final _searchController = TextEditingController();
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(supplierProvider.notifier).fetchAll(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supplierProvider);

    final filterChips = <Widget>[];
    if (state.hasSearch) {
      filterChips.add(FilterChip(
        label: 'Search: ${state.searchQuery}',
        onDeleted: () {
          _searchController.clear();
          ref.read(supplierProvider.notifier).search('');
        },
      ));
    }
    if (state.filterStatus != null) {
      filterChips.add(FilterChip(
        label: 'Status: ${state.filterStatus}',
        onDeleted: () {
          _selectedStatus = null;
          ref.read(supplierProvider.notifier).applyFilters(status: null);
        },
      ));
    }

    return ListScreenTemplate(
      showAppBar: widget.showAppBar,
      title: 'suppliers'.tr(),
      navTrailing: CustomPointer(child: GestureDetector(
        onTap: () => _showStatusFilter(context, state),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(CupertinoIcons.line_horizontal_3_decrease),
        ),
      )),
      searchController: _searchController,
      searchPlaceholder: 'Search suppliers by name, phone, email, TIN...',
      hasSearch: state.hasSearch,
      onSearchChanged: (value) {
        ref.read(supplierProvider.notifier).search(value);
      },
      onClearSearch: () {
        ref.read(supplierProvider.notifier).search('');
      },
      filterChips: filterChips.isNotEmpty ? filterChips : null,
      isLoading: state.isLoading && state.suppliers.isEmpty,
      hasError: state.error != null && state.suppliers.isEmpty,
      errorMessage: state.error,
      onRetry: () => ref.read(supplierProvider.notifier).fetchAll(refresh: true),
      isEmpty: state.suppliers.isEmpty,
      emptyIcon: 'building',
      emptyMessage: 'No Suppliers Found\nGet started by adding your first supplier',
      emptyActionLabel: 'Add Supplier',
      onEmptyAction: () => _navigateToForm(context),
      hasMore: state.hasMore,
      onLoadMore: () => ref.read(supplierProvider.notifier).loadMore(),
      totalCount: state.totalCount,
      countLabel: 'suppliers found',
      contentBuilder: (context, scrollController) {
        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: state.suppliers.length + (state.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= state.suppliers.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CupertinoActivityIndicator(),
                ),
              );
            }
            return _buildSupplierCard(context, state.suppliers[index]);
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
              Text('Add Supplier', style: AppTypography.poppins(color: CupertinoColors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      )),
    );
  }

  Widget _buildSupplierCard(BuildContext context, SupplierModel supplier) {
    return CustomPointer(child: GestureDetector(
      onTap: () => _navigateToForm(context, supplier: supplier),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderColor.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: context.isDarkTheme ? const Color(0xFF0F172A) : const Color(0xFF000000).withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: context.isDarkTheme ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(CupertinoIcons.building_2_fill, size: 24, color: CupertinoTheme.of(context).primaryColor.withValues(alpha: 0.6)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supplier.companyName,
                    style: AppTypography.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: context.primaryTextColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if (supplier.contactPerson != null && supplier.contactPerson!.isNotEmpty)
                    Text(
                      supplier.contactPerson!,
                      style: AppTypography.poppins(fontSize: 12, color: context.secondaryTextColor),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildStatusChip(supplier.status),
                      if (supplier.city != null && supplier.city!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Icon(CupertinoIcons.location, size: 12, color: context.secondaryTextColor),
                        const SizedBox(width: 2),
                        Text(
                          supplier.city!,
                          style: AppTypography.poppins(fontSize: 11, color: context.secondaryTextColor),
                        ),
                      ],
                      if (supplier.tinNumber != null && supplier.tinNumber!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: context.isDarkTheme ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'TIN',
                            style: AppTypography.poppins(fontSize: 8, color: context.secondaryTextColor),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            CustomPointer(child: GestureDetector(
              onTap: () => _showActionSheet(context, supplier),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(CupertinoIcons.ellipsis, size: 20, color: context.secondaryTextColor),
              ),
            )),
          ],
        ),
      ),
    ));
  }

  void _showActionSheet(BuildContext context, SupplierModel supplier) {
    showCustomActionSheet(
      context,
      title: supplier.companyName,
      items: [
        ActionSheetItem(
          label: 'edit'.tr(),
          onTap: () => _navigateToForm(context, supplier: supplier),
        ),
        ActionSheetItem(
          label: 'view_purchases'.tr(),
          onTap: () => _showPurchaseHistory(context, supplier),
        ),
        ActionSheetItem(
          label: 'delete'.tr(),
          onTap: () => _showDeleteConfirmation(context, supplier),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status, {bool small = false}) {
    final color = status == 'active'
        ? CupertinoTheme.of(context).primaryColor
        : status == 'inactive'
            ? (context.isDarkTheme ? const Color(0xFF94A3B8) : const Color(0xFF64748B))
            : CupertinoColors.systemRed;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8, vertical: small ? 1 : 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTypography.poppins(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: small ? 9 : 11,
        ),
      ),
    );
  }

  Future<void> _showStatusFilter(BuildContext context, SupplierState state) async {
    final result = await showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('filter_by_status'.tr()),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: state.filterStatus == null,
            onPressed: () => Navigator.pop(ctx, null),
            child: Text('all'.tr()),
          ),
          CupertinoDialogAction(
            isDefaultAction: state.filterStatus == 'active',
            onPressed: () => Navigator.pop(ctx, 'active'),
            child: Text('active'.tr()),
          ),
          CupertinoDialogAction(
            isDefaultAction: state.filterStatus == 'inactive',
            onPressed: () => Navigator.pop(ctx, 'inactive'),
            child: Text('inactive'.tr()),
          ),
        ],
      ),
    );

    if (result != null) {
      _selectedStatus = result;
      ref.read(supplierProvider.notifier).applyFilters(status: _selectedStatus);
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context, SupplierModel supplier) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('delete_supplier'.tr()),
        content: Text('Are you sure you want to delete "${supplier.companyName}"? This action can be undone by an administrator.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr()),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final error = await ref.read(supplierProvider.notifier).delete(supplier.id);
      if (error != null && mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: Text('error'.tr()),
            content: Text(error),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.pop(ctx),
                child: Text('ok'.tr()),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _showPurchaseHistory(BuildContext context, SupplierModel supplier) async {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => _PurchaseHistoryDialog(supplierId: supplier.id, supplierName: supplier.companyName),
    );
  }

  void _navigateToForm(BuildContext context, {SupplierModel? supplier}) {
    context.push('/suppliers/add', extra: supplier);
  }
}

class _PurchaseHistoryDialog extends ConsumerStatefulWidget {
  final String supplierId;
  final String supplierName;

  const _PurchaseHistoryDialog({
    required this.supplierId,
    required this.supplierName,
  });

  @override
  ConsumerState<_PurchaseHistoryDialog> createState() => _PurchaseHistoryDialogState();
}

class _PurchaseHistoryDialogState extends ConsumerState<_PurchaseHistoryDialog> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final repo = ref.read(supplierRepositoryProvider);
    final result = await repo.getPurchaseHistory(widget.supplierId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.isSuccess) {
          _history = result.value;
        } else {
          _error = result.error.message;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Row(
        children: [
          Icon(CupertinoIcons.doc_plaintext, color: CupertinoTheme.of(context).primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Purchases: ${widget.supplierName}', style: AppTypography.poppins(fontSize: 15, color: context.primaryTextColor)),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        height: 400,
        child: _isLoading
            ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CupertinoActivityIndicator()))
                : _error != null
                    ? Center(child: Text(_error!, style: AppTypography.poppins(color: CupertinoColors.systemRed)))
                : _history.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.doc_plaintext, size: 48, color: context.secondaryTextColor.withValues(alpha: 0.5)),
                            const SizedBox(height: 8),
                            Text('No purchase orders found', style: AppTypography.poppins(fontSize: 15, color: context.secondaryTextColor)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          final item = _history[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: context.borderColor, width: 0.5)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: context.isDarkTheme ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(child: Text('${index + 1}', style: AppTypography.poppins(fontSize: 14, color: context.primaryTextColor))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['orderNumber'] as String, style: AppTypography.poppins(color: context.primaryTextColor)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${item['itemCount']} items | ${(item['totalAmount'] as num).formattedCurrency}',
                                        style: AppTypography.poppins(fontSize: 12, color: context.secondaryTextColor),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  item['status'] as String,
                                  style: AppTypography.poppins(
                                    color: item['status'] == 'received'
                                        ? CupertinoTheme.of(context).primaryColor
                                        : CupertinoColors.systemRed,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: Text('close'.tr()),
        ),
      ],
    );
  }
}
