import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sahibz_inventory/core/logger.dart';
import 'package:sahibz_inventory/core/constants.dart';
import 'package:sahibz_inventory/features/purchases/models/purchase_model.dart';
import 'package:sahibz_inventory/features/purchases/repositories/purchase_repository.dart';
import 'package:sahibz_inventory/features/audit_logs/repositories/audit_log_repository.dart';

class PurchaseState {
  final List<PurchaseModel> purchases;
  final PurchaseModel? selectedPurchase;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalCount;
  final int pageSize;
  final String searchQuery;
  final String? filterStatus;
  final String? filterSupplierId;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;
  final String sortBy;
  final bool sortAscending;

  bool get hasMore => currentPage * pageSize < totalCount;
  bool get hasSearch => searchQuery.isNotEmpty;

  const PurchaseState({
    this.purchases = const [],
    this.selectedPurchase,
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalCount = 0,
    this.pageSize = AppConstants.defaultPageSize,
    this.searchQuery = '',
    this.filterStatus,
    this.filterSupplierId,
    this.filterStartDate,
    this.filterEndDate,
    this.sortBy = 'createdAt',
    this.sortAscending = false,
  });

  static const _sentinel = Object();

  PurchaseState copyWith({
    List<PurchaseModel>? purchases,
    PurchaseModel? selectedPurchase,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalCount,
    int? pageSize,
    String? searchQuery,
    Object? filterStatus = _sentinel,
    Object? filterSupplierId = _sentinel,
    Object? filterStartDate = _sentinel,
    Object? filterEndDate = _sentinel,
    String? sortBy,
    bool? sortAscending,
    bool clearError = false,
  }) {
    return PurchaseState(
      purchases: purchases ?? this.purchases,
      selectedPurchase: selectedPurchase ?? this.selectedPurchase,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      pageSize: pageSize ?? this.pageSize,
      searchQuery: searchQuery ?? this.searchQuery,
      filterStatus: identical(filterStatus, _sentinel)
          ? this.filterStatus
          : filterStatus as String?,
      filterSupplierId: identical(filterSupplierId, _sentinel)
          ? this.filterSupplierId
          : filterSupplierId as String?,
      filterStartDate: identical(filterStartDate, _sentinel)
          ? this.filterStartDate
          : filterStartDate as DateTime?,
      filterEndDate: identical(filterEndDate, _sentinel)
          ? this.filterEndDate
          : filterEndDate as DateTime?,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}

class PurchaseNotifier extends StateNotifier<PurchaseState> {
  final PurchaseRepository _repository;
  final AuditLogRepository _auditLogRepo;

  PurchaseNotifier(this._repository, this._auditLogRepo)
      : super(const PurchaseState());

  Future<void> fetchAll({bool refresh = false}) async {
    if (state.isLoading) return;

    final page = refresh ? 1 : state.currentPage;
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.getAll(
      page: page,
      pageSize: state.pageSize,
      status: state.filterStatus,
      supplierId: state.filterSupplierId,
      startDate: state.filterStartDate,
      endDate: state.filterEndDate,
      sortBy: state.sortBy,
      sortAscending: state.sortAscending,
    );

    if (result.isSuccess) {
      final purchases = refresh || page == 1
          ? result.value
          : [...state.purchases, ...result.value];

      final countResult = await _repository.getTotalCount(
        status: state.filterStatus,
        supplierId: state.filterSupplierId,
        startDate: state.filterStartDate,
        endDate: state.filterEndDate,
      );

      state = state.copyWith(
        purchases: purchases,
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

  Future<void> fetchById(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.getById(id);
    if (result.isSuccess) {
      state = state.copyWith(
        selectedPurchase: result.value,
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

  Future<String?> create({
    required String supplierId,
    double subtotal = 0.0,
    double taxAmount = 0.0,
    double discountAmount = 0.0,
    double shippingAmount = 0.0,
    double totalAmount = 0.0,
    String? notes,
    String? billingAddress,
    String? shippingAddress,
    String? paymentMethod,
    String paymentStatus = 'unpaid',
    required String createdBy,
    DateTime? orderDate,
    DateTime? expectedDelivery,
    required List<Map<String, dynamic>> items,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.create(
      supplierId: supplierId,
      subtotal: subtotal,
      taxAmount: taxAmount,
      discountAmount: discountAmount,
      shippingAmount: shippingAmount,
      totalAmount: totalAmount,
      notes: notes,
      billingAddress: billingAddress,
      shippingAddress: shippingAddress,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      createdBy: createdBy,
      orderDate: orderDate,
      expectedDelivery: expectedDelivery,
      items: items,
    );

    state = state.copyWith(isLoading: false, clearError: true);

    if (result.isSuccess) {
      AppLogger.i('PurchaseNotifier: purchase created successfully');
      unawaited(_auditLogRepo.logAction(
        userId: 'admin',
        action: 'create',
        entityType: 'purchase',
        entityId: result.value.id,
        newValues: result.value.toJson(),
      ));
      await fetchAll(refresh: true);
      return null;
    } else {
      final errorMsg = result.error.message;
      state = state.copyWith(error: errorMsg);
      AppLogger.e('PurchaseNotifier: create failed - $errorMsg');
      return errorMsg;
    }
  }

  Future<String?> update({
    required String id,
    String? supplierId,
    double? subtotal,
    double? taxAmount,
    double? discountAmount,
    double? shippingAmount,
    double? totalAmount,
    String? notes,
    String? billingAddress,
    String? shippingAddress,
    String? paymentMethod,
    String? paymentStatus,
    DateTime? expectedDelivery,
    List<Map<String, dynamic>>? items,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.update(
      id: id,
      supplierId: supplierId,
      subtotal: subtotal,
      taxAmount: taxAmount,
      discountAmount: discountAmount,
      shippingAmount: shippingAmount,
      totalAmount: totalAmount,
      notes: notes,
      billingAddress: billingAddress,
      shippingAddress: shippingAddress,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      expectedDelivery: expectedDelivery,
      items: items,
    );

    state = state.copyWith(isLoading: false, clearError: true);

    if (result.isSuccess) {
      AppLogger.i('PurchaseNotifier: purchase updated successfully');
      unawaited(_auditLogRepo.logAction(
        userId: 'admin',
        action: 'update',
        entityType: 'purchase',
        entityId: result.value.id,
        newValues: result.value.toJson(),
      ));
      await fetchAll(refresh: true);
      return null;
    } else {
      final errorMsg = result.error.message;
      state = state.copyWith(error: errorMsg);
      AppLogger.e('PurchaseNotifier: update failed - $errorMsg');
      return errorMsg;
    }
  }

  Future<String?> delete(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.delete(id);

    state = state.copyWith(isLoading: false, clearError: true);

    if (result.isSuccess) {
      AppLogger.i('PurchaseNotifier: purchase deleted successfully');
      unawaited(_auditLogRepo.logAction(
        userId: 'admin',
        action: 'delete',
        entityType: 'purchase',
        entityId: id,
        details: 'Deleted purchase',
      ));
      await fetchAll(refresh: true);
      return null;
    } else {
      final errorMsg = result.error.message;
      state = state.copyWith(error: errorMsg);
      AppLogger.e('PurchaseNotifier: delete failed - $errorMsg');
      return errorMsg;
    }
  }

  Future<String?> approve(String id, String approvedBy) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.approve(id, approvedBy);

    state = state.copyWith(isLoading: false, clearError: true);

    if (result.isSuccess) {
      AppLogger.i('PurchaseNotifier: purchase approved successfully');
      unawaited(_auditLogRepo.logAction(
        userId: 'admin',
        action: 'update',
        entityType: 'purchase',
        entityId: id,
        details: 'Purchase approved',
      ));
      await fetchAll(refresh: true);
      return null;
    } else {
      final errorMsg = result.error.message;
      state = state.copyWith(error: errorMsg);
      AppLogger.e('PurchaseNotifier: approve failed - $errorMsg');
      return errorMsg;
    }
  }

  Future<String?> receive(String id,
      {required List<ReceiptLine> lines, String? performedBy}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.receive(id, lines: lines, performedBy: performedBy);

    state = state.copyWith(isLoading: false, clearError: true);

    if (result.isSuccess) {
      AppLogger.i('PurchaseNotifier: purchase receipt recorded');
      unawaited(_auditLogRepo.logAction(
        userId: 'admin',
        action: 'update',
        entityType: 'purchase',
        entityId: id,
        details: 'Purchase received (${result.value.status})',
      ));
      await fetchAll(refresh: true);
      return null;
    } else {
      final errorMsg = result.error.message;
      state = state.copyWith(error: errorMsg);
      AppLogger.e('PurchaseNotifier: receive failed - $errorMsg');
      return errorMsg;
    }
  }

  Future<String?> closeOrder(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.closeOrder(id);

    state = state.copyWith(isLoading: false, clearError: true);

    if (result.isSuccess) {
      AppLogger.i('PurchaseNotifier: purchase closed');
      unawaited(_auditLogRepo.logAction(
        userId: 'admin',
        action: 'update',
        entityType: 'purchase',
        entityId: id,
        details: 'Purchase order closed with shortfall',
      ));
      await fetchAll(refresh: true);
      return null;
    } else {
      final errorMsg = result.error.message;
      state = state.copyWith(error: errorMsg);
      AppLogger.e('PurchaseNotifier: close failed - $errorMsg');
      return errorMsg;
    }
  }

  Future<String?> cancel(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.cancel(id);

    state = state.copyWith(isLoading: false, clearError: true);

    if (result.isSuccess) {
      AppLogger.i('PurchaseNotifier: purchase cancelled successfully');
      unawaited(_auditLogRepo.logAction(
        userId: 'admin',
        action: 'update',
        entityType: 'purchase',
        entityId: id,
        details: 'Purchase cancelled',
      ));
      await fetchAll(refresh: true);
      return null;
    } else {
      final errorMsg = result.error.message;
      state = state.copyWith(error: errorMsg);
      AppLogger.e('PurchaseNotifier: cancel failed - $errorMsg');
      return errorMsg;
    }
  }

  Future<void> search(String query) async {
    state = state.copyWith(
      searchQuery: query,
      currentPage: 1,
      isLoading: true,
      clearError: true,
    );

    if (query.isEmpty) {
      state = state.copyWith(
        searchQuery: '',
        currentPage: 1,
        isLoading: false,
        clearError: true,
      );
      await fetchAll(refresh: true);
      return;
    }

    final result =
        await _repository.search(query, page: 1, pageSize: state.pageSize);

    if (result.isSuccess) {
      state = state.copyWith(
        purchases: result.value,
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

  Future<void> applyFilters({
    String? status,
    String? supplierId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = state.copyWith(
      filterStatus: status,
      filterSupplierId: supplierId,
      filterStartDate: startDate,
      filterEndDate: endDate,
      currentPage: 1,
    );
    await fetchAll(refresh: true);
  }

  void setSortBy(String column) {
    final ascending = state.sortBy == column ? !state.sortAscending : false;
    state = state.copyWith(
        sortBy: column, sortAscending: ascending, currentPage: 1);
    fetchAll(refresh: true);
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(currentPage: state.currentPage + 1);
    await fetchAll();
  }

  void clearFilters() {
    state = state.copyWith(
      filterStatus: null,
      filterSupplierId: null,
      filterStartDate: null,
      filterEndDate: null,
      searchQuery: '',
      currentPage: 1,
    );
    fetchAll(refresh: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final purchaseProvider =
    StateNotifierProvider<PurchaseNotifier, PurchaseState>((ref) {
  final repository = ref.watch(purchaseRepositoryProvider);
  final auditLogRepo = ref.read(auditLogRepositoryProvider);
  return PurchaseNotifier(repository, auditLogRepo);
});
