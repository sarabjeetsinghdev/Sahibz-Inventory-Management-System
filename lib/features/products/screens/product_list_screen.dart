// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sahibz_inventory/core/extensions.dart';
import 'package:sahibz_inventory/features/products/models/product_model.dart';
import 'package:sahibz_inventory/features/products/providers/product_provider.dart';
import 'package:sahibz_inventory/features/products/services/product_excel_importer.dart';
import 'package:sahibz_inventory/shared/custom_modal.dart';
import 'package:sahibz_inventory/shared/widgets/custom_action_sheet.dart';
import 'package:sahibz_inventory/shared/app_colors.dart';
import 'package:sahibz_inventory/shared/custom_mouse_pointer.dart';
import 'package:sahibz_inventory/shared/widgets/filter_chip.dart';
import 'package:sahibz_inventory/shared/widgets/hover_card.dart';
import 'package:sahibz_inventory/shared/widgets/list_screen_template.dart';
import 'package:sahibz_inventory/shared/item_selector.dart';
import 'package:sahibz_inventory/themes/app_typography.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  final bool showAppBar;

  const ProductListScreen({super.key, this.showAppBar = true});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchController = TextEditingController();
  bool _isGridView = false;
  bool _progressOpen = false;

  String? _selectedCategoryId;
  String? _selectedSupplierId;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productProvider.notifier).fetchAll(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    showCustomModal(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
                isError
                    ? CupertinoIcons.exclamationmark_circle
                    : CupertinoIcons.check_mark_circled,
                size: 48,
                color: isError
                    ? CupertinoColors.destructiveRed
                    : CupertinoColors.activeGreen),
            const SizedBox(height: 16),
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

  Future<void> _showImportMenu() async {
    await showCustomActionSheet(
      context,
      title: 'Import Products',
      items: [
        ActionSheetItem(
          label: 'Import from Excel',
          icon: CupertinoIcons.cloud_download,
          onTap: _importProductsExcel,
        ),
      ],
    );
  }

  Future<void> _importProductsExcel() async {
    final picked = await FilePicker.pickFiles(
      dialogTitle: 'Select Products Excel',
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    final bytes = file.bytes ??
        (file.path != null ? await File(file.path!).readAsBytes() : null);
    if (bytes == null || !mounted) return;

    final policy = await _askDuplicatePolicy();
    if (policy == null || !mounted) return;

    _progressOpen = true;
    showCustomModal(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Consumer(
          builder: (c, ref, _) {
            final progress = ref.watch(productProvider);
            final total = progress.importTotal;
            final done = progress.importDone;
            final frac =
                total > 0 ? (done / total).clamp(0.0, 1.0) : 0.0;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CupertinoActivityIndicator(radius: 20),
                const SizedBox(height: 16),
                const Text('Importing products...',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                    total > 0 ? 'Row $done of $total' : 'Preparing...',
                    style: const TextStyle(
                        fontSize: 13, color: CupertinoColors.systemGrey)),
                const SizedBox(height: 12),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey5,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: frac,
                        child: Container(
                          decoration: BoxDecoration(
                            color: CupertinoTheme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ).then((_) => _progressOpen = false);

    // Let the progress dialog paint before the heavy import work starts.
    // Excel.decodeBytes is synchronous CPU work that would otherwise block
    // the first frame, so the modal would never appear on large files.
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) {
      _progressOpen = false;
      return;
    }

    final result = await ref
        .read(productProvider.notifier)
        .importFromExcel(bytes, policy: policy);
    if (!mounted) return;
    if (_progressOpen) {
      _progressOpen = false;
      Navigator.of(context).pop();
    }
    if (result == null) {
      final err = ref.read(productProvider).error;
      _showMessage(err ?? 'Import failed', isError: true);
      return;
    }
    _showImportResult(result);
  }

  Future<DuplicatePolicy?> _askDuplicatePolicy() async {
    DuplicatePolicy selected = DuplicatePolicy.skip;
    final options = [
      (
        value: DuplicatePolicy.skip,
        icon: CupertinoIcons.forward,
        title: 'Skip duplicates',
        subtitle: 'Keep existing products untouched',
        color: CupertinoColors.systemGrey,
      ),
      (
        value: DuplicatePolicy.replace,
        icon: CupertinoIcons.arrow_2_circlepath,
        title: 'Replace with Excel data',
        subtitle: 'Overwrite existing products',
        color: CupertinoColors.activeBlue,
      ),
      (
        value: DuplicatePolicy.discard,
        icon: CupertinoIcons.delete,
        title: 'Delete duplicates',
        subtitle: 'Remove existing products',
        color: CupertinoColors.destructiveRed,
      ),
    ];
    return showCustomModal<DuplicatePolicy>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setDialogState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.doc_on_doc,
                  size: 44, color: CupertinoColors.systemGrey),
              const SizedBox(height: 12),
              const Text('Duplicate Products',
                  style:
                      TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              const Text('If an imported product already exists\n(matched by name):',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: CupertinoColors.systemGrey)),
              const SizedBox(height: 14),
              ...options.map((o) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: CustomPointer(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () =>
                            setDialogState(() => selected = o.value),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected == o.value
                                  ? o.color
                                  : CupertinoColors.darkBackgroundGray,
                              width: 0.9,
                            ),
                            color: selected == o.value
                                ? o.color.withValues(alpha: 0.08)
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(o.icon, size: 20, color: o.color),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(o.title,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600)),
                                    Text(o.subtitle,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: CupertinoColors
                                                .systemGrey)),
                                  ],
                                ),
                              ),
                              Icon(
                                selected == o.value
                                    ? CupertinoIcons
                                        .check_mark_circled_solid
                                    : CupertinoIcons.circle,
                                size: 20,
                                color: selected == o.value
                                    ? o.color
                                    : CupertinoColors.systemGrey3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CustomPointer(
                      child: CupertinoButton.filled(
                        color: CupertinoColors.systemRed,
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('cancel'.tr()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomPointer(
                      child: CupertinoButton.filled(
                        onPressed: () => Navigator.pop(ctx, selected),
                        child: const Text('Continue'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImportResult(ProductImportResult result) {
    final hasErrors = result.errors.isNotEmpty;
    showCustomModal(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
                result.imported > 0
                    ? CupertinoIcons.check_mark_circled
                    : CupertinoIcons.exclamationmark_circle,
                size: 48,
                color: result.imported > 0
                    ? CupertinoColors.activeGreen
                    : CupertinoColors.systemOrange),
            const SizedBox(height: 12),
            Text(result.summary,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            if (hasErrors) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: result.errors.length,
                    itemBuilder: (c, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(result.errors[i],
                          style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                ),
              ),
            ],
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productProvider);
    final filterChips = <Widget>[];
    final totalCount = state.products.length;

    if (state.hasSearch) {
      filterChips.add(FilterChip(
        label: 'Search: ${state.searchQuery}',
        onDeleted: () {
          _searchController.clear();
          ref.read(productProvider.notifier).search('');
        },
      ));
    }
    if (state.filterCategoryId != null) {
      filterChips.add(FilterChip(
        label: 'Category filter',
        onDeleted: () {
          _selectedCategoryId = null;
          ref.read(productProvider.notifier).applyFilters(
                categoryId: null,
                supplierId: _selectedSupplierId,
                status: _selectedStatus,
              );
        },
      ));
    }
    if (state.filterSupplierId != null) {
      filterChips.add(FilterChip(
        label: 'Supplier filter',
        onDeleted: () {
          _selectedSupplierId = null;
          ref.read(productProvider.notifier).applyFilters(
                categoryId: _selectedCategoryId,
                supplierId: null,
                status: _selectedStatus,
              );
        },
      ));
    }
    if (state.filterStatus != null) {
      filterChips.add(FilterChip(
        label: 'Status: ${state.filterStatus}',
        onDeleted: () {
          _selectedStatus = null;
          ref.read(productProvider.notifier).applyFilters(
                categoryId: _selectedCategoryId,
                supplierId: _selectedSupplierId,
                status: null,
              );
        },
      ));
    }

    return ListScreenTemplate(
      showAppBar: widget.showAppBar,
      title: 'products'.tr(),
      // header: Container(
      //   width: double.infinity,
      //   margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      //   padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      //   decoration: BoxDecoration(
      //     color: context.primaryColor.withValues(alpha: 0.08),
      //     borderRadius: BorderRadius.circular(12),
      //     border:
      //         Border.all(color: context.primaryColor.withValues(alpha: 0.2)),
      //   ),
      //   child: Row(
      //     children: [
      //       Icon(CupertinoIcons.cube_box_fill,
      //           size: 22, color: context.primaryColor),
      //       const SizedBox(width: 10),
      //       Text('Total Products',
      //           style: AppTypography.poppins(
      //               fontSize: 13, color: context.secondaryTextColor)),
      //       const Spacer(),
      //       Text('${state.totalCount}',
      //           style: AppTypography.poppins(
      //               fontSize: 20,
      //               fontWeight: FontWeight.w700,
      //               color: context.primaryColor)),
      //     ],
      //   ),
      // ),
      navTrailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPointer(
              child: GestureDetector(
            onTap: _showImportMenu,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(CupertinoIcons.cloud_download),
            ),
          )),
          // CustomPointer(
          //     child: GestureDetector(
          //   onTap: () => setState(() => _isGridView = !_isGridView),
          //   child: const Padding(
          //     padding: EdgeInsets.all(8),
          //     child: Icon(CupertinoIcons.square_list),
          //   ),
          // )),
          CustomPointer(
              child: GestureDetector(
            onTap: () => _showFilterDialog(context, state),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(CupertinoIcons.line_horizontal_3_decrease),
            ),
          )),
        ],
      ),
      searchController: _searchController,
      searchPlaceholder: 'Search products by name, SKU or barcode...',
      hasSearch: state.hasSearch,
      onSearchChanged: (value) =>
          ref.read(productProvider.notifier).search(value),
      onClearSearch: () => ref.read(productProvider.notifier).search(''),
      filterChips: filterChips.isNotEmpty ? filterChips : null,
      isLoading: state.isLoading && state.products.isEmpty,
      hasError: state.error != null && state.products.isEmpty,
      errorMessage: state.error,
      onRetry: () => ref.read(productProvider.notifier).fetchAll(refresh: true),
      isEmpty: state.products.isEmpty,
      emptyIcon: 'tray',
      emptyMessage:
          'No Products Found\nGet started by adding your first product',
      emptyActionLabel: 'Add Product',
      onEmptyAction: () => _navigateToForm(context),
      hasMore: state.hasMore,
      onLoadMore: () => ref.read(productProvider.notifier).loadMore(),
      totalCount: state.totalCount,
      countLabel: 'Total: ',
      contentBuilder: (context, scrollController) {
        return _isGridView
            ? _buildGridView(context, state, scrollController)
            : _buildListView(context, state, scrollController);
      },
      fab: CupertinoButton.filled(
        sizeStyle: CupertinoButtonSize.medium,
        onPressed: () => _navigateToForm(context),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.add, color: CupertinoColors.white),
            SizedBox(width: 8),
            Text('Add Product'),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(BuildContext context, ProductState state,
      ScrollController scrollController) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: state.products.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.products.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CupertinoActivityIndicator(),
            ),
          );
        }
        return _buildProductCard(context, state.products[index]);
      },
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    return HoverCard(
      margin: const EdgeInsets.only(bottom: 8),
      borderRadius: 12,
      color: context.surfaceColor,
      border: Border.all(color: context.borderColor.withOpacity(0.5)),
      child: CustomPointer(
        child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _navigateToForm(context, product: product),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: context.primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: product.image != null && product.image!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(product.image!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _productIcon(product)),
                          )
                        : _productIcon(product),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: AppTypography.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.primaryTextColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.sku,
                          style: AppTypography.poppins(
                              fontSize: 12, color: context.secondaryTextColor),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildStatusChip(product.status, context),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        product.sellingPrice.formattedCurrency,
                        style: AppTypography.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Qty: ${product.quantity.toIntSafe}',
                        style: AppTypography.poppins(
                            fontSize: 12, color: context.secondaryTextColor),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  CustomPointer(
                      child: GestureDetector(
                    onTap: () {
                      showCustomActionSheet(
                        context,
                        title: 'options'.tr(),
                        items: [
                          ActionSheetItem(
                            label: 'edit'.tr(),
                            onTap: () =>
                                _navigateToForm(context, product: product),
                          ),
                          ActionSheetItem(
                            label: 'delete'.tr(),
                            onTap: () =>
                                _showDeleteConfirmation(context, product),
                            isDestructive: true,
                          ),
                        ],
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(CupertinoIcons.ellipsis, size: 20),
                    ),
                  )),
                ],
              ),
            )),
      ),
    );
  }

  Widget _productIcon(ProductModel product) {
    return Icon(CupertinoIcons.tray_full,
        size: 28,
        color: CupertinoTheme.of(context).primaryColor.withOpacity(0.6));
  }

  Widget _buildGridView(BuildContext context, ProductState state,
      ScrollController scrollController) {
    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: state.products.length,
      itemBuilder: (context, index) {
        return _buildGridCard(context, state.products[index]);
      },
    );
  }

  Widget _buildGridCard(BuildContext context, ProductModel product) {
    return HoverCard(
      borderRadius: 12,
      color: context.surfaceColor,
      border: Border.all(color: context.borderColor.withOpacity(0.5)),
      child: CustomPointer(
          child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _navigateToForm(context, product: product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.primaryColor.withOpacity(0.15),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: product.image != null && product.image!.isNotEmpty
                  ? ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(product.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _gridProductIcon(product)),
                    )
                  : _gridProductIcon(product),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTypography.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.primaryTextColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.sku,
                    style: AppTypography.poppins(
                        fontSize: 12, color: context.secondaryTextColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.sellingPrice.formattedCurrency,
                        style: AppTypography.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.primaryColor,
                        ),
                      ),
                      Text(
                        'Qty: ${product.quantity.toIntSafe}',
                        style: AppTypography.poppins(
                            fontSize: 12, color: context.secondaryTextColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _buildStatusChip(product.status, context, small: true),
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }

  Widget _gridProductIcon(ProductModel product) {
    return Center(
      child: Icon(CupertinoIcons.tray_full,
          size: 40,
          color: CupertinoTheme.of(context).primaryColor.withOpacity(0.4)),
    );
  }

  Widget _buildStatusChip(String status, BuildContext context,
      {bool small = false}) {
    final outlineColor =
        context.isDarkTheme ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    final color = status == 'active'
        ? context.primaryColor
        : status == 'inactive'
            ? outlineColor
            : CupertinoColors.destructiveRed;

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 6 : 8, vertical: small ? 1 : 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
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

  Future<void> _showFilterDialog(
      BuildContext context, ProductState state) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      CupertinoPageRoute(
        builder: (context) => _ProductFilterScreen(
          initialCategoryId: state.filterCategoryId,
          initialSupplierId: state.filterSupplierId,
          initialStatus: state.filterStatus,
        ),
      ),
    );

    if (result != null) {
      _selectedCategoryId = result['categoryId'] as String?;
      _selectedSupplierId = result['supplierId'] as String?;
      _selectedStatus = result['status'] as String?;
      ref.read(productProvider.notifier).applyFilters(
            categoryId: _selectedCategoryId,
            supplierId: _selectedSupplierId,
            status: _selectedStatus,
          );
    }
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, ProductModel product) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('delete_product'.tr()),
        content: Text(
            'Are you sure you want to delete "${product.name}"? This action can be undone by an administrator.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final error = await ref.read(productProvider.notifier).delete(product.id);
      if (error != null && mounted) {
        _showMessage(error, isError: true);
      }
    }
  }

  void _navigateToForm(BuildContext context, {ProductModel? product}) {
    context.push('/products/add', extra: product);
  }
}

