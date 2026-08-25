import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sahibz_inventory/core/logger.dart';
import 'package:sahibz_inventory/features/dashboard/models/dashboard_models.dart';
import 'package:sahibz_inventory/features/dashboard/repositories/dashboard_repository.dart';

class DashboardState {
  final DashboardStats? stats;
  final List<SalesDataPoint> salesTrend;
  final List<PurchaseDataPoint> purchaseTrend;
  final List<InventoryDataPoint> inventoryTrend;
  final bool isLoading;
  final String? error;
  final bool isLoadingTrends;
  final String? trendsError;
  final DateTime lastRefreshed;
  final String period;

  DashboardState({
    this.stats,
    this.salesTrend = const [],
    this.purchaseTrend = const [],
    this.inventoryTrend = const [],
    this.isLoading = false,
    this.error,
    this.isLoadingTrends = false,
    this.trendsError,
    DateTime? lastRefreshed,
    this.period = 'daily',
  }) : lastRefreshed = lastRefreshed ?? DateTime(2000);

  bool get hasData => stats != null;
  bool get hasError => error != null;
  bool get hasTrendsError => trendsError != null;

  DashboardState copyWith({
    DashboardStats? stats,
    List<SalesDataPoint>? salesTrend,
    List<PurchaseDataPoint>? purchaseTrend,
    List<InventoryDataPoint>? inventoryTrend,
    bool? isLoading,
    String? error,
    bool? isLoadingTrends,
    String? trendsError,
    DateTime? lastRefreshed,
    String? period,
    bool clearError = false,
    bool clearTrendsError = false,
  }) {
    return DashboardState(
      stats: stats ?? this.stats,
      salesTrend: salesTrend ?? this.salesTrend,
      purchaseTrend: purchaseTrend ?? this.purchaseTrend,
      inventoryTrend: inventoryTrend ?? this.inventoryTrend,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isLoadingTrends: isLoadingTrends ?? this.isLoadingTrends,
      trendsError: clearTrendsError ? null : (trendsError ?? this.trendsError),
      lastRefreshed: lastRefreshed ?? DateTime.now(),
      period: period ?? this.period,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardRepository _repository;
  Timer? _autoRefreshTimer;

  DashboardNotifier(this._repository) : super(DashboardState());

  Future<void> loadDashboard() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.getDashboardStats();
    if (result.isSuccess) {
      state = state.copyWith(
        stats: result.value,
        isLoading: false,
        clearError: true,
        lastRefreshed: DateTime.now(),
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error.message,
      );
    }
  }

  Future<void> loadTrends() async {
    if (state.isLoadingTrends) return;
    state = state.copyWith(isLoadingTrends: true, clearTrendsError: true);

    final results = await Future.wait([
      _repository.getSalesTrend(period: state.period),
      _repository.getPurchaseTrend(period: state.period),
      _repository.getInventoryTrend(period: state.period),
    ]);

    String? error;
    List<SalesDataPoint> sales = state.salesTrend;
    List<PurchaseDataPoint> purchases = state.purchaseTrend;
    List<InventoryDataPoint> inventory = state.inventoryTrend;

    if (results[0].isSuccess) {
      sales = results[0].value as List<SalesDataPoint>;
    } else {
      error = results[0].error.message;
    }
    if (results[1].isSuccess) {
      purchases = results[1].value as List<PurchaseDataPoint>;
    } else {
      error ??= results[1].error.message;
    }
    if (results[2].isSuccess) {
      inventory = results[2].value as List<InventoryDataPoint>;
    } else {
      error ??= results[2].error.message;
    }

    state = state.copyWith(
      salesTrend: sales,
      purchaseTrend: purchases,
      inventoryTrend: inventory,
      isLoadingTrends: false,
      trendsError: error,
      clearTrendsError: error == null,
    );
  }

  Future<void> refresh() async {
    await Future.wait([loadDashboard(), loadTrends()]);
  }

  void setPeriod(String period) {
    if (period == state.period) return;
    state = state.copyWith(period: period);
    loadTrends();
  }

  void startAutoRefresh({Duration interval = const Duration(seconds: 30)}) {
    stopAutoRefresh();
    _autoRefreshTimer = Timer.periodic(interval, (_) {
      AppLogger.d('Dashboard auto-refresh triggered');
      refresh();
    });
  }

  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  final notifier = DashboardNotifier(repository);
  ref.onDispose(() => notifier.dispose());
  return notifier;
});
