import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sahibz_inventory/core/logger.dart';
import 'package:sahibz_inventory/core/constants.dart';
import 'package:sahibz_inventory/features/products/models/product_model.dart';
import 'package:sahibz_inventory/features/products/repositories/product_repository.dart';
import 'package:sahibz_inventory/features/products/services/product_excel_importer.dart';
import 'package:sahibz_inventory/features/audit_logs/repositories/audit_log_repository.dart';

class ProductState {
  final List<ProductModel> products;
  final ProductModel? selectedProduct;
  final bool isLoading;
  final int importDone;
  final int importTotal;
  final String? error;
  final int currentPage;
  final int totalCount;
  final int pageSize;
  final String searchQuery;
  final String? filterCategoryId;
  final String? filterSupplierId;
  final String? filterStatus;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;
  final String sortBy;
  final bool sortAscending;

  bool get hasMore => currentPage * pageSize < totalCount;
  bool get hasSearch => searchQuery.isNotEmpty;

  const ProductState({
    this.products = const [],
    this.selectedProduct,
    this.isLoading = false,
    this.importDone = 0,
    this.importTotal = 0,
    this.error,
    this.currentPage = 1,
    this.totalCount = 0,
    this.pageSize = AppConstants.defaultPageSize,
    this.searchQuery = '',
    this.filterCategoryId,
    this.filterSupplierId,
    this.filterStatus,
    this.filterStartDate,
    this.filterEndDate,
    this.sortBy = 'createdAt',
    this.sortAscending = false,
  });

  static const _sentinel = Object();

