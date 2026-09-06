// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sahibz_inventory/core/extensions.dart';
import 'package:sahibz_inventory/features/customers/models/customer_model.dart';
import 'package:sahibz_inventory/features/customers/providers/customer_provider.dart';
import 'package:sahibz_inventory/features/customers/repositories/customer_repository.dart';
import 'package:sahibz_inventory/shared/app_colors.dart';
import 'package:sahibz_inventory/shared/widgets/custom_action_sheet.dart';
import 'package:sahibz_inventory/shared/custom_mouse_pointer.dart';
import 'package:sahibz_inventory/shared/widgets/filter_chip.dart';
import 'package:sahibz_inventory/shared/widgets/list_screen_template.dart';
import 'package:sahibz_inventory/themes/app_typography.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  final bool showAppBar;

  const CustomerListScreen({super.key, this.showAppBar = true});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final _searchController = TextEditingController();
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerProvider.notifier).fetchAll(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerProvider);

    final filterChips = <Widget>[];
    if (state.hasSearch) {
      filterChips.add(FilterChip(
        label: 'Search: ${state.searchQuery}',
        onDeleted: () {
          _searchController.clear();
          ref.read(customerProvider.notifier).search('');
        },
      ));
    }
    if (state.filterStatus != null) {
      filterChips.add(FilterChip(
        label: 'Status: ${state.filterStatus}',
        onDeleted: () {
          _selectedStatus = null;
          ref.read(customerProvider.notifier).applyFilters(status: null);
        },
      ));
    }

    return ListScreenTemplate(
      showAppBar: widget.showAppBar,
      title: 'customers'.tr(),
      navTrailing: CustomPointer(
          child: GestureDetector(
        onTap: () => _showStatusFilter(context, state),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(CupertinoIcons.line_horizontal_3_decrease),
        ),
      )),
      searchController: _searchController,
      searchPlaceholder: 'Search customers by name, phone, email, GST...',
      hasSearch: state.hasSearch,
      onSearchChanged: (value) {
        ref.read(customerProvider.notifier).search(value);
      },
      onClearSearch: () {
        ref.read(customerProvider.notifier).search('');
      },
      filterChips: filterChips.isNotEmpty ? filterChips : null,
      isLoading: state.isLoading && state.customers.isEmpty,
      hasError: state.error != null && state.customers.isEmpty,
      errorMessage: state.error,
      onRetry: () =>
          ref.read(customerProvider.notifier).fetchAll(refresh: true),
      isEmpty: state.customers.isEmpty,
      emptyIcon: 'person',
      emptyMessage:
          'No Customers Found\nGet started by adding your first customer',
      emptyActionLabel: 'Add Customer',
      onEmptyAction: () => _navigateToForm(context),
      hasMore: state.hasMore,
      onLoadMore: () => ref.read(customerProvider.notifier).loadMore(),
      totalCount: state.totalCount,
      countLabel: 'customers found',
      contentBuilder: (context, scrollController) {
        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: state.customers.length + (state.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= state.customers.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CupertinoActivityIndicator(),
                ),
              );
            }
            return _buildCustomerCard(context, state.customers[index]);
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
              Text('Add Customer',
                  style: AppTypography.poppins(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      )),
    );
  }

  Widget _buildCustomerCard(BuildContext context, CustomerModel customer) {
    return CustomPointer(
      child: GestureDetector(
          onTap: () => _navigateToForm(context, customer: customer),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: context.borderColor.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: context.isDarkTheme
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF000000).withValues(alpha: 0.04),
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
                    color: context.isDarkTheme
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(CupertinoIcons.person,
                      size: 24,
                      color: CupertinoTheme.of(context)
                          .primaryColor
                          .withValues(alpha: 0.6)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: AppTypography.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.primaryTextColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (customer.phone != null && customer.phone!.isNotEmpty)
                        Text(
                          customer.phone!,
                          style: AppTypography.poppins(
                              fontSize: 12, color: context.secondaryTextColor),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildStatusChip(customer.status),
                          if (customer.city != null &&
                              customer.city!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Icon(CupertinoIcons.location,
                                size: 12, color: context.secondaryTextColor),
                            const SizedBox(width: 2),
                            Text(
                              customer.city!,
                              style: AppTypography.poppins(
                                  fontSize: 11,
                                  color: context.secondaryTextColor),
                            ),
                          ],
                          if (customer.tinNumber != null &&
                              customer.tinNumber!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: context.isDarkTheme
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'TIN',
                                style: AppTypography.poppins(
                                    fontSize: 8,
                                    color: context.secondaryTextColor),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                CustomPointer(
                    child: GestureDetector(
                  onTap: () => _showActionSheet(context, customer),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(CupertinoIcons.ellipsis,
                        size: 20, color: context.secondaryTextColor),
                  ),
                )),
              ],
            ),
          )),
    );
  }

  void _showActionSheet(BuildContext context, CustomerModel customer) {
    showCustomActionSheet(
      context,
      title: customer.name,
      items: [
        ActionSheetItem(
          label: 'edit'.tr(),
          onTap: () => _navigateToForm(context, customer: customer),
        ),
        ActionSheetItem(
          label: 'view_sales'.tr(),
          onTap: () => _showSaleHistory(context, customer),
        ),
        ActionSheetItem(
          label: 'delete'.tr(),
          onTap: () => _showDeleteConfirmation(context, customer),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status, {bool small = false}) {
    final color = status == 'active'
        ? CupertinoTheme.of(context).primaryColor
        : status == 'inactive'
            ? (context.isDarkTheme
                ? const Color(0xFF94A3B8)
                : const Color(0xFF64748B))
            : CupertinoColors.systemRed;

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 6 : 8, vertical: small ? 1 : 2),
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

  Future<void> _showStatusFilter(
      BuildContext context, CustomerState state) async {
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
      ref.read(customerProvider.notifier).applyFilters(status: _selectedStatus);
    }
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, CustomerModel customer) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('delete_customer'.tr()),
        content: Text(
            'Are you sure you want to delete "${customer.name}"? This action can be undone by an administrator.'),
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
      final error =
          await ref.read(customerProvider.notifier).delete(customer.id);
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

  Future<void> _showSaleHistory(
      BuildContext context, CustomerModel customer) async {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => _SaleHistoryDialog(
          customerId: customer.id, customerName: customer.name),
    );
  }

  void _navigateToForm(BuildContext context, {CustomerModel? customer}) {
    context.push('/customers/add', extra: customer);
  }
}

