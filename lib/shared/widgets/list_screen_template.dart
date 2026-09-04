// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sahibz_inventory/shared/app_colors.dart';
import 'package:sahibz_inventory/shared/custom_mouse_pointer.dart';
import 'package:sahibz_inventory/themes/app_typography.dart';

class ListScreenTemplate extends StatefulWidget {
  final bool showAppBar;
  final String title;
  final Widget? navLeading;
  final Widget? navTrailing;

  final TextEditingController searchController;
  final String? searchPlaceholder;
  final bool hasSearch;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onClearSearch;

  final List<Widget>? filterChips;

  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final bool isEmpty;
  final String emptyIcon;
  final String emptyMessage;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;

  final bool hasMore;
  final VoidCallback onLoadMore;
  final int totalCount;
  final String countLabel;

  final Widget Function(BuildContext context, ScrollController scrollController)
      contentBuilder;

  final Widget? fab;

  const ListScreenTemplate({
    super.key,
    this.showAppBar = true,
    required this.title,
    this.navLeading,
    this.navTrailing,
    required this.searchController,
    this.searchPlaceholder,
    this.hasSearch = false,
    required this.onSearchChanged,
    this.onClearSearch,
    this.filterChips,
    required this.isLoading,
    this.hasError = false,
    this.errorMessage,
    this.onRetry,
    required this.isEmpty,
    this.emptyIcon = 'tray',
    required this.emptyMessage,
    this.emptyActionLabel,
    this.onEmptyAction,
    required this.hasMore,
    required this.onLoadMore,
    required this.totalCount,
    required this.countLabel,
    required this.contentBuilder,
    this.fab,
  });

  @override
  State<ListScreenTemplate> createState() => _ListScreenTemplateState();
}

class _ListScreenTemplateState extends State<ListScreenTemplate> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.addListener(_onScroll);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (max < 200) return;
    if (_scrollController.position.pixels >= max - 200) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onLoadMore();
      });
    }
  }

  IconData _resolveIcon() {
    switch (widget.emptyIcon) {
      case 'tray':
        return CupertinoIcons.tray_full;
      case 'person':
        return CupertinoIcons.person_2;
      case 'building':
        return CupertinoIcons.building_2_fill;
      case 'folder':
        return CupertinoIcons.folder;
      case 'doc':
        return CupertinoIcons.doc_text;
      case 'cart':
        return CupertinoIcons.cart;
      case 'cube':
        return CupertinoIcons.cube;
      case 'bell':
        return CupertinoIcons.bell;
      case 'clock':
        return CupertinoIcons.clock;
      case 'chart':
        return CupertinoIcons.chart_bar;
      default:
        return CupertinoIcons.tray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          Column(
            children: [
              _buildSearchBar(context),
              if (widget.isLoading && !_hasData)
                const Expanded(
                    child: Center(child: CupertinoActivityIndicator()))
              else if (widget.hasError && !_hasData)
                Expanded(child: _buildErrorState(context))
              else if (widget.isEmpty && !_hasData)
                Expanded(child: _buildEmptyState(context))
              else
                Expanded(child: _buildContent(context)),
            ],
          ),
          if (widget.fab != null)
            Positioned(right: 16, bottom: 16, child: CustomPointer(child: widget.fab!)),
        ],
      ),
    );
  }

  bool get _hasData => widget.totalCount > 0;

  Widget _buildSearchBar(BuildContext context) {
    final filterActive = widget.hasSearch ||
        (widget.filterChips != null && widget.filterChips!.isNotEmpty);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: widget.searchController,
                  placeholder: widget.searchPlaceholder ?? 'search'.tr(),
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(CupertinoIcons.search, size: 20),
                  ),
                  suffix: widget.hasSearch
                      ? CustomPointer(
                          child: GestureDetector(
                          onTap: () {
                            widget.searchController.clear();
                            widget.onClearSearch?.call();
                            widget.onSearchChanged('');
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(CupertinoIcons.xmark_circle_fill,
                                size: 20),
                          ),
                        ))
                      : null,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.isDarkTheme
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: context.borderColor),
                  ),
                  onChanged: widget.onSearchChanged,
                ),
              ),
              widget.navTrailing ?? const SizedBox.shrink(),
            ],
          ),
          if (filterActive)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 0,
                runSpacing: 8,
                children: widget.filterChips ?? [],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.exclamationmark_circle,
                size: 64, color: CupertinoColors.destructiveRed),
            const SizedBox(height: 16),
            Text(widget.errorMessage ?? 'An error occurred',
                textAlign: TextAlign.center),
            if (widget.onRetry != null) ...[
              const SizedBox(height: 16),
              CustomPointer(
                child: CupertinoButton.filled(
                  onPressed: widget.onRetry,
                  child: Text('retry'.tr()),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_resolveIcon(),
                size: 80, color: context.primaryColor.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              widget.emptyMessage,
              style: AppTypography.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.primaryTextColor),
              textAlign: TextAlign.center,
            ),
            if (widget.emptyActionLabel != null &&
                widget.onEmptyAction != null) ...[
              const SizedBox(height: 24),
              CustomPointer(
                child: CupertinoButton.filled(
                  sizeStyle: CupertinoButtonSize.medium,
                  onPressed: widget.onEmptyAction,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.add,
                          color: CupertinoColors.white),
                      const SizedBox(width: 8),
                      Text(widget.emptyActionLabel!),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${widget.totalCount} ${widget.countLabel}',
                style:
                    AppTypography.poppins(fontSize: 12, color: context.secondaryTextColor),
              ),
              const Spacer(),
              if (widget.isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CupertinoActivityIndicator(),
                ),
            ],
          ),
        ),
        Expanded(
          child: widget.contentBuilder(context, _scrollController),
        ),
      ],
    );
  }

  String get totalCount {
    if (widget.totalCount == 1) {
      final singular = widget.countLabel.replaceAll(RegExp(r's$'), '');
      return '1 $singular';
    }
    return '${widget.totalCount} ${widget.countLabel}';
  }
}
