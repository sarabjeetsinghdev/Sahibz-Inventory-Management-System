import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:sahibz_inventory/core/result.dart';
import 'package:sahibz_inventory/core/exceptions.dart';
import 'package:sahibz_inventory/core/logger.dart';
import 'package:sahibz_inventory/core/constants.dart';
import 'package:sahibz_inventory/database/database.dart';
import 'package:sahibz_inventory/features/categories/models/category_model.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CategoryRepository(database: db);
});

class CategoryRepository {
  final AppDatabase _db;
  final Uuid _uuid;

  CategoryRepository({
    required AppDatabase database,
  })  : _db = database,
        _uuid = const Uuid();

  Future<Result<CategoryModel>> create({
    required String name,
    String? description,
    String? image,
    String? parentId,
    String status = 'active',
  }) async {
    try {
      final id = _uuid.v4();
      final now = DateTime.now();

      String? parentName;
      if (parentId != null && parentId.isNotEmpty) {
        final parent = await (_db.select(_db.categories)..where((c) => c.id.equals(parentId))).getSingleOrNull();
        parentName = parent?.name;
      }

      await _db.into(_db.categories).insert(CategoriesCompanion.insert(
        id: id,
        name: name,
        description: description != null ? Value(description) : const Value.absent(),
        image: image != null ? Value(image) : const Value.absent(),
        parentId: parentId != null && parentId.isNotEmpty ? Value(parentId) : const Value.absent(),
        status: Value(status),
      ));

      final category = CategoryModel(
        id: id,
        name: name,
        description: description,
        image: image,
        parentId: parentId,
        parentName: parentName,
        status: status,
        createdAt: now,
        updatedAt: now,
      );

      AppLogger.i('Category created: $name');
      return Success(category);
    } on DatabaseException catch (e) {
      AppLogger.e('Database error creating category', e);
      return Failure(DatabaseException('Failed to create category: ${e.message}', originalError: e));
    } catch (e, stack) {
      AppLogger.e('Failed to create category', e, stack);
      return Failure(AppException('Failed to create category', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<CategoryModel>> update({
    required String id,
    String? name,
    String? description,
    String? image,
    String? parentId,
    String? status,
  }) async {
    try {
      final existing = await (_db.select(_db.categories)..where((c) => c.id.equals(id))).getSingleOrNull();
      if (existing == null) {
        return const Failure(NotFoundException('Category not found'));
      }

      final now = DateTime.now();
      await (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(CategoriesCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        description: description != null ? Value(description) : const Value.absent(),
        image: image != null ? Value(image) : const Value.absent(),
        parentId: parentId != null ? Value(parentId) : const Value.absent(),
        status: status != null ? Value(status) : const Value.absent(),
        updatedAt: Value(now),
      ));

      final category = await _getCategoryById(id);
      if (category == null) {
        return const Failure(NotFoundException('Category updated but not found'));
      }

      AppLogger.i('Category updated: ${category.name}');
      return Success(category);
    } on DatabaseException catch (e) {
      AppLogger.e('Database error updating category', e);
      return Failure(DatabaseException('Failed to update category: ${e.message}', originalError: e));
    } catch (e, stack) {
      AppLogger.e('Failed to update category', e, stack);
      return Failure(AppException('Failed to update category', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<void>> delete(String id) async {
    try {
      final existing = await (_db.select(_db.categories)..where((c) => c.id.equals(id))).getSingleOrNull();
      if (existing == null) {
        return const Failure(NotFoundException('Category not found'));
      }

      final children = await (_db.select(_db.categories)..where((c) => c.parentId.equals(id) & c.isDeleted.equals(false))).get();
      if (children.isNotEmpty) {
        return const Failure(ValidationException('Cannot delete category with subcategories. Remove or reassign them first.'));
      }

      final productCount = await (_db.select(_db.products)..where((p) => p.categoryId.equals(id) & p.isDeleted.equals(false))).get().then((r) => r.length);
      print(await _db.select(_db.products).get());
      if (productCount > 0) {
        return Failure(ValidationException('Cannot delete category with $productCount associated products. Reassign products first.'));
      }

      await (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(CategoriesCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ));

      AppLogger.i('Category soft-deleted: ${existing.name}');
      return const Success(null);
    } catch (e, stack) {
      AppLogger.e('Failed to delete category', e, stack);
      return Failure(AppException('Failed to delete category', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<CategoryModel>> getById(String id) async {
    try {
      final category = await _getCategoryById(id);
      if (category == null) {
        return const Failure(NotFoundException('Category not found'));
      }
      return Success(category);
    } catch (e, stack) {
      AppLogger.e('Failed to get category by id', e, stack);
      return Failure(AppException('Failed to get category', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<List<CategoryModel>>> getAll({
    bool onlyActive = false,
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) async {
    try {
      final query = _db.select(_db.categories)
        ..where((c) => c.isDeleted.equals(false));

      if (onlyActive) {
        query.where((c) => c.status.equals('active'));
      }

      final totalCount = await query.get().then((r) => r.length);
      final offset = (page - 1) * pageSize;
      query
        ..orderBy([(c) => OrderingTerm.desc(c.createdAt)])
        ..limit(pageSize, offset: offset);

      final categories = await query.get();
      final models = await Future.wait(categories.map((c) => _buildCategoryModel(c)));

      AppLogger.i('Categories fetched: ${categories.length} (page $page, total $totalCount)');
      return Success(models);
    } catch (e, stack) {
      AppLogger.e('Failed to fetch categories', e, stack);
      return Failure(AppException('Failed to fetch categories', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<List<CategoryModel>>> search(String query, {
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) async {
    try {
      final searchTerm = '%${query.toLowerCase()}%';
      final offset = (page - 1) * pageSize;

      final searchQuery = _db.select(_db.categories)
        ..where((c) => c.isDeleted.equals(false) & c.name.lower().like(searchTerm))
        ..orderBy([(c) => OrderingTerm.desc(c.createdAt)])
        ..limit(pageSize, offset: offset);

      final categories = await searchQuery.get();
      final models = await Future.wait(categories.map((c) => _buildCategoryModel(c)));

      AppLogger.i('Categories search: ${categories.length} results for "$query"');
      return Success(models);
    } catch (e, stack) {
      AppLogger.e('Failed to search categories', e, stack);
      return Failure(AppException('Failed to search categories', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<List<CategoryModel>>> getChildren(String parentId) async {
    try {
      final categories = await (_db.select(_db.categories)
        ..where((c) => c.parentId.equals(parentId) & c.isDeleted.equals(false))
        ..orderBy([(c) => OrderingTerm.asc(c.name)])
      ).get();

      final models = await Future.wait(categories.map((c) => _buildCategoryModel(c)));
      return Success(models);
    } catch (e, stack) {
      AppLogger.e('Failed to get child categories', e, stack);
      return Failure(AppException('Failed to get child categories', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<List<CategoryModel>>> getAllRootCategories({bool onlyActive = false}) async {
    try {
      final query = _db.select(_db.categories)
        ..where((c) => c.isDeleted.equals(false) & c.parentId.isNull());

      if (onlyActive) {
        query.where((c) => c.status.equals('active'));
      }

      query.orderBy([(c) => OrderingTerm.asc(c.name)]);
      final categories = await query.get();
      final models = await Future.wait(categories.map((c) => _buildCategoryModel(c)));
      return Success(models);
    } catch (e, stack) {
      AppLogger.e('Failed to get root categories', e, stack);
      return Failure(AppException('Failed to get root categories', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<int>> getTotalCount({bool onlyActive = false}) async {
    try {
      final query = _db.select(_db.categories)
        ..where((c) => c.isDeleted.equals(false));
      if (onlyActive) {
        query.where((c) => c.status.equals('active'));
      }
      final count = await query.get().then((r) => r.length);
      return Success(count);
    } catch (e, stack) {
      AppLogger.e('Failed to get category count', e, stack);
      return Failure(AppException('Failed to get category count', originalError: e, stackTrace: stack));
    }
  }

  Future<CategoryModel?> _getCategoryById(String id) async {
    final category = await (_db.select(_db.categories)..where((c) => c.id.equals(id))).getSingleOrNull();
    if (category == null) return null;
    return _buildCategoryModel(category);
  }

  Future<CategoryModel> _buildCategoryModel(Category c) async {
    String? parentName;
    if (c.parentId != null && c.parentId!.isNotEmpty) {
      final parent = await (_db.select(_db.categories)..where((p) => p.id.equals(c.parentId!))).getSingleOrNull();
      parentName = parent?.name;
    }
    return CategoryModel.fromCategory(c, parentName: parentName);
  }
}
