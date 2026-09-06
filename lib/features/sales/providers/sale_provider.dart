import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sahibz_inventory/core/logger.dart';
import 'package:sahibz_inventory/core/constants.dart';
import 'package:sahibz_inventory/features/sales/models/sale_model.dart';
import 'package:sahibz_inventory/features/sales/repositories/sale_repository.dart';
import 'package:sahibz_inventory/features/audit_logs/repositories/audit_log_repository.dart';

class SaleState {
  final List<SaleModel> sales;
  final SaleModel? selectedSale;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalCount;
  final int pageSize;
  final String searchQuery;
  final String? filterStatus;
  final String? filterPaymentStatus;
  final String? filterCustomerId;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;
  final String sortBy;
  final bool sortAscending;

  bool get hasMore => currentPage * pageSize < totalCount;
  bool get hasSearch => searchQuery.isNotEmpty;

  const SaleState({
    this.sales = const [],
    this.selectedSale,
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalCount = 0,
    this.pageSize = AppConstants.defaultPageSize,
    this.searchQuery = '',
    this.filterStatus,
    this.filterPaymentStatus,
    this.filterCustomerId,
    this.filterStartDate,
    this.filterEndDate,
    this.sortBy = 'createdAt',
    this.sortAscending = false,
  });

  static const _sentinel = Object();

