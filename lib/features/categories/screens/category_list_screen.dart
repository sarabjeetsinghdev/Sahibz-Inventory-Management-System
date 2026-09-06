// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sahibz_inventory/features/categories/models/category_model.dart';
import 'package:sahibz_inventory/features/categories/providers/category_provider.dart';
import 'package:sahibz_inventory/features/categories/screens/category_form_dialog.dart';
import 'package:sahibz_inventory/shared/app_colors.dart';
import 'package:sahibz_inventory/shared/widgets/custom_action_sheet.dart';
import 'package:sahibz_inventory/shared/custom_mouse_pointer.dart';
import 'package:sahibz_inventory/shared/widgets/filter_chip.dart';
import 'package:sahibz_inventory/shared/widgets/list_screen_template.dart';
import 'package:sahibz_inventory/themes/app_typography.dart';

class CategoryListScreen extends ConsumerStatefulWidget {
  final bool showAppBar;

  const CategoryListScreen({super.key, this.showAppBar = true});

  @override
  ConsumerState<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends ConsumerState<CategoryListScreen> {
  final _searchController = TextEditingController();
  final Set<String> _expandedParents = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryProvider.notifier).fetchAll(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text('ok'.tr()),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryProvider);
    final totalCount = state.categories.length;

    final filterChips = <Widget>[];
    if (state.hasSearch) {
      filterChips.add(FilterChip(
        label: 'Search: ${state.searchQuery}',
        onDeleted: () {
          _searchController.clear();
          ref.read(categoryProvider.notifier).search('');
        },
      ));
    }

    return ListScreenTemplate(
      showAppBar: widget.showAppBar,
      title: 'categories'.tr(),
      navTrailing: CustomPointer(
          child: GestureDetector(
        onTap: () => _showFormDialog(context),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(CupertinoIcons.add),
        ),
      )),
      searchController: _searchController,
      searchPlaceholder: 'Search categories by name...',
      hasSearch: state.hasSearch,
      onSearchChanged: (value) =>
          ref.read(categoryProvider.notifier).search(value),
      onClearSearch: () => ref.read(categoryProvider.notifier).search(''),
      filterChips: filterChips.isNotEmpty ? filterChips : null,
      isLoading: state.isLoading && totalCount == 0,
      hasError: state.error != null && totalCount == 0,
      errorMessage: state.error,
      onRetry: () =>
          ref.read(categoryProvider.notifier).fetchAll(refresh: true),
      isEmpty: totalCount == 0,
      emptyIcon: 'folder',
      emptyMessage: 'No Categories Found',
      emptyActionLabel: 'add_category'.tr(),
      onEmptyAction: () => _showFormDialog(context),
      hasMore: state.hasMore,
      onLoadMore: () => ref.read(categoryProvider.notifier).loadMore(),
      totalCount: totalCount,
      countLabel: 'categories',
      contentBuilder: (context, scrollController) {
        final rootCategories = state.categories.where((c) => c.isRoot).toList();
        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: rootCategories.length + (state.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= rootCategories.length) {
              return const Center(
                child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CupertinoActivityIndicator()),
              );
            }
            return _buildCategoryNode(
                context, rootCategories[index], state.categories, 0);
          },
        );
      },
      fab: CupertinoButton.filled(
        sizeStyle: CupertinoButtonSize.medium,
        onPressed: () => _showFormDialog(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.add, color: CupertinoColors.white),
            const SizedBox(width: 8),
            Text('add_category'.tr()),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryNode(BuildContext context, CategoryModel category,
      List<CategoryModel> allCategories, int depth) {
    final children =
        allCategories.where((c) => c.parentId == category.id).toList();
    final hasChildren = children.isNotEmpty;
    final isExpanded = _expandedParents.contains(category.id);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(left: depth * 24.0),
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.borderColor.withOpacity(0.5)),
            ),
            child: CustomPointer(
                child: GestureDetector(
              onTap: hasChildren
                  ? () {
                      setState(() {
                        if (isExpanded) {
                          _expandedParents.remove(category.id);
                        } else {
                          _expandedParents.add(category.id);
                        }
                      });
                    }
                  : null,
              onLongPress: () => _showFormDialog(context, category: category),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    if (hasChildren)
                      Icon(
                        isExpanded
                            ? CupertinoIcons.chevron_down
                            : CupertinoIcons.chevron_right,
                        size: 20,
                        color: context.secondaryTextColor,
                      )
                    else
                      const SizedBox(width: 20),
                    const SizedBox(width: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: context.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        category.image != null && category.image!.isNotEmpty
                            ? CupertinoIcons.photo
                            : hasChildren
                                ? CupertinoIcons.folder
                                : CupertinoIcons.tray_full,
                        size: 20,
                        color: context.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: AppTypography.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: context.primaryTextColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (category.description != null &&
                              category.description!.isNotEmpty)
                            Text(
                              category.description!,
                              style: AppTypography.poppins(
                                  fontSize: 12,
                                  color: context.secondaryTextColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (category.parentName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.isDarkTheme
                              ? const Color(0xFF334155)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          category.parentName!,
                          style: AppTypography.poppins(
                              fontSize: 10, color: context.secondaryTextColor),
                        ),
                      ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(category.status, context),
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
                                  _showFormDialog(context, category: category),
                            ),
                            ActionSheetItem(
                              label: 'add_subcategory'.tr(),
                              onTap: () => _showFormDialog(context,
                                  parentId: category.id),
                            ),
                            ActionSheetItem(
                              label: 'delete'.tr(),
                              onTap: () =>
                                  _showDeleteConfirmation(context, category),
                              isDestructive: true,
                            ),
                          ],
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(CupertinoIcons.ellipsis, size: 18),
                      ),
                    )),
                  ],
                ),
              ),
            )),
          ),
        ),
        if (hasChildren && isExpanded)
          ...children.map((child) =>
              _buildCategoryNode(context, child, allCategories, depth + 1)),
      ],
    );
  }

  Widget _buildStatusBadge(String status, BuildContext context) {
    final color =
        status == 'active' ? context.primaryColor : context.secondaryTextColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTypography.poppins(
            fontSize: 9, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Future<void> _showFormDialog(BuildContext context,
      {CategoryModel? category, String? parentId}) async {
    final result = await Navigator.of(context).push<bool>(
      CupertinoPageRoute(
        builder: (context) => CategoryFormDialog(
          category: category,
          parentId: parentId,
        ),
      ),
    );

    if (result == true && mounted) {
      ref.read(categoryProvider.notifier).fetchAll(refresh: true);
    }
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, CategoryModel category) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('delete_category'.tr()),
        content: Text(
            'Are you sure you want to delete "${category.name}"? This action can be undone by an administrator.'),
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

    if (confirmed == true && mounted) {
      final error =
          await ref.read(categoryProvider.notifier).delete(category.id);
      if (error != null && mounted) {
        _showMessage(error, isError: true);
      }
    }
  }
}
