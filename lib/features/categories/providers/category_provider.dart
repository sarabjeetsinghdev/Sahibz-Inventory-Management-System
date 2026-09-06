import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';

import 'package:sahibz_inventory/core/logger.dart';
import 'package:sahibz_inventory/core/constants.dart';
import 'package:sahibz_inventory/features/categories/models/category_model.dart';
import 'package:sahibz_inventory/features/categories/repositories/category_repository.dart';
import 'package:sahibz_inventory/features/audit_logs/repositories/audit_log_repository.dart';

class CategoryState {
  final List<CategoryModel> categories;
  final CategoryModel? selectedCategory;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalCount;
  final int pageSize;
  final String searchQuery;
  final String sortBy;
  final bool sortAscending;

  bool get hasMore => currentPage * pageSize < totalCount;
  bool get hasSearch => searchQuery.isNotEmpty;

  const CategoryState({
    this.categories = const [],
    this.selectedCategory,
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalCount = 0,
    this.pageSize = AppConstants.defaultPageSize,
    this.searchQuery = '',
    this.sortBy = 'createdAt',
    this.sortAscending = false,
  });

  CategoryState copyWith({
    List<CategoryModel>? categories,
    CategoryModel? selectedCategory,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalCount,
    int? pageSize,
    String? searchQuery,
    String? sortBy,
    bool? sortAscending,
    bool clearError = false,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      pageSize: pageSize ?? this.pageSize,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}

class CategoryNotifier extends StateNotifier<CategoryState> {
  final CategoryRepository _repository;
  final AuditLogRepository _auditLogRepo;

  CategoryNotifier(this._repository, this._auditLogRepo)
      : super(const CategoryState());

  Future<void> fetchAll({bool refresh = false}) async {
    if (state.isLoading) return;

    final page = refresh ? 1 : state.currentPage;
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.getAll(
      page: page,
      pageSize: state.pageSize,
    );

    if (result.isSuccess) {
      final categories = refresh || page == 1
          ? result.value
          : [...state.categories, ...result.value];

      final countResult = await _repository.getTotalCount();

      state = state.copyWith(
        categories: categories,
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
        selectedCategory: result.value,
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
    String? description,
    String? image,
    String? parentId,
    String status = 'active',
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.create(
      name: name,
      description: description,
      image: image,
      parentId: parentId,
      status: status,
    );

    state = state.copyWith(isLoading: false, clearError: true);

    if (result.isSuccess) {
      AppLogger.i('CategoryNotifier: category created successfully');
      unawaited(_auditLogRepo.logAction(
        userId: 'admin',
        action: 'create',
        entityType: 'category',
        entityId: result.value.id,
        newValues: result.value.toJson(),
      ));
      await fetchAll(refresh: true);
      return null;
    } else {
      final errorMsg = result.error.message;
      state = state.copyWith(error: errorMsg);
      AppLogger.e('CategoryNotifier: create failed - $errorMsg');
      return errorMsg;
    }
  }

  Future<String?> update({
    required String id,
    String? name,
    String? description,
    String? image,
    String? parentId,
    String? status,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.update(
      id: id,
      name: name,
      description: description,
      image: image,
      parentId: parentId,
      status: status,
    );

    state = state.copyWith(isLoading: false, clearError: true);

    if (result.isSuccess) {
      AppLogger.i('CategoryNotifier: category updated successfully');
      unawaited(_auditLogRepo.logAction(
        userId: 'admin',
        action: 'update',
        entityType: 'category',
        entityId: result.value.id,
        newValues: result.value.toJson(),
      ));
      await fetchAll(refresh: true);
      return null;
    } else {
      final errorMsg = result.error.message;
      state = state.copyWith(error: errorMsg);
      AppLogger.e('CategoryNotifier: update failed - $errorMsg');
      return errorMsg;
    }
  }

  Future<String?> delete(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.delete(id);

    state = state.copyWith(isLoading: false, clearError: true);

    if (result.isSuccess) {
      AppLogger.i('CategoryNotifier: category deleted successfully');
      unawaited(_auditLogRepo.logAction(
        userId: 'admin',
        action: 'delete',
        entityType: 'category',
        entityId: id,
        details: 'Deleted category',
      ));
      await fetchAll(refresh: true);
      return null;
    } else {
      final errorMsg = result.error.message;
      state = state.copyWith(error: errorMsg);
      AppLogger.e('CategoryNotifier: delete failed - $errorMsg');
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
      final countResult = await _repository.getTotalCount();
      state = state.copyWith(
        categories: result.value,
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

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final categoryProvider =
    StateNotifierProvider<CategoryNotifier, CategoryState>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  final auditLogRepo = ref.read(auditLogRepositoryProvider);
  return CategoryNotifier(repository, auditLogRepo);
});
