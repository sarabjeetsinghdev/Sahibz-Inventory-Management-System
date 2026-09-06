import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:sahibz_inventory/core/result.dart';
import 'package:sahibz_inventory/core/exceptions.dart';
import 'package:sahibz_inventory/core/logger.dart';
import 'package:sahibz_inventory/core/constants.dart';
import 'package:sahibz_inventory/database/database.dart';
import 'package:sahibz_inventory/features/customers/models/customer_model.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CustomerRepository(database: db);
});

class CustomerRepository {
  final AppDatabase _db;
  final Uuid _uuid;

  CustomerRepository({
    required AppDatabase database,
  })  : _db = database,
        _uuid = const Uuid();

  Future<Result<CustomerModel>> create({
    required String name,
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

      await _db.into(_db.customers).insert(CustomersCompanion.insert(
        id: id,
        name: name,
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

      final customer = CustomerModel(
        id: id,
        name: name,
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

      AppLogger.i('Customer created: $name');
      return Success(customer);
    } on DatabaseException catch (e) {
      AppLogger.e('Database error creating customer', e);
      return Failure(DatabaseException('Failed to create customer: ${e.message}', originalError: e));
    } catch (e, stack) {
      AppLogger.e('Failed to create customer', e, stack);
      return Failure(AppException('Failed to create customer', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<CustomerModel>> update({
    required String id,
    String? name,
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
      final existing = await (_db.select(_db.customers)..where((c) => c.id.equals(id))).getSingleOrNull();
      if (existing == null) {
        return const Failure(NotFoundException('Customer not found'));
      }

      final now = DateTime.now();
      await (_db.update(_db.customers)..where((c) => c.id.equals(id))).write(CustomersCompanion(
        name: name != null ? Value(name) : const Value.absent(),
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

      final customer = await _getCustomerById(id);
      if (customer == null) {
        return const Failure(NotFoundException('Customer updated but not found'));
      }

      AppLogger.i('Customer updated: ${customer.name}');
      return Success(customer);
    } on DatabaseException catch (e) {
      AppLogger.e('Database error updating customer', e);
      return Failure(DatabaseException('Failed to update customer: ${e.message}', originalError: e));
    } catch (e, stack) {
      AppLogger.e('Failed to update customer', e, stack);
      return Failure(AppException('Failed to update customer', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<void>> delete(String id) async {
    try {
      final existing = await (_db.select(_db.customers)..where((c) => c.id.equals(id))).getSingleOrNull();
      if (existing == null) {
        return const Failure(NotFoundException('Customer not found'));
      }

      await (_db.update(_db.customers)..where((c) => c.id.equals(id))).write(CustomersCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ));

      AppLogger.i('Customer soft-deleted: ${existing.name}');
      return const Success(null);
    } catch (e, stack) {
      AppLogger.e('Failed to delete customer', e, stack);
      return Failure(AppException('Failed to delete customer', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<CustomerModel>> getById(String id) async {
    try {
      final customer = await _getCustomerById(id);
      if (customer == null) {
        return const Failure(NotFoundException('Customer not found'));
      }
      return Success(customer);
    } catch (e, stack) {
      AppLogger.e('Failed to get customer by id', e, stack);
      return Failure(AppException('Failed to get customer', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<List<CustomerModel>>> getAll({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String sortBy = 'createdAt',
    bool sortAscending = false,
  }) async {
    try {
      final query = _db.select(_db.customers)
        ..where((c) => c.isDeleted.equals(false));

      if (status != null && status.isNotEmpty) {
        query.where((c) => c.status.equals(status));
      }
      if (startDate != null) {
        query.where((c) => c.createdAt.isBiggerThanValue(startDate));
      }
      if (endDate != null) {
        query.where((c) => c.createdAt.isSmallerThanValue(endDate));
      }

      // final totalCount = await query.get().then((r) => r.length);
      final offset = (page - 1) * pageSize;
      query.limit(pageSize, offset: offset);

      switch (sortBy) {
        case 'name':
          query.orderBy([(c) => sortAscending ? OrderingTerm.asc(c.name) : OrderingTerm.desc(c.name)]);
          break;
        case 'city':
          query.orderBy([(c) => sortAscending ? OrderingTerm.asc(c.city) : OrderingTerm.desc(c.city)]);
          break;
        case 'status':
          query.orderBy([(c) => sortAscending ? OrderingTerm.asc(c.status) : OrderingTerm.desc(c.status)]);
          break;
        default:
          query.orderBy([(c) => sortAscending ? OrderingTerm.asc(c.createdAt) : OrderingTerm.desc(c.createdAt)]);
      }

      final customers = await query.get();
      final models = customers.map(CustomerModel.fromCustomer).toList();

      AppLogger.i('Customers fetched: ${customers.length} (page $page)');
      return Success(models);
    } catch (e, stack) {
      AppLogger.e('Failed to fetch customers', e, stack);
      return Failure(AppException('Failed to fetch customers', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<List<CustomerModel>>> search(String query, {
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) async {
    try {
      final searchTerm = '%${query.toLowerCase()}%';
      final offset = (page - 1) * pageSize;

      final searchQuery = _db.select(_db.customers)
        ..where((c) => c.isDeleted.equals(false) & (
          c.name.lower().like(searchTerm) |
          c.phone.like(searchTerm) |
          c.email.lower().like(searchTerm) |
          c.gstNumber.lower().like(searchTerm) |
          c.city.lower().like(searchTerm)
        ))
        ..orderBy([(c) => OrderingTerm.desc(c.createdAt)])
        ..limit(pageSize, offset: offset);

      final customers = await searchQuery.get();
      final models = customers.map(CustomerModel.fromCustomer).toList();

      AppLogger.i('Customers search: ${models.length} results for "$query"');
      return Success(models);
    } catch (e, stack) {
      AppLogger.e('Failed to search customers', e, stack);
      return Failure(AppException('Failed to search customers', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<int>> getTotalCount({String? status}) async {
    try {
      final query = _db.select(_db.customers)
        ..where((c) => c.isDeleted.equals(false));
      if (status != null && status.isNotEmpty) {
        query.where((c) => c.status.equals(status));
      }
      final count = await query.get().then((r) => r.length);
      return Success(count);
    } catch (e, stack) {
      AppLogger.e('Failed to get customer count', e, stack);
      return Failure(AppException('Failed to get customer count', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<List<Map<String, dynamic>>>> getSaleHistory(String customerId, {
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) async {
    try {
      final offset = (page - 1) * pageSize;
      final sales = await (_db.select(_db.sales)
        ..where((s) => s.customerId.equals(customerId) & s.isDeleted.equals(false))
        ..orderBy([(s) => OrderingTerm.desc(s.saleDate)])
        ..limit(pageSize, offset: offset)
      ).get();

      final history = await Future.wait(sales.map((s) async {
        int itemCount = 0;
        try {
          final items = await (_db.select(_db.salesItems)
            ..where((si) => si.saleId.equals(s.id))
          ).get();
          itemCount = items.length;
        } catch (_) {}

        return {
          'id': s.id,
          'invoiceNumber': s.invoiceNumber,
          'saleDate': s.saleDate,
          'totalAmount': s.totalAmount,
          'paidAmount': s.paidAmount,
          'dueAmount': s.dueAmount,
          'status': s.status,
          'paymentStatus': s.paymentStatus,
          'itemCount': itemCount,
        };
      }));

      AppLogger.i('Sale history fetched for customer $customerId: ${history.length} records');
      return Success(history);
    } catch (e, stack) {
      AppLogger.e('Failed to get sale history', e, stack);
      return Failure(AppException('Failed to get sale history', originalError: e, stackTrace: stack));
    }
  }

  Future<CustomerModel?> _getCustomerById(String id) async {
    final customer = await (_db.select(_db.customers)..where((c) => c.id.equals(id))).getSingleOrNull();
    if (customer == null) return null;
    return CustomerModel.fromCustomer(customer);
  }
}
