import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:sahibz_inventory/core/result.dart';
import 'package:sahibz_inventory/core/exceptions.dart';
import 'package:sahibz_inventory/core/logger.dart';
import 'package:sahibz_inventory/core/constants.dart';
import 'package:sahibz_inventory/database/database.dart';
import 'package:sahibz_inventory/features/products/models/product_model.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ProductRepository(database: db);
});

class ProductRepository {
  final AppDatabase _db;
  final Uuid _uuid;

  ProductRepository({
    required AppDatabase database,
  })  : _db = database,
        _uuid = const Uuid();

  Future<Result<ProductModel>> create({
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
    try {
      final id = _uuid.v4();
      // final now = DateTime.now();

      await _db.into(_db.products).insert(ProductsCompanion.insert(
        id: id,
        name: name,
        sku: sku,
        barcode: barcode != null ? Value(barcode) : const Value.absent(),
        description: description != null ? Value(description) : const Value.absent(),
        categoryId: categoryId != null ? Value(categoryId) : const Value.absent(),
        supplierId: supplierId != null ? Value(supplierId) : const Value.absent(),
        costPrice: Value(costPrice),
        sellingPrice: Value(sellingPrice),
        taxRate: Value(taxRate),
        taxType: Value(taxType),
        unit: Value(unit),
        reorderLevel: Value(reorderLevel),
        image: image != null ? Value(image) : const Value.absent(),
        status: Value(status),
      ));

      final product = await _getProductById(id);
      if (product == null) {
        return const Failure(NotFoundException('Product created but not found'));
      }

      AppLogger.i('Product created: $name ($sku)');
      return Success(product);
    } on DatabaseException catch (e) {
      AppLogger.e('Database error creating product', e);
      return Failure(DatabaseException('Failed to create product: ${e.message}', originalError: e));
    } catch (e, stack) {
      AppLogger.e('Failed to create product', e, stack);
      return Failure(AppException('Failed to create product', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<ProductModel>> update({
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
    try {
      final existing = await (_db.select(_db.products)..where((p) => p.id.equals(id))).getSingleOrNull();
      if (existing == null) {
        return const Failure(NotFoundException('Product not found'));
      }

      final now = DateTime.now();
      await (_db.update(_db.products)..where((p) => p.id.equals(id))).write(ProductsCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        sku: sku != null ? Value(sku) : const Value.absent(),
        barcode: barcode != null ? Value(barcode) : const Value.absent(),
        description: description != null ? Value(description) : const Value.absent(),
        categoryId: categoryId != null ? Value(categoryId) : const Value.absent(),
        supplierId: supplierId != null ? Value(supplierId) : const Value.absent(),
        costPrice: costPrice != null ? Value(costPrice) : const Value.absent(),
        sellingPrice: sellingPrice != null ? Value(sellingPrice) : const Value.absent(),
        taxRate: taxRate != null ? Value(taxRate) : const Value.absent(),
        taxType: taxType != null ? Value(taxType) : const Value.absent(),
        unit: unit != null ? Value(unit) : const Value.absent(),
        reorderLevel: reorderLevel != null ? Value(reorderLevel) : const Value.absent(),
        image: image != null ? Value(image) : const Value.absent(),
        status: status != null ? Value(status) : const Value.absent(),
        updatedAt: Value(now),
      ));

      final product = await _getProductById(id);
      if (product == null) {
        return const Failure(NotFoundException('Product updated but not found'));
      }

      AppLogger.i('Product updated: ${product.name}');
      return Success(product);
    } on DatabaseException catch (e) {
      AppLogger.e('Database error updating product', e);
      return Failure(DatabaseException('Failed to update product: ${e.message}', originalError: e));
    } catch (e, stack) {
      AppLogger.e('Failed to update product', e, stack);
      return Failure(AppException('Failed to update product', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<void>> delete(String id) async {
    try {
      final existing = await (_db.select(_db.products)..where((p) => p.id.equals(id))).getSingleOrNull();
      if (existing == null) {
        return const Failure(NotFoundException('Product not found'));
      }

      await (_db.update(_db.products)..where((p) => p.id.equals(id))).write(ProductsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ));

      AppLogger.i('Product soft-deleted: ${existing.name}');
      return const Success(null);
    } catch (e, stack) {
      AppLogger.e('Failed to delete product', e, stack);
      return Failure(AppException('Failed to delete product', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<ProductModel>> getById(String id) async {
    try {
      final product = await _getProductById(id);
      if (product == null) {
        return const Failure(NotFoundException('Product not found'));
      }
      return Success(product);
    } catch (e, stack) {
      AppLogger.e('Failed to get product by id', e, stack);
      return Failure(AppException('Failed to get product', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<List<ProductModel>>> getAll({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
    String? categoryId,
    String? supplierId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String sortBy = 'createdAt',
    bool sortAscending = false,
  }) async {
    try {
      final query = _db.select(_db.products)
        ..where((p) => p.isDeleted.equals(false));

      if (categoryId != null && categoryId.isNotEmpty) {
        query.where((p) => p.categoryId.equals(categoryId));
      }
      if (supplierId != null && supplierId.isNotEmpty) {
        query.where((p) => p.supplierId.equals(supplierId));
      }
      if (status != null && status.isNotEmpty) {
        query.where((p) => p.status.equals(status));
      }
      if (startDate != null) {
        query.where((p) => p.createdAt.isBiggerThanValue(startDate));
      }
      if (endDate != null) {
        query.where((p) => p.createdAt.isSmallerThanValue(endDate));
      }

      // final totalCount = await query.get().then((r) => r.length);

      final offset = (page - 1) * pageSize;
      query.limit(pageSize, offset: offset);

      switch (sortBy) {
        case 'name':
          query.orderBy([(p) => sortAscending ? OrderingTerm.asc(p.name) : OrderingTerm.desc(p.name)]);
          break;
        case 'sku':
          query.orderBy([(p) => sortAscending ? OrderingTerm.asc(p.sku) : OrderingTerm.desc(p.sku)]);
          break;
        case 'costPrice':
          query.orderBy([(p) => sortAscending ? OrderingTerm.asc(p.costPrice) : OrderingTerm.desc(p.costPrice)]);
          break;
        case 'sellingPrice':
          query.orderBy([(p) => sortAscending ? OrderingTerm.asc(p.sellingPrice) : OrderingTerm.desc(p.sellingPrice)]);
          break;
        case 'quantity':
          query.orderBy([(p) => sortAscending ? OrderingTerm.asc(p.reorderLevel) : OrderingTerm.desc(p.reorderLevel)]);
          break;
        case 'status':
          query.orderBy([(p) => sortAscending ? OrderingTerm.asc(p.status) : OrderingTerm.desc(p.status)]);
          break;
        default:
          query.orderBy([(p) => sortAscending ? OrderingTerm.asc(p.createdAt) : OrderingTerm.desc(p.createdAt)]);
      }

      final products = await query.get();
      final models = await Future.wait(products.map((p) => _buildProductModel(p)));

      AppLogger.i('Products fetched: ${products.length} (page $page)');
      return Success(models);
    } catch (e, stack) {
      AppLogger.e('Failed to fetch products', e, stack);
      return Failure(AppException('Failed to fetch products', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<List<ProductModel>>> search(String query, {
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) async {
    try {
      final searchTerm = '%${query.toLowerCase()}%';
      final offset = (page - 1) * pageSize;

      final searchQuery = _db.select(_db.products)
        ..where((p) => p.isDeleted.equals(false) & (
          p.name.lower().like(searchTerm) |
          p.sku.lower().like(searchTerm) |
          (p.barcode.like(searchTerm))
        ))
        ..orderBy([(p) => OrderingTerm.desc(p.createdAt)])
        ..limit(pageSize, offset: offset);

      final products = await searchQuery.get();
      final models = await Future.wait(products.map((p) => _buildProductModel(p)));

      AppLogger.i('Products search: ${products.length} results for "$query"');
      return Success(models);
    } catch (e, stack) {
      AppLogger.e('Failed to search products', e, stack);
      return Failure(AppException('Failed to search products', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<int>> getTotalCount({
    String? categoryId,
    String? supplierId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final query = _db.select(_db.products)
        ..where((p) => p.isDeleted.equals(false));

      if (categoryId != null && categoryId.isNotEmpty) {
        query.where((p) => p.categoryId.equals(categoryId));
      }
      if (supplierId != null && supplierId.isNotEmpty) {
        query.where((p) => p.supplierId.equals(supplierId));
      }
      if (status != null && status.isNotEmpty) {
        query.where((p) => p.status.equals(status));
      }
      if (startDate != null) {
        query.where((p) => p.createdAt.isBiggerThanValue(startDate));
      }
      if (endDate != null) {
        query.where((p) => p.createdAt.isSmallerThanValue(endDate));
      }

      final count = await query.get().then((r) => r.length);
      return Success(count);
    } catch (e, stack) {
      AppLogger.e('Failed to get product count', e, stack);
      return Failure(AppException('Failed to get product count', originalError: e, stackTrace: stack));
    }
  }

  Future<ProductModel?> _getProductById(String id) async {
    final product = await (_db.select(_db.products)..where((p) => p.id.equals(id))).getSingleOrNull();
    if (product == null) return null;
    return _buildProductModel(product);
  }

  Future<ProductModel> _buildProductModel(Product p) async {
    String? categoryName;
    if (p.categoryId != null && p.categoryId!.isNotEmpty) {
      final category = await (_db.select(_db.categories)..where((c) => c.id.equals(p.categoryId!))).getSingleOrNull();
      categoryName = category?.name;
    }

    String? supplierName;
    if (p.supplierId != null && p.supplierId!.isNotEmpty) {
      final supplier = await (_db.select(_db.suppliers)..where((s) => s.id.equals(p.supplierId!))).getSingleOrNull();
      supplierName = supplier?.companyName;
    }

    return ProductModel.fromProduct(p, categoryName: categoryName, supplierName: supplierName);
  }
}