  ProductState copyWith({
    List<ProductModel>? products,
    ProductModel? selectedProduct,
    bool? isLoading,
    int? importDone,
    int? importTotal,
    String? error,
    int? currentPage,
    int? totalCount,
    int? pageSize,
    String? searchQuery,
    Object? filterCategoryId = _sentinel,
    Object? filterSupplierId = _sentinel,
    Object? filterStatus = _sentinel,
    Object? filterStartDate = _sentinel,
    Object? filterEndDate = _sentinel,
    String? sortBy,
    bool? sortAscending,
    bool clearError = false,
  }) {
    return ProductState(
      products: products ?? this.products,
      selectedProduct: selectedProduct ?? this.selectedProduct,
      isLoading: isLoading ?? this.isLoading,
      importDone: importDone ?? this.importDone,
      importTotal: importTotal ?? this.importTotal,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      pageSize: pageSize ?? this.pageSize,
      searchQuery: searchQuery ?? this.searchQuery,
      filterCategoryId: identical(filterCategoryId, _sentinel)
          ? this.filterCategoryId
          : filterCategoryId as String?,
      filterSupplierId: identical(filterSupplierId, _sentinel)
          ? this.filterSupplierId
          : filterSupplierId as String?,
      filterStatus: identical(filterStatus, _sentinel)
          ? this.filterStatus
          : filterStatus as String?,
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

class ProductNotifier extends StateNotifier<ProductState> {
  final ProductRepository _repository;
  final AuditLogRepository _auditLogRepo;
  final ProductExcelImportService _importService;

  ProductNotifier(this._repository, this._auditLogRepo, this._importService)
      : super(const ProductState());

  Future<void> fetchAll({bool refresh = false}) async {
    if (state.isLoading) return;

    final page = refresh ? 1 : state.currentPage;
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.getAll(
      page: page,
      pageSize: state.pageSize,
      categoryId: state.filterCategoryId,
      supplierId: state.filterSupplierId,
      status: state.filterStatus,
      startDate: state.filterStartDate,
      endDate: state.filterEndDate,
      sortBy: state.sortBy,
      sortAscending: state.sortAscending,
    );

    if (result.isSuccess) {
      final products = refresh || page == 1
          ? result.value
          : [...state.products, ...result.value];

      final countResult = await _repository.getTotalCount(
        categoryId: state.filterCategoryId,
        supplierId: state.filterSupplierId,
        status: state.filterStatus,
        startDate: state.filterStartDate,
        endDate: state.filterEndDate,
      );

      state = state.copyWith(
        products: products,
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
        selectedProduct: result.value,
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
    required String sku,
    String? barcode,
    String? description,
    String? categoryId,
    String? supplierId,
    double costPrice = 0.0,
    double sellingPrice = 0.0,
    double taxRate = 0.0,
    String taxType = 'percentage',
    String unit = 'pcs',
    double reorderLevel = 0.0,
    String? image,
    String status = 'active',
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.create(
      name: name,
      sku: sku,
      barcode: barcode,
      description: description,
      categoryId: categoryId,
      supplierId: supplierId,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      taxRate: taxRate,
      taxType: taxType,
      unit: unit,
      reorderLevel: reorderLevel,
      image: image,
      status: status,
    );

    state = state.copyWith(isLoading: false, clearError: true);

    if (result.isSuccess) {
      AppLogger.i('ProductNotifier: product created successfully');
      unawaited(_auditLogRepo.logAction(
        userId: 'admin',
        action: 'create',
        entityType: 'product',
        entityId: result.value.id,
        newValues: result.value.toJson(),
      ));
      await fetchAll(refresh: true);
      return null;
    } else {
      final errorMsg = result.error.message;
      state = state.copyWith(error: errorMsg);
      AppLogger.e('ProductNotifier: create failed - $errorMsg');
      return errorMsg;
    }
  }

  Future<ProductImportResult?> importFromExcel(
    Uint8List bytes, {
    DuplicatePolicy policy = DuplicatePolicy.skip,
  }) async {
    state = state.copyWith(
        isLoading: true, importDone: 0, importTotal: 0, clearError: true);

    try {
      final result = await _importService.importBytes(
        bytes,
        duplicatePolicy: policy,
        onProgress: (done, total) {
          state = state.copyWith(importDone: done, importTotal: total);
        },
      );
      state = state.copyWith(
          isLoading: false, importDone: 0, importTotal: 0, clearError: true);
      await fetchAll(refresh: true);
      return result;
    } catch (e) {
      final msg = e.toString().replaceFirst('AppException: ', '');
      state = state.copyWith(
          isLoading: false, importDone: 0, importTotal: 0, error: msg);
      AppLogger.e('ProductNotifier: import failed - $msg');
      return null;
    }
  }

  Future<String?> update({
    required String id,
    String? name,
    String? sku,
    String? barcode,
    String? description,
    String? categoryId,
    String? supplierId,
    double? costPrice,
    double? sellingPrice,
    double? taxRate,
    String? taxType,
    String? unit,
    double? reorderLevel,
    String? image,
    String? status,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.update(
      id: id,
      name: name,
      sku: sku,
      barcode: barcode,
      description: description,
      categoryId: categoryId,
      supplierId: supplierId,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      taxRate: taxRate,
      taxType: taxType,
      unit: unit,
      reorderLevel: reorderLevel,
      image: image,
      status: status,
    );

    state = state.copyWith(isLoading: false, clearError: true);

    if (result.isSuccess) {
      AppLogger.i('ProductNotifier: product updated successfully');
      unawaited(_auditLogRepo.logAction(
        userId: 'admin',
        action: 'update',
        entityType: 'product',
        entityId: result.value.id,
        newValues: result.value.toJson(),
      ));
      await fetchAll(refresh: true);
      return null;
    } else {
      final errorMsg = result.error.message;
      state = state.copyWith(error: errorMsg);
      AppLogger.e('ProductNotifier: update failed - $errorMsg');
      return errorMsg;
    }
  }

  Future<String?> delete(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.delete(id);

    state = state.copyWith(isLoading: false, clearError: true);

    if (result.isSuccess) {
      AppLogger.i('ProductNotifier: product deleted successfully');
      unawaited(_auditLogRepo.logAction(
        userId: 'admin',
        action: 'delete',
        entityType: 'product',
        entityId: id,
        details: 'Deleted product',
      ));
      await fetchAll(refresh: true);
      return null;
    } else {
      final errorMsg = result.error.message;
      state = state.copyWith(error: errorMsg);
      AppLogger.e('ProductNotifier: delete failed - $errorMsg');
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
        products: result.value,
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

  Future<void> applyFilters({
    String? categoryId,
    String? supplierId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = state.copyWith(
      filterCategoryId: categoryId,
      filterSupplierId: supplierId,
      filterStatus: status,
      filterStartDate: startDate,
      filterEndDate: endDate,
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
      filterCategoryId: null,
      filterSupplierId: null,
      filterStatus: null,
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

final productProvider = StateNotifierProvider<ProductNotifier, ProductState>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  final auditLogRepo = ref.read(auditLogRepositoryProvider);
  final importService = ref.watch(productExcelImportServiceProvider);
  return ProductNotifier(repository, auditLogRepo, importService);
});