  SaleState copyWith({
    List<SaleModel>? sales,
    SaleModel? selectedSale,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalCount,
    int? pageSize,
    String? searchQuery,
    Object? filterStatus = _sentinel,
    Object? filterPaymentStatus = _sentinel,
    Object? filterCustomerId = _sentinel,
    Object? filterStartDate = _sentinel,
    Object? filterEndDate = _sentinel,
    String? sortBy,
    bool? sortAscending,
    bool clearError = false,
  }) {
    return SaleState(
      sales: sales ?? this.sales,
      selectedSale: selectedSale ?? this.selectedSale,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      pageSize: pageSize ?? this.pageSize,
      searchQuery: searchQuery ?? this.searchQuery,
      filterStatus: identical(filterStatus, _sentinel)
          ? this.filterStatus
          : filterStatus as String?,
      filterPaymentStatus: identical(filterPaymentStatus, _sentinel)
          ? this.filterPaymentStatus
          : filterPaymentStatus as String?,
      filterCustomerId: identical(filterCustomerId, _sentinel)
          ? this.filterCustomerId
          : filterCustomerId as String?,
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

class SaleNotifier extends StateNotifier<SaleState> {
  final SaleRepository _repository;
  final AuditLogRepository _auditLogRepo;

  SaleNotifier(this._repository, this._auditLogRepo) : super(const SaleState());

  Future<void> fetchAll({bool refresh = false}) async {
    if (state.isLoading) return;

    final page = refresh ? 1 : state.currentPage;
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.getAll(
      page: page,
      pageSize: state.pageSize,
      status: state.filterStatus,
      paymentStatus: state.filterPaymentStatus,
      customerId: state.filterCustomerId,
      startDate: state.filterStartDate,
      endDate: state.filterEndDate,
      sortBy: state.sortBy,
      sortAscending: state.sortAscending,
    );

    if (result.isSuccess) {
      final sales = refresh || page == 1
          ? result.value
          : [...state.sales, ...result.value];

      final countResult = await _repository.getTotalCount(
        status: state.filterStatus,
        paymentStatus: state.filterPaymentStatus,
        customerId: state.filterCustomerId,
        startDate: state.filterStartDate,
        endDate: state.filterEndDate,
      );

      state = state.copyWith(
        sales: sales,
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
        selectedSale: result.value,
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
    String? customerId,
    double subtotal = 0.0,
    double taxAmount = 0.0,
    double discountAmount = 0.0,
    double totalAmount = 0.0,
    double paidAmount = 0.0,
    String? paymentMethod,
    String paymentStatus = 'unpaid',
    String? notes,
    String? billingAddress,
    String? shippingAddress,
    required String createdBy,
    DateTime? saleDate,
    required List<Map<String, dynamic>> items,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.create(
      customerId: customerId,
      subtotal: subtotal,
      taxAmount: taxAmount,
      discountAmount: discountAmount,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      notes: notes,
      billingAddress: billingAddress,
      shippingAddress: shippingAddress,
      createdBy: createdBy,
      saleDate: saleDate,
      items: items,
    );

    state = state.copyWith(isLoading: false, clearError: true);

    if (result.isSuccess) {
      AppLogger.i('SaleNotifier: sale created successfully');
      unawaited(_auditLogRepo.logAction(
        userId: 'admin',
        action: 'create',
        entityType: 'sale',
        entityId: result.value.id,
        newValues: result.value.toJson(),
      ));
      await fetchAll(refresh: true);
      return null;
    } else {
      final errorMsg = result.error.message;
      state = state.copyWith(error: errorMsg);
      AppLogger.e('SaleNotifier: create failed - $errorMsg');
      return errorMsg;
    }
  }

  Future<String?> update({
    required String id,
    String? customerId,
    double? subtotal,
    double? taxAmount,
    double? discountAmount,
    double? totalAmount,
    String? paymentMethod,
    String? notes,
    String? billingAddress,
    String? shippingAddress,
    DateTime? saleDate,
    List<Map<String, dynamic>>? items,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.update(
      id: id,
      customerId: customerId,
      subtotal: subtotal,
      taxAmount: taxAmount,
      discountAmount: discountAmount,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      notes: notes,
      billingAddress: billingAddress,
      shippingAddress: shippingAddress,
      saleDate: saleDate,
      items: items,
    );

    state = state.copyWith(isLoading: false, clearError: true);

    if (result.isSuccess) {
      AppLogger.i('SaleNotifier: sale updated successfully');
      unawaited(_auditLogRepo.logAction(
        userId: 'admin',
        action: 'update',
        entityType: 'sale',
        entityId: result.value.id,
        newValues: result.value.toJson(),
      ));
      await fetchAll(refresh: true);
      return null;
    } else {
      final errorMsg = result.error.message;
      state = state.copyWith(error: errorMsg);
      AppLogger.e('SaleNotifier: update failed - $errorMsg');
      return errorMsg;
    }
  }

  Future<String?> delete(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.delete(id);

    state = state.copyWith(isLoading: false, clearError: true);

    if (result.isSuccess) {
      AppLogger.i('SaleNotifier: sale deleted successfully');
      unawaited(_auditLogRepo.logAction(
        userId: 'admin',
        action: 'delete',
        entityType: 'sale',
        entityId: id,
        details: 'Deleted sale',
      ));
      await fetchAll(refresh: true);
      return null;
    } else {
      final errorMsg = result.error.message;
      state = state.copyWith(error: errorMsg);
      AppLogger.e('SaleNotifier: delete failed - $errorMsg');
      return errorMsg;
    }
  }

  Future<String?> updatePayment({
    required String id,
    required double paidAmount,
    String? paymentMethod,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.updatePayment(
      id: id,
      paidAmount: paidAmount,
      paymentMethod: paymentMethod,
    );

    state = state.copyWith(isLoading: false, clearError: true);

    if (result.isSuccess) {
      AppLogger.i('SaleNotifier: payment updated successfully');
      unawaited(_auditLogRepo.logAction(
        userId: 'admin',
        action: 'update',
        entityType: 'sale',
        entityId: result.value.id,
        newValues: result.value.toJson(),
        details: 'Payment updated',
      ));
      await fetchAll(refresh: true);
      return null;
    } else {
      final errorMsg = result.error.message;
      state = state.copyWith(error: errorMsg);
      AppLogger.e('SaleNotifier: payment update failed - $errorMsg');
      return errorMsg;
    }
  }

  Future<String?> complete(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.complete(id);

    state = state.copyWith(isLoading: false, clearError: true);

    if (result.isSuccess) {
      AppLogger.i('SaleNotifier: sale completed successfully');
      unawaited(_auditLogRepo.logAction(
        userId: 'admin',
        action: 'update',
        entityType: 'sale',
        entityId: id,
        details: 'Sale completed',
      ));
      await fetchAll(refresh: true);
      return null;
    } else {
      final errorMsg = result.error.message;
      state = state.copyWith(error: errorMsg);
      AppLogger.e('SaleNotifier: complete failed - $errorMsg');
      return errorMsg;
    }
  }

  Future<String?> cancel(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.cancel(id);

    state = state.copyWith(isLoading: false, clearError: true);

    if (result.isSuccess) {
      AppLogger.i('SaleNotifier: sale cancelled successfully');
      unawaited(_auditLogRepo.logAction(
        userId: 'admin',
        action: 'update',
        entityType: 'sale',
        entityId: id,
        details: 'Sale cancelled',
      ));
      await fetchAll(refresh: true);
      return null;
    } else {
      final errorMsg = result.error.message;
      state = state.copyWith(error: errorMsg);
      AppLogger.e('SaleNotifier: cancel failed - $errorMsg');
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
        sales: result.value,
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
    String? paymentStatus,
    String? customerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = state.copyWith(
      filterStatus: status,
      filterPaymentStatus: paymentStatus,
      filterCustomerId: customerId,
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
      filterPaymentStatus: null,
      filterCustomerId: null,
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

final saleProvider = StateNotifierProvider<SaleNotifier, SaleState>((ref) {
  final repository = ref.watch(saleRepositoryProvider);
  final auditLogRepo = ref.read(auditLogRepositoryProvider);
  return SaleNotifier(repository, auditLogRepo);
});
