import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:sahibz_inventory/core/result.dart';
import 'package:sahibz_inventory/core/exceptions.dart';
import 'package:sahibz_inventory/core/logger.dart';
import 'package:sahibz_inventory/core/constants.dart';
import 'package:sahibz_inventory/database/database.dart';
import 'package:sahibz_inventory/features/sales/models/sale_model.dart';

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SaleRepository(database: db);
});

class SaleRepository {
  final AppDatabase _db;
  final Uuid _uuid;
  int _invoiceSequence = 0;
  String _lastInvoiceDate = '';

  SaleRepository({
    required AppDatabase database,
  })  : _db = database,
        _uuid = const Uuid();

  Future<Result<SaleModel>> create({
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
    try {
      final id = _uuid.v4();
      final now = DateTime.now();
      final invoiceNumber = await _generateInvoiceNumber();
      final saleDt = saleDate ?? now;
      final dueAmount = totalAmount - paidAmount;

      await _db.transaction(() async {
        await _db.into(_db.sales).insert(SalesCompanion.insert(
          id: id,
          invoiceNumber: invoiceNumber,
          customerId: customerId != null ? Value(customerId) : const Value.absent(),
          subtotal: Value(subtotal),
          taxAmount: Value(taxAmount),
          discountAmount: Value(discountAmount),
          totalAmount: Value(totalAmount),
          paidAmount: Value(paidAmount),
          dueAmount: Value(dueAmount),
          paymentMethod: paymentMethod != null ? Value(paymentMethod) : const Value.absent(),
          paymentStatus: Value(paidAmount >= totalAmount ? 'paid' : (paidAmount > 0 ? 'partial' : 'unpaid')),
          notes: notes != null ? Value(notes) : const Value.absent(),
          billingAddress: billingAddress != null ? Value(billingAddress) : const Value.absent(),
          shippingAddress: shippingAddress != null ? Value(shippingAddress) : const Value.absent(),
          createdBy: Value(createdBy),
          saleDate: Value(saleDt),
        ));

        for (final item in items) {
          final itemId = _uuid.v4();
          await _db.into(_db.salesItems).insert(SalesItemsCompanion.insert(
            id: itemId,
            saleId: id,
            productId: item['productId'] as String,
            quantity: (item['quantity'] as num).toDouble(),
            unitPrice: (item['unitPrice'] as num).toDouble(),
            taxRate: Value((item['taxRate'] as num?)?.toDouble() ?? 0.0),
            taxAmount: Value((item['taxAmount'] as num?)?.toDouble() ?? 0.0),
            discountAmount: Value((item['discountAmount'] as num?)?.toDouble() ?? 0.0),
            totalPrice: (item['totalPrice'] as num).toDouble(),
          ));
        }

        // Deduct inventory for each sale item -> affects valuation
        for (final item in items) {
          final productId = item['productId'] as String;
          final qty = (item['quantity'] as num).toDouble();
          final unitPrice = (item['unitPrice'] as num).toDouble();

          final product = await (_db.select(_db.products)..where((p) => p.id.equals(productId))).getSingleOrNull();
          if (product == null || product.isDeleted) {
            throw const ValidationException('Product not found for inventory deduction');
          }

          final lastTx = await (_db.select(_db.inventoryTransactions)
                ..where((t) => t.productId.equals(productId))
                ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
                ..limit(1))
              .get();
          final currentBalance = lastTx.isEmpty ? 0.0 : lastTx.first.balanceAfter;
          if (currentBalance < qty) {
            throw ValidationException(
                'Insufficient stock for ${product.name}. Available: $currentBalance, Required: $qty');
          }
          final balanceAfter = currentBalance - qty;
          await _db.into(_db.inventoryTransactions).insert(InventoryTransactionsCompanion.insert(
            id: _uuid.v4(),
            productId: productId,
            type: 'stock_out',
            quantity: -qty,
            unitPrice: Value(unitPrice),
            totalPrice: Value(qty * unitPrice),
            balanceBefore: Value(currentBalance),
            balanceAfter: Value(balanceAfter),
            reference: Value(id),
            referenceType: const Value('sale'),
            notes: Value('Sale $invoiceNumber'),
            transactionDate: Value(saleDt),
          ));
        }
      });

      final sale = await _getSaleById(id);
      if (sale == null) {
        return const Failure(NotFoundException('Sale created but not found'));
      }

      AppLogger.i('Sale created: $invoiceNumber');
      return Success(sale);
    } on DatabaseException catch (e) {
      AppLogger.e('Database error creating sale', e);
      return Failure(DatabaseException('Failed to create sale: ${e.message}', originalError: e));
    } catch (e, stack) {
      AppLogger.e('Failed to create sale', e, stack);
      return Failure(AppException('Failed to create sale', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<SaleModel>> update({
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
    try {
      final existing = await (_db.select(_db.sales)..where((s) => s.id.equals(id))).getSingleOrNull();
      if (existing == null) {
        return const Failure(NotFoundException('Sale not found'));
      }
      if (existing.status != 'pending') {
        return const Failure(ValidationException('Only pending sales can be edited'));
      }

      final now = DateTime.now();

      await (_db.update(_db.sales)..where((s) => s.id.equals(id))).write(SalesCompanion(
        customerId: customerId != null ? Value(customerId) : const Value.absent(),
        subtotal: subtotal != null ? Value(subtotal) : const Value.absent(),
        taxAmount: taxAmount != null ? Value(taxAmount) : const Value.absent(),
        discountAmount: discountAmount != null ? Value(discountAmount) : const Value.absent(),
        totalAmount: totalAmount != null ? Value(totalAmount) : const Value.absent(),
        paymentMethod: paymentMethod != null ? Value(paymentMethod) : const Value.absent(),
        notes: notes != null ? Value(notes) : const Value.absent(),
        billingAddress: billingAddress != null ? Value(billingAddress) : const Value.absent(),
        shippingAddress: shippingAddress != null ? Value(shippingAddress) : const Value.absent(),
        saleDate: saleDate != null ? Value(saleDate) : const Value.absent(),
        updatedAt: Value(now),
      ));

      final sale = await _getSaleById(id);
      if (sale == null) {
        return const Failure(NotFoundException('Sale updated but not found'));
      }

      AppLogger.i('Sale updated: ${sale.invoiceNumber}');
      return Success(sale);
    } catch (e, stack) {
      AppLogger.e('Failed to update sale', e, stack);
      return Failure(AppException('Failed to update sale', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<void>> delete(String id) async {
    try {
      final existing = await (_db.select(_db.sales)..where((s) => s.id.equals(id))).getSingleOrNull();
      if (existing == null) {
        return const Failure(NotFoundException('Sale not found'));
      }

      await (_db.update(_db.sales)..where((s) => s.id.equals(id))).write(SalesCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ));

      AppLogger.i('Sale soft-deleted: ${existing.invoiceNumber}');
      return const Success(null);
    } catch (e, stack) {
      AppLogger.e('Failed to delete sale', e, stack);
      return Failure(AppException('Failed to delete sale', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<SaleModel>> getById(String id) async {
    try {
      final sale = await _getSaleById(id);
      if (sale == null) {
        return const Failure(NotFoundException('Sale not found'));
      }
      return Success(sale);
    } catch (e, stack) {
      AppLogger.e('Failed to get sale by id', e, stack);
      return Failure(AppException('Failed to get sale', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<SaleModel>> updatePayment({
    required String id,
    required double paidAmount,
    String? paymentMethod,
  }) async {
    try {
      final existing = await (_db.select(_db.sales)..where((s) => s.id.equals(id))).getSingleOrNull();
      if (existing == null) {
        return const Failure(NotFoundException('Sale not found'));
      }
      if (existing.status == 'cancelled') {
        return const Failure(ValidationException('Cannot update payment for cancelled sale'));
      }

      final newPaidAmount = existing.paidAmount + paidAmount;
      final newDueAmount = existing.totalAmount - newPaidAmount;
      final newPaymentStatus = newPaidAmount >= existing.totalAmount ? 'paid' : (newPaidAmount > 0 ? 'partial' : 'unpaid');

      await (_db.update(_db.sales)..where((s) => s.id.equals(id))).write(SalesCompanion(
        paidAmount: Value(newPaidAmount),
        dueAmount: Value(newDueAmount),
        paymentStatus: Value(newPaymentStatus),
        paymentMethod: paymentMethod != null ? Value(paymentMethod) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ));

      final sale = await _getSaleById(id);
      AppLogger.i('Payment updated for sale: ${existing.invoiceNumber}');
      return Success(sale!);
    } catch (e, stack) {
      AppLogger.e('Failed to update payment', e, stack);
      return Failure(AppException('Failed to update payment', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<SaleModel>> complete(String id) async {
    try {
      final existing = await (_db.select(_db.sales)..where((s) => s.id.equals(id))).getSingleOrNull();
      if (existing == null) {
        return const Failure(NotFoundException('Sale not found'));
      }
      if (existing.status != 'pending') {
        return const Failure(ValidationException('Only pending sales can be completed'));
      }

      await (_db.update(_db.sales)..where((s) => s.id.equals(id))).write(SalesCompanion(
        status: const Value('completed'),
        updatedAt: Value(DateTime.now()),
      ));

      final sale = await _getSaleById(id);
      AppLogger.i('Sale completed: ${existing.invoiceNumber}');
      return Success(sale!);
    } catch (e, stack) {
      AppLogger.e('Failed to complete sale', e, stack);
      return Failure(AppException('Failed to complete sale', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<SaleModel>> cancel(String id) async {
    try {
      final existing = await (_db.select(_db.sales)..where((s) => s.id.equals(id))).getSingleOrNull();
      if (existing == null) {
        return const Failure(NotFoundException('Sale not found'));
      }
      if (existing.status == 'cancelled') {
        return const Failure(ValidationException('Sale is already cancelled'));
      }

      await _db.transaction(() async {
        await (_db.update(_db.sales)..where((s) => s.id.equals(id))).write(SalesCompanion(
          status: const Value('cancelled'),
          updatedAt: Value(DateTime.now()),
        ));

        // Restore inventory for each item -> reverts valuation
        final saleItems = await (_db.select(_db.salesItems)..where((si) => si.saleId.equals(id))).get();
        for (final item in saleItems) {
          final lastTx = await (_db.select(_db.inventoryTransactions)
                ..where((t) => t.productId.equals(item.productId))
                ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
                ..limit(1))
              .get();
          final currentBalance = lastTx.isEmpty ? 0.0 : lastTx.first.balanceAfter;
          final balanceAfter = currentBalance + item.quantity;
          await _db.into(_db.inventoryTransactions).insert(InventoryTransactionsCompanion.insert(
            id: _uuid.v4(),
            productId: item.productId,
            type: 'stock_in',
            quantity: item.quantity,
            unitPrice: Value(item.unitPrice),
            totalPrice: Value(item.totalPrice),
            balanceBefore: Value(currentBalance),
            balanceAfter: Value(balanceAfter),
            reference: Value(id),
            referenceType: const Value('sale_cancel'),
            notes: Value('Restored from cancelled sale ${existing.invoiceNumber}'),
            transactionDate: Value(DateTime.now()),
          ));
        }
      });

      final sale = await _getSaleById(id);
      AppLogger.i('Sale cancelled: ${existing.invoiceNumber}');
      return Success(sale!);
    } catch (e, stack) {
      AppLogger.e('Failed to cancel sale', e, stack);
      if (e is ValidationException) return Failure(e);
      return Failure(AppException('Failed to cancel sale', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<List<SaleModel>>> getAll({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
    String? status,
    String? paymentStatus,
    String? customerId,
    DateTime? startDate,
    DateTime? endDate,
    String sortBy = 'createdAt',
    bool sortAscending = false,
  }) async {
    try {
      final query = _db.select(_db.sales)
        ..where((s) => s.isDeleted.equals(false));

      if (status != null && status.isNotEmpty) {
        query.where((s) => s.status.equals(status));
      }
      if (paymentStatus != null && paymentStatus.isNotEmpty) {
        query.where((s) => s.paymentStatus.equals(paymentStatus));
      }
      if (customerId != null && customerId.isNotEmpty) {
        query.where((s) => s.customerId.equals(customerId));
      }
      if (startDate != null) {
        query.where((s) => s.saleDate.isBiggerThanValue(startDate));
      }
      if (endDate != null) {
        query.where((s) => s.saleDate.isSmallerThanValue(endDate));
      }

      // final totalCount = await query.get().then((r) => r.length);
      final offset = (page - 1) * pageSize;
      query.limit(pageSize, offset: offset);

      switch (sortBy) {
        case 'invoiceNumber':
          query.orderBy([(s) => sortAscending ? OrderingTerm.asc(s.invoiceNumber) : OrderingTerm.desc(s.invoiceNumber)]);
          break;
        case 'totalAmount':
          query.orderBy([(s) => sortAscending ? OrderingTerm.asc(s.totalAmount) : OrderingTerm.desc(s.totalAmount)]);
          break;
        case 'status':
          query.orderBy([(s) => sortAscending ? OrderingTerm.asc(s.status) : OrderingTerm.desc(s.status)]);
          break;
        case 'saleDate':
          query.orderBy([(s) => sortAscending ? OrderingTerm.asc(s.saleDate) : OrderingTerm.desc(s.saleDate)]);
          break;
        default:
          query.orderBy([(s) => sortAscending ? OrderingTerm.asc(s.createdAt) : OrderingTerm.desc(s.createdAt)]);
      }

      final sales = await query.get();
      final models = await Future.wait(sales.map((s) => _buildSaleModel(s)));

      AppLogger.i('Sales fetched: ${sales.length} (page $page)');
      return Success(models);
    } catch (e, stack) {
      AppLogger.e('Failed to fetch sales', e, stack);
      return Failure(AppException('Failed to fetch sales', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<List<SaleModel>>> search(String query, {
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) async {
    try {
      final searchTerm = '%${query.toLowerCase()}%';
      final offset = (page - 1) * pageSize;

      final searchQuery = _db.select(_db.sales)
        ..where((s) => s.isDeleted.equals(false) & (
          s.invoiceNumber.lower().like(searchTerm)
        ))
        ..orderBy([(s) => OrderingTerm.desc(s.createdAt)])
        ..limit(pageSize, offset: offset);

      final sales = await searchQuery.get();
      final models = await Future.wait(sales.map((s) => _buildSaleModel(s)));

      AppLogger.i('Sales search: ${models.length} results for "$query"');
      return Success(models);
    } catch (e, stack) {
      AppLogger.e('Failed to search sales', e, stack);
      return Failure(AppException('Failed to search sales', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<int>> getTotalCount({
    String? status,
    String? paymentStatus,
    String? customerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final query = _db.select(_db.sales)
        ..where((s) => s.isDeleted.equals(false));

      if (status != null && status.isNotEmpty) {
        query.where((s) => s.status.equals(status));
      }
      if (paymentStatus != null && paymentStatus.isNotEmpty) {
        query.where((s) => s.paymentStatus.equals(paymentStatus));
      }
      if (customerId != null && customerId.isNotEmpty) {
        query.where((s) => s.customerId.equals(customerId));
      }
      if (startDate != null) {
        query.where((s) => s.saleDate.isBiggerThanValue(startDate));
      }
      if (endDate != null) {
        query.where((s) => s.saleDate.isSmallerThanValue(endDate));
      }

      final count = await query.get().then((r) => r.length);
      return Success(count);
    } catch (e, stack) {
      AppLogger.e('Failed to get sale count', e, stack);
      return Failure(AppException('Failed to get sale count', originalError: e, stackTrace: stack));
    }
  }

  Future<String> _generateInvoiceNumber() async {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    if (dateStr != _lastInvoiceDate) {
      _invoiceSequence = 0;
      _lastInvoiceDate = dateStr;
    }

    _invoiceSequence++;
    final seq = _invoiceSequence.toString().padLeft(4, '0');
    return 'INV-$dateStr-$seq';
  }

  Future<SaleModel?> _getSaleById(String id) async {
    final sale = await (_db.select(_db.sales)..where((s) => s.id.equals(id))).getSingleOrNull();
    if (sale == null) return null;
    return _buildSaleModel(sale);
  }

  Future<SaleModel> _buildSaleModel(Sale s) async {
    String? customerName;
    if (s.customerId != null && s.customerId!.isNotEmpty) {
      final customer = await (_db.select(_db.customers)..where((c) => c.id.equals(s.customerId!))).getSingleOrNull();
      customerName = customer?.name;
    }

    final items = await (_db.select(_db.salesItems)..where((si) => si.saleId.equals(s.id))).get();
    final itemModels = await Future.wait(items.map((si) async {
      String? productName;
      if (si.productId.isNotEmpty) {
        final product = await (_db.select(_db.products)..where((pr) => pr.id.equals(si.productId))).getSingleOrNull();
        productName = product?.name;
      }
      return SaleItemModel.fromSaleItem(si, productName: productName);
    }));

    return SaleModel.fromSale(s,
      customerName: customerName,
      createdByName: null,
      items: itemModels,
    );
  }

}
