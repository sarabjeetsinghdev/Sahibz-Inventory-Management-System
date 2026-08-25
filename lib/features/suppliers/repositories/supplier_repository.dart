import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:sahibz_inventory/core/result.dart';
import 'package:sahibz_inventory/core/exceptions.dart';
import 'package:sahibz_inventory/core/logger.dart';
import 'package:sahibz_inventory/core/constants.dart';
import 'package:sahibz_inventory/database/database.dart';
import 'package:sahibz_inventory/features/suppliers/models/supplier_model.dart';

final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SupplierRepository(database: db);
});

class SupplierRepository {
  final AppDatabase _db;
  final Uuid _uuid;

  SupplierRepository({
    required AppDatabase database,
  })  : _db = database,
        _uuid = const Uuid();

  Future<Result<SupplierModel>> create({
    required String companyName,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? tinNumber,
    String? notes,
    String status = 'active',
  }) async {
    try {
      final id = _uuid.v4();
      final now = DateTime.now();

      await _db.into(_db.suppliers).insert(SuppliersCompanion.insert(
        id: id,
        companyName: companyName,
        contactPerson: contactPerson != null ? Value(contactPerson) : const Value.absent(),
        phone: phone != null ? Value(phone) : const Value.absent(),
        email: email != null ? Value(email) : const Value.absent(),
        address: address != null ? Value(address) : const Value.absent(),
        city: city != null ? Value(city) : const Value.absent(),
        state: state != null ? Value(state) : const Value.absent(),
        pincode: pincode != null ? Value(pincode) : const Value.absent(),
        gstNumber: tinNumber != null ? Value(tinNumber) : const Value.absent(),
        notes: notes != null ? Value(notes) : const Value.absent(),
        status: Value(status),
      ));

      final supplier = SupplierModel(
        id: id,
        companyName: companyName,
        contactPerson: contactPerson,
        phone: phone,
        email: email,
        address: address,
        city: city,
        state: state,
        pincode: pincode,
        tinNumber: tinNumber,
        notes: notes,
        status: status,
        createdAt: now,
        updatedAt: now,
      );

      AppLogger.i('Supplier created: $companyName');
      return Success(supplier);
    } on DatabaseException catch (e) {
      AppLogger.e('Database error creating supplier', e);
      return Failure(DatabaseException('Failed to create supplier: ${e.message}', originalError: e));
    } catch (e, stack) {
      AppLogger.e('Failed to create supplier', e, stack);
      return Failure(AppException('Failed to create supplier', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<SupplierModel>> update({
    required String id,
    String? companyName,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? tinNumber,
    String? notes,
    String? status,
  }) async {
    try {
      final existing = await (_db.select(_db.suppliers)..where((s) => s.id.equals(id))).getSingleOrNull();
      if (existing == null) {
        return const Failure(NotFoundException('Supplier not found'));
      }

      final now = DateTime.now();
      await (_db.update(_db.suppliers)..where((s) => s.id.equals(id))).write(SuppliersCompanion(
        companyName: companyName != null ? Value(companyName) : const Value.absent(),
        contactPerson: contactPerson != null ? Value(contactPerson) : const Value.absent(),
        phone: phone != null ? Value(phone) : const Value.absent(),
        email: email != null ? Value(email) : const Value.absent(),
        address: address != null ? Value(address) : const Value.absent(),
        city: city != null ? Value(city) : const Value.absent(),
        state: state != null ? Value(state) : const Value.absent(),
        pincode: pincode != null ? Value(pincode) : const Value.absent(),
        gstNumber: tinNumber != null ? Value(tinNumber) : const Value.absent(),
        notes: notes != null ? Value(notes) : const Value.absent(),
        status: status != null ? Value(status) : const Value.absent(),
        updatedAt: Value(now),
      ));

      final supplier = await _getSupplierById(id);
      if (supplier == null) {
        return const Failure(NotFoundException('Supplier updated but not found'));
      }

      AppLogger.i('Supplier updated: ${supplier.companyName}');
      return Success(supplier);
    } on DatabaseException catch (e) {
      AppLogger.e('Database error updating supplier', e);
      return Failure(DatabaseException('Failed to update supplier: ${e.message}', originalError: e));
    } catch (e, stack) {
      AppLogger.e('Failed to update supplier', e, stack);
      return Failure(AppException('Failed to update supplier', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<void>> delete(String id) async {
    try {
      final existing = await (_db.select(_db.suppliers)..where((s) => s.id.equals(id))).getSingleOrNull();
      if (existing == null) {
        return const Failure(NotFoundException('Supplier not found'));
      }

      await (_db.update(_db.suppliers)..where((s) => s.id.equals(id))).write(SuppliersCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ));

      AppLogger.i('Supplier soft-deleted: ${existing.companyName}');
      return const Success(null);
    } catch (e, stack) {
      AppLogger.e('Failed to delete supplier', e, stack);
      return Failure(AppException('Failed to delete supplier', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<SupplierModel>> getById(String id) async {
    try {
      final supplier = await _getSupplierById(id);
      if (supplier == null) {
        return const Failure(NotFoundException('Supplier not found'));
      }
      return Success(supplier);
    } catch (e, stack) {
      AppLogger.e('Failed to get supplier by id', e, stack);
      return Failure(AppException('Failed to get supplier', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<List<SupplierModel>>> getAll({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String sortBy = 'createdAt',
    bool sortAscending = false,
  }) async {
    try {
      final query = _db.select(_db.suppliers)
        ..where((s) => s.isDeleted.equals(false));

      if (status != null && status.isNotEmpty) {
        query.where((s) => s.status.equals(status));
      }
      if (startDate != null) {
        query.where((s) => s.createdAt.isBiggerThanValue(startDate));
      }
      if (endDate != null) {
        query.where((s) => s.createdAt.isSmallerThanValue(endDate));
      }

      // final totalCount = await query.get().then((r) => r.length);
      final offset = (page - 1) * pageSize;
      query.limit(pageSize, offset: offset);

      switch (sortBy) {
        case 'companyName':
          query.orderBy([(s) => sortAscending ? OrderingTerm.asc(s.companyName) : OrderingTerm.desc(s.companyName)]);
          break;
        case 'city':
          query.orderBy([(s) => sortAscending ? OrderingTerm.asc(s.city) : OrderingTerm.desc(s.city)]);
          break;
        case 'status':
          query.orderBy([(s) => sortAscending ? OrderingTerm.asc(s.status) : OrderingTerm.desc(s.status)]);
          break;
        default:
          query.orderBy([(s) => sortAscending ? OrderingTerm.asc(s.createdAt) : OrderingTerm.desc(s.createdAt)]);
      }

      final suppliers = await query.get();
      final models = suppliers.map(SupplierModel.fromSupplier).toList();

      AppLogger.i('Suppliers fetched: ${suppliers.length} (page $page)');
      return Success(models);
    } catch (e, stack) {
      AppLogger.e('Failed to fetch suppliers', e, stack);
      return Failure(AppException('Failed to fetch suppliers', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<List<SupplierModel>>> search(String query, {
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) async {
    try {
      final searchTerm = '%${query.toLowerCase()}%';
      final offset = (page - 1) * pageSize;

      final searchQuery = _db.select(_db.suppliers)
        ..where((s) => s.isDeleted.equals(false) & (
          s.companyName.lower().like(searchTerm) |
          s.contactPerson.lower().like(searchTerm) |
          s.phone.like(searchTerm) |
          s.email.lower().like(searchTerm) |
          s.gstNumber.lower().like(searchTerm) |
          s.city.lower().like(searchTerm)
        ))
        ..orderBy([(s) => OrderingTerm.desc(s.createdAt)])
        ..limit(pageSize, offset: offset);

      final suppliers = await searchQuery.get();
      final models = suppliers.map(SupplierModel.fromSupplier).toList();

      AppLogger.i('Suppliers search: ${models.length} results for "$query"');
      return Success(models);
    } catch (e, stack) {
      AppLogger.e('Failed to search suppliers', e, stack);
      return Failure(AppException('Failed to search suppliers', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<int>> getTotalCount({String? status}) async {
    try {
      final query = _db.select(_db.suppliers)
        ..where((s) => s.isDeleted.equals(false));
      if (status != null && status.isNotEmpty) {
        query.where((s) => s.status.equals(status));
      }
      final count = await query.get().then((r) => r.length);
      return Success(count);
    } catch (e, stack) {
      AppLogger.e('Failed to get supplier count', e, stack);
      return Failure(AppException('Failed to get supplier count', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<List<Map<String, dynamic>>>> getPurchaseHistory(String supplierId, {
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) async {
    try {
      final offset = (page - 1) * pageSize;
      final purchases = await (_db.select(_db.purchases)
        ..where((p) => p.supplierId.equals(supplierId) & p.isDeleted.equals(false))
        ..orderBy([(p) => OrderingTerm.desc(p.orderDate)])
        ..limit(pageSize, offset: offset)
      ).get();

      final history = await Future.wait(purchases.map((p) async {
        int itemCount = 0;
        try {
          final items = await (_db.select(_db.purchaseItems)
            ..where((pi) => pi.purchaseId.equals(p.id))
          ).get();
          itemCount = items.length;
        } catch (_) {}

        return {
          'id': p.id,
          'orderNumber': p.orderNumber,
          'orderDate': p.orderDate,
          'totalAmount': p.totalAmount,
          'status': p.status,
          'paymentStatus': p.paymentStatus,
          'itemCount': itemCount,
        };
      }));

      AppLogger.i('Purchase history fetched for supplier $supplierId: ${history.length} records');
      return Success(history);
    } catch (e, stack) {
      AppLogger.e('Failed to get purchase history', e, stack);
      return Failure(AppException('Failed to get purchase history', originalError: e, stackTrace: stack));
    }
  }

  Future<SupplierModel?> _getSupplierById(String id) async {
    final supplier = await (_db.select(_db.suppliers)..where((s) => s.id.equals(id))).getSingleOrNull();
    if (supplier == null) return null;
    return SupplierModel.fromSupplier(supplier);
  }
}
