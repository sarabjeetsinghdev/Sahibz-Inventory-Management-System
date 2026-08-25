import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sahibz_inventory/core/logger.dart';
import 'package:sahibz_inventory/core/constants.dart';
import 'package:sahibz_inventory/features/inventory/models/inventory_model.dart';
import 'package:sahibz_inventory/features/inventory/repositories/inventory_repository.dart';
import 'package:sahibz_inventory/features/audit_logs/repositories/audit_log_repository.dart';

class InventoryState {
  final List<InventoryTransactionModel> transactions;
  final List<StockSummaryModel> stockItems;
  final List<StockSummaryModel> lowStockItems;
  final List<StockSummaryModel> outOfStockItems;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalCount;
  final int pageSize;
  final String? filterProductId;
  final String? filterType;
  final String searchQuery;

  bool get hasMore => currentPage * pageSize < totalCount;
  bool get hasSearch => searchQuery.isNotEmpty;

  const InventoryState({
    this.transactions = const [],
    this.stockItems = const [],
    this.lowStockItems = const [],
    this.outOfStockItems = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalCount = 0,
    this.pageSize = AppConstants.defaultPageSize,
    this.filterProductId,
    this.filterType,
    this.searchQuery = '',
  });

  InventoryState copyWith({
    List<InventoryTransactionModel>? transactions,
    List<StockSummaryModel>? stockItems,
    List<StockSummaryModel>? lowStockItems,
    List<StockSummaryModel>? outOfStockItems,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalCount,
    int? pageSize,
    String? filterProductId,
    String? filterType,
    String? searchQuery,
    bool clearError = false,
  }) {
    return InventoryState(
      transactions: transactions ?? this.transactions,
      stockItems: stockItems ?? this.stockItems,
      lowStockItems: lowStockItems ?? this.lowStockItems,
      outOfStockItems: outOfStockItems ?? this.outOfStockItems,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      pageSize: pageSize ?? this.pageSize,
      filterProductId: filterProductId ?? this.filterProductId,
      filterType: filterType ?? this.filterType,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class InventoryNotifier extends StateNotifier<InventoryState> {
  final InventoryRepository _repository;
  final AuditLogRepository _auditLogRepo;

  InventoryNotifier(this._repository, this._auditLogRepo)
      : super(const InventoryState());

  Future<String?> stockIn({
    required String productId,
    required double quantity,
    double unitPrice = 0.0,
    String? reference,
    String? referenceType,
    String? notes,
    String? batchNumber,
    String? serialNumber,
    String? performedBy,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.stockIn(
      productId: productId,
      quantity: quantity,
      unitPrice: unitPrice,
      reference: reference,
      referenceType: referenceType,
      notes: notes,
      batchNumber: batchNumber,
      serialNumber: serialNumber,
      performedBy: performedBy,
    );

    state = state.copyWith(isLoading: false, clearError: true);

    if (result.isSuccess) {
      AppLogger.i('InventoryNotifier: stock in recorded');
      unawaited(_auditLogRepo.logAction(
        userId: 'admin',
        action: 'stock_in',
        entityType: 'inventory',
        entityId: result.value.id,
        newValues: result.value.toJson(),
      ));
      await fetchCurrentStock();
      return null;
    } else {
      final errorMsg = result.error.message;
      state = state.copyWith(error: errorMsg);
      AppLogger.e('InventoryNotifier: stock in failed - $errorMsg');
      return errorMsg;
    }
  }

  Future<String?> stockOut({
    required String productId,
    required double quantity,
    double unitPrice = 0.0,
    String? reference,
    String? referenceType,
    String? notes,
    String? batchNumber,
    String? serialNumber,
    String? performedBy,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.stockOut(
      productId: productId,
      quantity: quantity,
      unitPrice: unitPrice,
      reference: reference,
      referenceType: referenceType,
      notes: notes,
      batchNumber: batchNumber,
      serialNumber: serialNumber,
      performedBy: performedBy,
    );

    state = state.copyWith(isLoading: false, clearError: true);

    if (result.isSuccess) {
      AppLogger.i('InventoryNotifier: stock out recorded');
      unawaited(_auditLogRepo.logAction(
        userId: 'admin',
        action: 'stock_out',
        entityType: 'inventory',
        entityId: result.value.id,
        newValues: result.value.toJson(),
      ));
      await fetchCurrentStock();
      return null;
    } else {
      final errorMsg = result.error.message;
      state = state.copyWith(error: errorMsg);
      AppLogger.e('InventoryNotifier: stock out failed - $errorMsg');
      return errorMsg;
    }
  }

  Future<String?> adjustStock({
    required String productId,
    required double newQuantity,
    String? reason,
    String? performedBy,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.adjustStock(
      productId: productId,
      newQuantity: newQuantity,
      reason: reason,
      performedBy: performedBy,
    );

    state = state.copyWith(isLoading: false, clearError: true);

    if (result.isSuccess) {
      AppLogger.i('InventoryNotifier: stock adjusted');
      unawaited(_auditLogRepo.logAction(
        userId: 'admin',
        action: 'stock_adjust',
        entityType: 'inventory',
        entityId: result.value.id,
        newValues: result.value.toJson(),
      ));
      await fetchCurrentStock();
      return null;
    } else {
      final errorMsg = result.error.message;
      state = state.copyWith(error: errorMsg);
      AppLogger.e('InventoryNotifier: adjust stock failed - $errorMsg');
      return errorMsg;
    }
  }

  Future<String?> transferStock({
    required String productId,
    required double quantity,
    String? notes,
    String? performedBy,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.transferStock(
      productId: productId,
      quantity: quantity,
      notes: notes,
      performedBy: performedBy,
    );

    state = state.copyWith(isLoading: false, clearError: true);

    if (result.isSuccess) {
      AppLogger.i('InventoryNotifier: stock transferred');
      unawaited(_auditLogRepo.logAction(
        userId: 'admin',
        action: 'stock_transfer',
        entityType: 'inventory',
        details: 'Transferred product $productId qty: $quantity',
      ));
      await fetchCurrentStock();
      return null;
    } else {
      final errorMsg = result.error.message;
      state = state.copyWith(error: errorMsg);
      AppLogger.e('InventoryNotifier: transfer stock failed - $errorMsg');
      return errorMsg;
    }
  }

  Future<void> fetchTransactions({
    String? productId,
    String? type,
    bool refresh = false,
  }) async {
    if (state.isLoading) return;

    final page = refresh ? 1 : state.currentPage;
    state = state.copyWith(
      isLoading: true,
      filterProductId: productId ?? state.filterProductId,
      filterType: type ?? state.filterType,
      clearError: true,
    );

    final result = await _repository.getTransactionHistory(
      productId: state.filterProductId,
      type: state.filterType,
      page: page,
      pageSize: state.pageSize,
    );

    if (result.isSuccess) {
      final transactions = refresh || page == 1
          ? result.value
          : [...state.transactions, ...result.value];

      final countResult = await _repository.getTotalTransactionCount(
        productId: state.filterProductId,
        type: state.filterType,
      );

      state = state.copyWith(
        transactions: transactions,
        currentPage: page,
        totalCount: countResult.valueOrNull ?? result.value.length,
        isLoading: false,
        clearError: true,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error.message,
      );
    }
  }

  Future<void> fetchCurrentStock({
    bool refresh = false,
  }) async {
    if (state.isLoading) return;

    final page = refresh ? 1 : state.currentPage;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    final result = await _repository.getAllCurrentStock(
      searchQuery: state.hasSearch ? state.searchQuery : null,
      page: page,
      pageSize: state.pageSize,
    );

    if (result.isSuccess) {
      state = state.copyWith(
        stockItems: refresh || page == 1
            ? result.value
            : [...state.stockItems, ...result.value],
        totalCount: result.value.length,
        isLoading: false,
        clearError: true,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error.message,
      );
    }
  }

  Future<void> fetchLowStock() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.getLowStockItems();

    if (result.isSuccess) {
      state = state.copyWith(
        lowStockItems: result.value,
        isLoading: false,
        clearError: true,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error.message,
      );
    }
  }

  Future<void> fetchOutOfStock() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.getOutOfStockItems();

    if (result.isSuccess) {
      state = state.copyWith(
        outOfStockItems: result.value,
        isLoading: false,
        clearError: true,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error.message,
      );
    }
  }

  Future<void> search(String query) async {
    state = state.copyWith(
      searchQuery: query,
      currentPage: 1,
    );

    if (query.isEmpty) {
      state = state.copyWith(
        searchQuery: '',
        currentPage: 1,
      );
      await fetchCurrentStock(refresh: true);
      return;
    }

    await fetchCurrentStock(refresh: true);
  }

  Future<void> loadMoreTransactions() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(currentPage: state.currentPage + 1);
    await fetchTransactions();
  }

  Future<void> loadMoreStock() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(currentPage: state.currentPage + 1);
    await fetchCurrentStock();
  }

  void clearFilters() {
    state = state.copyWith(
      filterProductId: null,
      filterType: null,
      searchQuery: '',
      currentPage: 1,
    );
    fetchCurrentStock(refresh: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, InventoryState>((ref) {
  final repository = ref.watch(inventoryRepositoryProvider);
  final auditLogRepo = ref.read(auditLogRepositoryProvider);
  return InventoryNotifier(repository, auditLogRepo);
});