class _SaleHistoryDialog extends ConsumerStatefulWidget {
  final String customerId;
  final String customerName;

  const _SaleHistoryDialog({
    required this.customerId,
    required this.customerName,
  });

  @override
  ConsumerState<_SaleHistoryDialog> createState() => _SaleHistoryDialogState();
}

class _SaleHistoryDialogState extends ConsumerState<_SaleHistoryDialog> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final repo = ref.read(customerRepositoryProvider);
    final result = await repo.getSaleHistory(widget.customerId);

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
          Icon(CupertinoIcons.cart,
              color: CupertinoTheme.of(context).primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Sales: ${widget.customerName}',
                style:
                    AppTypography.poppins(fontSize: 15, color: context.primaryTextColor)),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        height: 400,
        child: _isLoading
            ? const Center(
                child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CupertinoActivityIndicator()))
            : _error != null
                ? Center(
                    child: Text(_error!,
                        style:
                            AppTypography.poppins(color: CupertinoColors.systemRed)))
                : _history.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.cart,
                                size: 48,
                                color: context.secondaryTextColor
                                    .withValues(alpha: 0.5)),
                            const SizedBox(height: 8),
                            Text('No sales records found',
                                style: AppTypography.poppins(
                                    fontSize: 15,
                                    color: context.secondaryTextColor)),
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
                              border: Border(
                                  bottom: BorderSide(
                                      color: context.borderColor, width: 0.5)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: context.isDarkTheme
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                      child: Text('${index + 1}',
                                          style: AppTypography.poppins(
                                              fontSize: 14,
                                              color:
                                                  context.primaryTextColor))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item['invoiceNumber'] as String,
                                          style: AppTypography.poppins(
                                              color: context.primaryTextColor)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${item['itemCount']} items | ${(item['totalAmount'] as num).formattedCurrency}',
                                        style: AppTypography.poppins(
                                            fontSize: 12,
                                            color: context.secondaryTextColor),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  item['status'] as String,
                                  style: AppTypography.poppins(
                                    color: item['status'] == 'completed'
                                        ? CupertinoTheme.of(context)
                                            .primaryColor
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
