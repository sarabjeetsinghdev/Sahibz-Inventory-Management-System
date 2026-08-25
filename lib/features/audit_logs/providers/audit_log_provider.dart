import 'package:flutter_riverpod/legacy.dart';
import 'package:sahibz_inventory/core/constants.dart';
import 'package:sahibz_inventory/features/audit_logs/models/audit_log_model.dart';
import 'package:sahibz_inventory/features/audit_logs/repositories/audit_log_repository.dart';

class AuditLogState {
  final List<AuditLogModel> logs;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int pageSize;
  final String searchQuery;
  final String? filterAction;
  final String? filterEntityType;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;

  bool get hasMore {
    return logs.length >= pageSize;
  }

  bool get hasSearch => searchQuery.isNotEmpty;

  const AuditLogState({
    this.logs = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.pageSize = AppConstants.defaultPageSize,
    this.searchQuery = '',
    this.filterAction,
    this.filterEntityType,
    this.filterStartDate,
    this.filterEndDate,
  });

  static const _sentinel = Object();

  AuditLogState copyWith({
    List<AuditLogModel>? logs,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? pageSize,
    String? searchQuery,
    Object? filterAction = _sentinel,
    Object? filterEntityType = _sentinel,
    Object? filterStartDate = _sentinel,
    Object? filterEndDate = _sentinel,
    bool clearError = false,
  }) {
    return AuditLogState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      searchQuery: searchQuery ?? this.searchQuery,
      filterAction: identical(filterAction, _sentinel)
          ? this.filterAction
          : filterAction as String?,
      filterEntityType: identical(filterEntityType, _sentinel)
          ? this.filterEntityType
          : filterEntityType as String?,
      filterStartDate: identical(filterStartDate, _sentinel)
          ? this.filterStartDate
          : filterStartDate as DateTime?,
      filterEndDate: identical(filterEndDate, _sentinel)
          ? this.filterEndDate
          : filterEndDate as DateTime?,
    );
  }
}

class AuditLogNotifier extends StateNotifier<AuditLogState> {
  final AuditLogRepository _repository;

  AuditLogNotifier(this._repository) : super(const AuditLogState());

  Future<void> fetchAll({bool refresh = false}) async {
    if (state.isLoading) return;

    final page = refresh ? 1 : state.currentPage;
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.getLogs(
      page: page,
      pageSize: state.pageSize,
      search: state.hasSearch ? state.searchQuery : null,
      action: state.filterAction,
      entityType: state.filterEntityType,
      startDate: state.filterStartDate,
      endDate: state.filterEndDate,
    );

    if (result.isSuccess) {
      final logs = refresh || page == 1
          ? result.value
          : [...state.logs, ...result.value];

      state = state.copyWith(
        logs: logs,
        currentPage: page,
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
      isLoading: true,
      clearError: true,
    );

    if (query.isEmpty) {
      await fetchAll(refresh: true);
      return;
    }

    final result = await _repository.getLogs(
      search: query,
      page: 1,
      pageSize: state.pageSize,
      action: state.filterAction,
      entityType: state.filterEntityType,
      startDate: state.filterStartDate,
      endDate: state.filterEndDate,
    );

    if (result.isSuccess) {
      state = state.copyWith(
        logs: result.value,
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
    String? action,
    String? entityType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = state.copyWith(
      filterAction: action,
      filterEntityType: entityType,
      filterStartDate: startDate,
      filterEndDate: endDate,
      currentPage: 1,
    );
    await fetchAll(refresh: true);
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(currentPage: state.currentPage + 1);
    await fetchAll();
  }

  void clearFilters() {
    state = state.copyWith(
      filterAction: null,
      filterEntityType: null,
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

final auditLogProvider = StateNotifierProvider<AuditLogNotifier, AuditLogState>((ref) {
  final repository = ref.watch(auditLogRepositoryProvider);
  return AuditLogNotifier(repository);
});