class _ProductFilterScreen extends StatefulWidget {
  final String? initialCategoryId;
  final String? initialSupplierId;
  final String? initialStatus;

  const _ProductFilterScreen({
    this.initialCategoryId,
    this.initialSupplierId,
    this.initialStatus,
  });

  @override
  State<_ProductFilterScreen> createState() => _ProductFilterScreenState();
}

class _ProductFilterScreenState extends State<_ProductFilterScreen> {
  String? _categoryId;
  String? _supplierId;
  String? _status;

  final List<({String label, String? value})> _statusItems = [
    (label: 'All Statuses', value: null),
    (label: 'active'.tr(), value: 'active'),
    (label: 'inactive'.tr(), value: 'inactive'),
    (label: 'Discontinued', value: 'discontinued'),
  ];

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategoryId;
    _supplierId = widget.initialSupplierId;
    _status = widget.initialStatus;
  }

  void _showPicker({
    required String title,
    required List<({String label, String? value})> items,
    required String? currentValue,
    required ValueChanged<String?> onSelected,
  }) {
    showCustomModal(
      context: context,
      builder: (_) => ItemSelector(
        items: items.map((e) => e.value ?? '').toList(),
        labels: items.map((e) => e.label).toList(),
        initialValue: currentValue,
        onSelected: (value) => onSelected(value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // final brightness = CupertinoTheme.of(context).brightness;
    // final context.isDarkTheme = brightness == Brightness.dark;
    // final context.primaryTextColor = context.isDarkTheme ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    // final context.secondaryTextColor = context.isDarkTheme ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    // final context.borderColor = context.isDarkTheme ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    // final context.surfaceColor = context.isDarkTheme ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    // final bgColor = context.isDarkTheme ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Filter Products'),
        leading: CustomPointer(
            child: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text('cancel'.tr()),
          onPressed: () => Navigator.pop(context),
        )),
        trailing: CustomPointer(
            child: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text('apply'.tr()),
          onPressed: () => Navigator.pop(context, {
            'categoryId': _categoryId,
            'supplierId': _supplierId,
            'status': _status,
          }),
        )),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CustomPointer(
                child: GestureDetector(
              onTap: () => _showPicker(
                title: 'Category',
                items: const [
                  (label: 'All Categories', value: null),
                ],
                currentValue: _categoryId,
                onSelected: (v) => setState(() => _categoryId = v),
              ),
              child: _buildPickerTile('Category', _categoryId),
            )),
            const SizedBox(height: 16),
            CustomPointer(
                child: GestureDetector(
              onTap: () => _showPicker(
                title: 'Supplier',
                items: const [
                  (label: 'All Suppliers', value: null),
                ],
                currentValue: _supplierId,
                onSelected: (v) => setState(() => _supplierId = v),
              ),
              child: _buildPickerTile('Supplier', _supplierId),
            )),
            const SizedBox(height: 16),
            CustomPointer(
                child: GestureDetector(
              onTap: () => _showPicker(
                title: 'Status',
                items: _statusItems,
                currentValue: _status,
                onSelected: (v) => setState(() => _status = v),
              ),
              child: _buildPickerTile('Status', _status),
            )),
            const SizedBox(height: 24),
            CustomPointer(
                child: CupertinoButton(
              child: Text('clear_all'.tr()),
              onPressed: () => setState(() {
                _categoryId = null;
                _supplierId = null;
                _status = null;
              }),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerTile(String label, String? value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTypography.poppins(
                        fontSize: 12, color: context.secondaryTextColor)),
                const SizedBox(height: 4),
                Text(
                  value ?? (label == 'Status' ? 'All Statuses' : 'All'),
                  style: AppTypography.poppins(
                      fontSize: 16, color: context.primaryTextColor),
                ),
              ],
            ),
          ),
          Icon(CupertinoIcons.chevron_right,
              color: context.secondaryTextColor, size: 16),
        ],
      ),
    );
  }
}
