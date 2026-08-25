import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sahibz_inventory/core/logger.dart';
import 'package:sahibz_inventory/core/constants.dart';
import 'package:sahibz_inventory/features/suppliers/models/supplier_model.dart';
import 'package:sahibz_inventory/features/suppliers/repositories/supplier_repository.dart';
import 'package:sahibz_inventory/features/audit_logs/repositories/audit_log_repository.dart';

class SupplierState {
  final List<SupplierModel> suppliers;
  final SupplierModel? selectedSupplier;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalCount;
  final int pageSize;
  final String searchQuery;
  final String? filterStatus;
  final String sortBy;
  final bool sortAscending;

  bool get hasMore => currentPage * pageSize < totalCount;
  bool get hasSearch => searchQuery.isNotEmpty;

  const SupplierState({
    this.suppliers = const [],
    this.selectedSupplier,
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalCount = 0,
    this.pageSize = AppConstants.defaultPageSize,
    this.searchQuery = '',
    this.filterStatus,
    this.sortBy = 'createdAt',
    this.sortAscending = false,
  });

  static const _sentinel = Object();

  SupplierState copyWith({
    List<SupplierModel>? suppliers,
    SupplierModel? selectedSupplier,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalCount,
    int? pageSize,
    String? searchQuery,
    Object? filterStatus = _sentinel,
    String? sortBy,
    bool? sortAscending,
    bool clearError = false,
  }) {
    return SupplierState(
      suppliers: suppliers ?? this.suppliers,
      selectedSupplier: selectedSupplier ?? this.selectedSupplier,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      pageSize: pageSize ?? this.pageSize,
      searchQuery: searchQuery ?? this.searchQuery,
      filterStatus: identical(filterStatus, _sentinel)
          ? this.filterStatus
          : filterStatus as String?,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}

class SupplierNotifier extends StateNotifier<SupplierState> {
  final SupplierRepository _repository;
  final AuditLogRepository _auditLogRepo;

  SupplierNotifier(this._repository, this._auditLogRepo) : super(const SupplierState());

  Future<void> fetchAll({bool refresh = false}) async {
    if (state.isLoading) return;

    final page = refresh ? 1 : state.currentPage;
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.getAll(
      page: page,
      pageSize: state.pageSize,
      status: state.filterStatus,
      sortBy: state.sortBy,
      sortAscending: state.sortAscending,
    );

    if (result.isSuccess) {
      final suppliers = refresh || page == 1
          ? result.value
          : [...state.suppliers, ...result.value];

      final countResult = await _repository.getTotalCount(
        status: state.filterStatus,
      );

      state = state.copyWith(
        suppliers: suppliers,
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
        selectedSupplier: result.value,
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
    required String companyName,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? stateName,
    String? pincode,
    String? tinNumber,
    String? notes,
    String status = 'active',
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.create(
      companyName: companyName,
      contactPerson: contactPerson,
      phone: phone,
      email: email,
      address: address,
      city: city,
      state: stateName,
      pincode: pincode,
      tinNumber: tinNumber,
      notes: notes,
      status: status,
    );

    state = state.copyWith(isLoading: false, clearError: true);

    if (result.isSuccess) {
      AppLogger.i('SupplierNotifier: supplier created successfully');
      unawaited(_auditLogRepo.logAction(
        userId: 'admin',
        action: 'create',
        entityType: 'supplier',
        entityId: result.value.id,
        newValues: result.value.toJson(),
      ));
      await fetchAll(refresh: true);
      return null;
    } else {
      final errorMsg = result.error.message;
      state = state.copyWith(error: errorMsg);
      AppLogger.e('SupplierNotifier: create failed - $errorMsg');
      return errorMsg;
    }
  }

  Future<String?> update({
    required String id,
    String? companyName,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? stateName,
    String? pincode,
    String? tinNumber,
    String? notes,
    String? status,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.update(
      id: id,
      companyName: companyName,
      contactPerson: contactPerson,
      phone: phone,
      email: email,
      address: address,
      city: city,
      state: stateName,
      pincode: pincode,
      tinNumber: tinNumber,
      notes: notes,
      status: status,
    );

    state = state.copyWith(isLoading: false, clearError: true);

    if (result.isSuccess) {
      AppLogger.i('SupplierNotifier: supplier updated successfully');
      unawaited(_auditLogRepo.logAction(
        userId: 'admin',
        action: 'update',
        entityType: 'supplier',
        entityId: result.value.id,
        newValues: result.value.toJson(),
      ));
      await fetchAll(refresh: true);
      return null;
    } else {
      final errorMsg = result.error.message;
      state = state.copyWith(error: errorMsg);
      AppLogger.e('SupplierNotifier: update failed - $errorMsg');
      return errorMsg;
    }
  }

  Future<String?> delete(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.delete(id);

    state = state.copyWith(isLoading: false, clearError: true);

    if (result.isSuccess) {
      AppLogger.i('SupplierNotifier: supplier deleted successfully');
      unawaited(_auditLogRepo.logAction(
        userId: 'admin',
        action: 'delete',
        entityType: 'supplier',
        entityId: id,
        details: 'Deleted supplier',
      ));
      await fetchAll(refresh: true);
      return null;
    } else {
      final errorMsg = result.error.message;
      state = state.copyWith(error: errorMsg);
      AppLogger.e('SupplierNotifier: delete failed - $errorMsg');
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

    final result = await _repository.search(query, page: 1, pageSize: state.pageSize);

    if (result.isSuccess) {
      final countResult = await _repository.getTotalCount();
      state = state.copyWith(
        suppliers: result.value,
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

  Future<void> applyFilters({String? status}) async {
    state = state.copyWith(
      filterStatus: status,
      currentPage: 1,
    );
    await fetchAll(refresh: true);
  }

  void setSortBy(String column) {
    final ascending = state.sortBy == column ? !state.sortAscending : false;
    state = state.copyWith(sortBy: column, sortAscending: ascending, currentPage: 1);
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
      searchQuery: '',
      currentPage: 1,
    );
    fetchAll(refresh: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final supplierProvider = StateNotifierProvider<SupplierNotifier, SupplierState>((ref) {
  final repository = ref.watch(supplierRepositoryProvider);
  final auditLogRepo = ref.read(auditLogRepositoryProvider);
  return SupplierNotifier(repository, auditLogRepo);
});
