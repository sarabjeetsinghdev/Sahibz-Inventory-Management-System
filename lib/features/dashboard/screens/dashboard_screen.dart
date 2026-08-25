import 'package:sahibz_inventory/features/dashboard/providers/dashboard_provider.dart';
import 'package:sahibz_inventory/features/settings/providers/settings_provider.dart';
import 'package:sahibz_inventory/features/dashboard/models/dashboard_models.dart';
import 'package:sahibz_inventory/features/dashboard/widgets/dashboard_chart.dart';
import 'package:sahibz_inventory/features/dashboard/widgets/stat_card.dart';
import 'package:sahibz_inventory/shared/widgets/section_title.dart';
import 'package:sahibz_inventory/shared/custom_mouse_pointer.dart';
import 'package:sahibz_inventory/shared/widgets/error_state.dart';
import 'package:sahibz_inventory/themes/app_typography.dart';
import 'package:sahibz_inventory/shared/item_selector.dart';
import 'package:sahibz_inventory/shared/custom_modal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sahibz_inventory/shared/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final bool showAppBar;

  const DashboardScreen({super.key, this.showAppBar = true});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(dashboardProvider.notifier);
      notifier.refresh();
      notifier.startAutoRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final currency = ref.watch(settingsProvider).settings.currency;
    final size = MediaQuery.of(context).size;
    final crossAxisCount = size.width >= 1200 ? 3 : (size.width >= 600 ? 2 : 1);
    final chartCrossAxisCount = size.width >= 900 ? 2 : 1;

    return CupertinoPageScaffold(
      navigationBar: widget.showAppBar
          ? CupertinoNavigationBar(
              middle: Text('dashboard'.tr()),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPeriodDropdown(state),
                  if (state.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CupertinoActivityIndicator()),
                    ),
                  CustomPointer(
                      child: GestureDetector(
                    onTap: () => ref.read(dashboardProvider.notifier).refresh(),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(CupertinoIcons.refresh, size: 24),
                    ),
                  )),
                ],
              ),
            )
          : null,
      child: !state.hasData
          ? (state.isLoading
              ? _buildSkeletonLoading()
              : state.hasError
                  ? ErrorState(
                      message: state.error ?? 'Something went wrong',
                      onRetry: () =>
                          ref.read(dashboardProvider.notifier).refresh())
                  : _buildSkeletonLoading())
          : _buildMainContent(
              state, crossAxisCount, chartCrossAxisCount, currency),
    );
  }

  Widget _buildPeriodDropdown(DashboardState state) {
    final labels = <String, String>{
      'daily': 'Daily',
      'weekly': 'Weekly',
      'monthly': 'Monthly'
    };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.borderColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomPointer(
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _showPeriodPicker(state),
          child: Text(
            labels[state.period] ?? state.period,
            style: AppTypography.poppins(fontSize: 13),
          ),
        ),
      ),
    );
  }

  void _showPeriodPicker(DashboardState state) {
    final periods = ['daily', 'weekly', 'monthly'];

    showCustomModal(
      context: context,
      builder: (_) => ItemSelector(
        items: periods,
        labels:
            periods.map((p) => p[0].toUpperCase() + p.substring(1)).toList(),
        initialValue: state.period,
        onSelected: (value) {
          ref.read(dashboardProvider.notifier).setPeriod(value);
        },
      ),
    );
  }

  Widget _buildMainContent(DashboardState state, int crossAxisCount,
      int chartColumns, String currency) {
    final stats = state.stats!;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(stats, currency),
                const SizedBox(height: 20),
                SectionTitle(
                    title: 'overview'.tr(),
                    icon: CupertinoIcons.square_grid_2x2),
                const SizedBox(height: 12),
                _buildOverviewGrid(stats, crossAxisCount),
                const SizedBox(height: 24),
                SectionTitle(
                    title: 'sales_purchases'.tr(),
                    icon: CupertinoIcons.chart_bar_alt_fill),
                const SizedBox(height: 12),
                _buildSalesPurchasesGrid(stats, crossAxisCount),
                const SizedBox(height: 24),
                const SectionTitle(
                    title: 'Stock Alerts',
                    icon: CupertinoIcons.exclamationmark_triangle),
                const SizedBox(height: 12),
                _buildStockAlertsGrid(stats),
                const SizedBox(height: 24),
                SectionTitle(
                    title: 'trends'.tr(),
                    icon: CupertinoIcons.chart_bar_alt_fill),
                const SizedBox(height: 12),
                _buildTrends(state, chartColumns),
                const SizedBox(height: 24),
                _buildFooter(state),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(DashboardStats stats, String currency) {
    final now = DateTime.now();
    final dateStr = DateFormat('dd MMMM yyyy').format(now);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.primaryColor.withValues(alpha: 0.15),
            context.primaryColor.withValues(alpha: 0.05)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome to SahibZ',
                    style: AppTypography.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: context.primaryTextColor)),
                const SizedBox(height: 4),
                Text(dateStr,
                    style: AppTypography.poppins(
                        fontSize: 14,
                        color:
                            context.secondaryTextColor.withValues(alpha: 0.7))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: context.primaryTextColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              currency,
              style: AppTypography.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.primaryTextColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewGrid(DashboardStats stats, int crossAxisCount) {
    final cards = <Widget>[
      StatCard(
        title: 'Total Products',
        value: stats.totalProducts,
        icon: CupertinoIcons.tray_full,
        color: CupertinoColors.systemBlue,
        onTap: () {},
      ),
      StatCard(
        title: 'categories'.tr(),
        value: stats.totalCategories,
        icon: CupertinoIcons.folder,
        color: CupertinoColors.systemTeal,
        onTap: () {},
      ),
      StatCard(
        title: 'suppliers'.tr(),
        value: stats.totalSuppliers,
        icon: CupertinoIcons.car,
        color: CupertinoColors.systemGreen,
        onTap: () {},
      ),
      StatCard(
        title: 'customers'.tr(),
        value: stats.totalCustomers,
        icon: CupertinoIcons.person_2,
        color: const Color(0xFF009688),
        onTap: () {},
      ),
      StatCard(
        title: 'inventory_value'.tr(),
        value: stats.inventoryValue,
        icon: CupertinoIcons.money_dollar,
        color: const Color(0xFF673AB7),
        isCurrency: true,
        onTap: () {},
      ),
    ];

    return _responsiveGrid(cards, crossAxisCount);
  }

  Widget _buildSalesPurchasesGrid(DashboardStats stats, int crossAxisCount) {
    final cards = <Widget>[
      StatCard(
        title: 'today_sales'.tr(),
        value: stats.todaySales,
        icon: CupertinoIcons.cart,
        color: CupertinoColors.systemGreen,
        isCurrency: true,
      ),
      StatCard(
        title: 'monthly_sales'.tr(),
        value: stats.monthlySales,
        icon: CupertinoIcons.chart_bar_alt_fill,
        color: const Color(0xFF2E7D32),
        isCurrency: true,
      ),
      StatCard(
        title: 'today_purchases'.tr(),
        value: stats.todayPurchases,
        icon: CupertinoIcons.doc_text,
        color: CupertinoColors.systemOrange,
        isCurrency: true,
      ),
      StatCard(
        title: 'monthly_purchases'.tr(),
        value: stats.monthlyPurchases,
        icon: CupertinoIcons.bag,
        color: const Color(0xFFE65100),
        isCurrency: true,
      ),
    ];

    return _responsiveGrid(cards, crossAxisCount);
  }

  Widget _buildStockAlertsGrid(DashboardStats stats) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Low Stock Items',
            value: stats.lowStockProducts,
            icon: CupertinoIcons.tray_full,
            color: const Color(0xFFFFA000),
            backgroundColor: const Color(0xFFFFC107).withValues(alpha: 0.05),
            subtitle:
                stats.lowStockProducts > 0 ? 'Needs reordering' : 'All good',
            onTap: () => context.push('/inventory?filter=low_stock'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            title: 'out_of_stock'.tr(),
            value: stats.outOfStockProducts,
            icon: CupertinoIcons.xmark_circle_fill,
            color: const Color(0xFFD32F2F),
            backgroundColor: const Color(0xFFD32F2F).withValues(alpha: 0.05),
            subtitle: stats.outOfStockProducts > 0
                ? 'Requires attention'
                : 'All stocked',
          ),
        ),
      ],
    );
  }

  Widget _buildTrends(DashboardState state, int chartColumns) {
    if (state.isLoadingTrends) {
      return const SizedBox(
        height: 320,
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    if (state.hasTrendsError) {
      return _buildTrendsError(state);
    }

    return _responsiveGrid(
      [
        DashboardChart(
          title: 'sales_trend'.tr(),
          spots: state.salesTrend
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.amount))
              .toList(),
          lineColor: CupertinoColors.systemGreen,
          isCurrency: true,
          bottomLabelFormatter: (value) {
            final idx = value.toInt();
            if (idx >= 0 && idx < state.salesTrend.length) {
              return DateFormat('d/M').format(state.salesTrend[idx].date);
            }
            return null;
          },
        ),
        DashboardChart(
          title: 'purchase_trend'.tr(),
          spots: state.purchaseTrend
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.amount))
              .toList(),
          lineColor: CupertinoColors.systemOrange,
          isCurrency: true,
          bottomLabelFormatter: (value) {
            final idx = value.toInt();
            if (idx >= 0 && idx < state.purchaseTrend.length) {
              return DateFormat('d/M').format(state.purchaseTrend[idx].date);
            }
            return null;
          },
        ),
        DashboardChart(
          title: 'Inventory Movement',
          spots: state.inventoryTrend
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.quantity))
              .toList(),
          lineColor: CupertinoColors.systemBlue,
          isCurrency: false,
          bottomLabelFormatter: (value) {
            final idx = value.toInt();
            if (idx >= 0 && idx < state.inventoryTrend.length) {
              return DateFormat('d/M').format(state.inventoryTrend[idx].date);
            }
            return null;
          },
        ),
      ],
      chartColumns,
    );
  }

  Widget _buildFooter(DashboardState state) {
    final now = state.lastRefreshed;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(CupertinoIcons.clock,
            size: 14, color: context.secondaryTextColor.withValues(alpha: 0.5)),
        const SizedBox(width: 6),
        Text(
          'Last updated: ${DateFormat('dd MMM yyyy, HH:mm').format(now)}',
          style: AppTypography.poppins(
              fontSize: 12,
              color: context.secondaryTextColor.withValues(alpha: 0.5)),
        ),
      ],
    );
  }

  Widget _responsiveGrid(List<Widget> items, int crossAxisCount) {
    assert(crossAxisCount >= 1);
    if (crossAxisCount == 1) {
      return Column(
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: item,
                ))
            .toList(),
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += crossAxisCount) {
      final rowItems = items.sublist(
          i,
          (i + crossAxisCount < items.length)
              ? i + crossAxisCount
              : items.length);
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: rowItems
                .map((item) => Expanded(
                        child: Padding(
                      padding: EdgeInsets.only(
                          left: rowItems.indexOf(item) > 0 ? 6 : 0,
                          right: rowItems.indexOf(item) < rowItems.length - 1
                              ? 6
                              : 0),
                      child: item,
                    )))
                .toList(),
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSkeletonBlock(80, double.infinity),
          const SizedBox(height: 24),
          SectionTitle(
              title: 'overview'.tr(), icon: CupertinoIcons.square_grid_2x2),
          const SizedBox(height: 12),
          _buildSkeletonGrid(6),
          const SizedBox(height: 24),
          SectionTitle(
              title: 'sales_purchases'.tr(),
              icon: CupertinoIcons.chart_bar_alt_fill),
          const SizedBox(height: 12),
          _buildSkeletonGrid(4),
          const SizedBox(height: 24),
          SectionTitle(
              title: 'trends'.tr(), icon: CupertinoIcons.chart_bar_alt_fill),
          const SizedBox(height: 12),
          _buildSkeletonBlock(300, double.infinity),
        ],
      ),
    );
  }

  Widget _buildSkeletonBlock(double height, double width) {
    return Container(
      height: height,
      width: width,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.borderColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Icon(CupertinoIcons.hourglass,
            color: context.secondaryTextColor.withValues(alpha: 0.2)),
      ),
    );
  }

  Widget _buildSkeletonGrid(int count) {
    return Column(
      children: List.generate(
        (count / 2).ceil(),
        (rowIndex) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: List.generate(
              count - rowIndex * 2 >= 2 ? 2 : 1,
              (colIndex) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      left: colIndex > 0 ? 6 : 0, right: colIndex < 1 ? 6 : 0),
                  child: _buildSkeletonBlock(120, double.infinity),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendsError(DashboardState state) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: CupertinoColors.systemRed.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.chart_bar_alt_fill,
                size: 40,
                color: CupertinoColors.systemRed.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            Text('Failed to load trends',
                style: AppTypography.poppins(
                    fontSize: 13, color: CupertinoColors.systemRed)),
          ],
        ),
      ),
    );
  }
}
