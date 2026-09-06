import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';

import 'package:sahibz_inventory/core/logger.dart';
import 'package:sahibz_inventory/core/constants.dart';
import 'package:sahibz_inventory/features/customers/models/customer_model.dart';
import 'package:sahibz_inventory/features/customers/repositories/customer_repository.dart';
import 'package:sahibz_inventory/features/audit_logs/repositories/audit_log_repository.dart';

class CustomerState {
  final List<CustomerModel> customers;
  final CustomerModel? selectedCustomer;
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

  const CustomerState({
    this.customers = const [],
    this.selectedCustomer,
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

  CustomerState copyWith({
    List<CustomerModel>? customers,
    CustomerModel? selectedCustomer,
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
    return CustomerState(
      customers: customers ?? this.customers,
      selectedCustomer: selectedCustomer ?? this.selectedCustomer,
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

class CustomerNotifier extends StateNotifier<CustomerState> {
  final CustomerRepository _repository;
  final AuditLogRepository _auditLogRepo;

  CustomerNotifier(this._repository, this._auditLogRepo) : super(const CustomerState());

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
      final customers = refresh || page == 1
          ? result.value
          : [...state.customers, ...result.value];

      final countResult = await _repository.getTotalCount(
        status: state.filterStatus,
      );

      state = state.copyWith(
        customers: customers,
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
        selectedCustomer: result.value,
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
    required String name,
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
      name: name,
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
      AppLogger.i('CustomerNotifier: customer created successfully');
      unawaited(_auditLogRepo.logAction(
        userId: 'admin',
        action: 'create',
        entityType: 'customer',
        entityId: result.value.id,
        newValues: result.value.toJson(),
      ));
      await fetchAll(refresh: true);
      return null;
    } else {
      final errorMsg = result.error.message;
      state = state.copyWith(error: errorMsg);
      AppLogger.e('CustomerNotifier: create failed - $errorMsg');
      return errorMsg;
    }
  }

  Future<String?> update({
    required String id,
    String? name,
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
      name: name,
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
      AppLogger.i('CustomerNotifier: customer updated successfully');
      unawaited(_auditLogRepo.logAction(
        userId: 'admin',
        action: 'update',
        entityType: 'customer',
        entityId: result.value.id,
        newValues: result.value.toJson(),
      ));
      await fetchAll(refresh: true);
      return null;
    } else {
      final errorMsg = result.error.message;
      state = state.copyWith(error: errorMsg);
      AppLogger.e('CustomerNotifier: update failed - $errorMsg');
      return errorMsg;
    }
  }

  Future<String?> delete(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.delete(id);

    state = state.copyWith(isLoading: false, clearError: true);

    if (result.isSuccess) {
      AppLogger.i('CustomerNotifier: customer deleted successfully');
      unawaited(_auditLogRepo.logAction(
        userId: 'admin',
        action: 'delete',
        entityType: 'customer',
        entityId: id,
        details: 'Deleted customer',
      ));
      await fetchAll(refresh: true);
      return null;
    } else {
      final errorMsg = result.error.message;
      state = state.copyWith(error: errorMsg);
      AppLogger.e('CustomerNotifier: delete failed - $errorMsg');
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
        customers: result.value,
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

final customerProvider = StateNotifierProvider<CustomerNotifier, CustomerState>((ref) {
  final repository = ref.watch(customerRepositoryProvider);
  final auditLogRepo = ref.read(auditLogRepositoryProvider);
  return CustomerNotifier(repository, auditLogRepo);
});
