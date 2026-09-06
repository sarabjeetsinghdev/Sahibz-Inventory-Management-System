import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:sahibz_inventory/core/result.dart';
import 'package:sahibz_inventory/core/exceptions.dart';
import 'package:sahibz_inventory/core/logger.dart';
import 'package:sahibz_inventory/core/constants.dart';
import 'package:sahibz_inventory/database/database.dart';
import 'package:sahibz_inventory/features/purchases/models/purchase_model.dart';

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return PurchaseRepository(database: db);
});

class ReceiptLine {
  final String purchaseItemId;
  final double qtyAsOrdered;
  final String? substituteProductId;
  final double substituteQty;

  const ReceiptLine({
    required this.purchaseItemId,
    this.qtyAsOrdered = 0.0,
    this.substituteProductId,
    this.substituteQty = 0.0,
  });

  double get totalQty => qtyAsOrdered + substituteQty;
}

class PurchaseRepository {
  final AppDatabase _db;
  final Uuid _uuid;
  int _orderSequence = 0;
  String _lastOrderDate = '';

  PurchaseRepository({
    required AppDatabase database,
  })  : _db = database,
        _uuid = const Uuid();

  Future<Result<PurchaseModel>> create({
    required String supplierId,
    double subtotal = 0.0,
    double taxAmount = 0.0,
    double discountAmount = 0.0,
    double shippingAmount = 0.0,
    double totalAmount = 0.0,
    String? notes,
    String? billingAddress,
    String? shippingAddress,
    String? paymentMethod,
    String paymentStatus = 'unpaid',
    required String createdBy,
    DateTime? orderDate,
    DateTime? expectedDelivery,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final id = _uuid.v4();
      final now = DateTime.now();
      final orderNumber = await _generateOrderNumber();
      final orderDt = orderDate ?? now;

      await _db.transaction(() async {
        await _db.into(_db.purchases).insert(PurchasesCompanion.insert(
          id: id,
          orderNumber: orderNumber,
          supplierId: supplierId,
          subtotal: Value(subtotal),
          taxAmount: Value(taxAmount),
          discountAmount: Value(discountAmount),
          shippingAmount: Value(shippingAmount),
          totalAmount: Value(totalAmount),
          notes: notes != null ? Value(notes) : const Value.absent(),
          billingAddress: billingAddress != null ? Value(billingAddress) : const Value.absent(),
          shippingAddress: shippingAddress != null ? Value(shippingAddress) : const Value.absent(),
          paymentMethod: paymentMethod != null ? Value(paymentMethod) : const Value.absent(),
          paymentStatus: Value(paymentStatus),
          createdBy: Value(createdBy),
          orderDate: Value(orderDt),
          expectedDelivery: expectedDelivery != null ? Value(expectedDelivery) : const Value.absent(),
        ));

        for (final item in items) {
          final itemId = _uuid.v4();
          await _db.into(_db.purchaseItems).insert(PurchaseItemsCompanion.insert(
            id: itemId,
            purchaseId: id,
            productId: item['productId'] as String,
            quantity: (item['quantity'] as num).toDouble(),
            unitPrice: (item['unitPrice'] as num).toDouble(),
            taxRate: Value((item['taxRate'] as num?)?.toDouble() ?? 0.0),
            taxAmount: Value((item['taxAmount'] as num?)?.toDouble() ?? 0.0),
            discountAmount: Value((item['discountAmount'] as num?)?.toDouble() ?? 0.0),
            totalPrice: (item['totalPrice'] as num).toDouble(),
          ));
        }
      });

      final purchase = await _getPurchaseById(id);
      if (purchase == null) {
        return const Failure(NotFoundException('Purchase created but not found'));
      }

      AppLogger.i('Purchase created: $orderNumber');
      return Success(purchase);
    } on DatabaseException catch (e) {
      AppLogger.e('Database error creating purchase', e);
      return Failure(e);
    } catch (e, stack) {
      AppLogger.e('Failed to create purchase', e, stack);
      return Failure(AppException('Failed to create purchase', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<PurchaseModel>> update({
    required String id,
    String? supplierId,
    double? subtotal,
    double? taxAmount,
    double? discountAmount,
    double? shippingAmount,
    double? totalAmount,
    String? notes,
    String? billingAddress,
    String? shippingAddress,
    String? paymentMethod,
    String? paymentStatus,
    DateTime? expectedDelivery,
    List<Map<String, dynamic>>? items,
  }) async {
    try {
      final existing = await (_db.select(_db.purchases)..where((p) => p.id.equals(id))).getSingleOrNull();
      if (existing == null) {
        return const Failure(NotFoundException('Purchase not found'));
      }
      if (existing.status != 'pending') {
        return const Failure(ValidationException('Only pending purchases can be edited'));
      }

      final now = DateTime.now();
      await (_db.update(_db.purchases)..where((p) => p.id.equals(id))).write(PurchasesCompanion(
        supplierId: supplierId != null ? Value(supplierId) : const Value.absent(),
        subtotal: subtotal != null ? Value(subtotal) : const Value.absent(),
        taxAmount: taxAmount != null ? Value(taxAmount) : const Value.absent(),
        discountAmount: discountAmount != null ? Value(discountAmount) : const Value.absent(),
        shippingAmount: shippingAmount != null ? Value(shippingAmount) : const Value.absent(),
        totalAmount: totalAmount != null ? Value(totalAmount) : const Value.absent(),
        notes: notes != null ? Value(notes) : const Value.absent(),
        billingAddress: billingAddress != null ? Value(billingAddress) : const Value.absent(),
        shippingAddress: shippingAddress != null ? Value(shippingAddress) : const Value.absent(),
        paymentMethod: paymentMethod != null ? Value(paymentMethod) : const Value.absent(),
        paymentStatus: paymentStatus != null ? Value(paymentStatus) : const Value.absent(),
        expectedDelivery: expectedDelivery != null ? Value(expectedDelivery) : const Value.absent(),
        updatedAt: Value(now),
      ));

      if (items != null) {
        await (_db.delete(_db.purchaseItems)..where((pi) => pi.purchaseId.equals(id))).go();
        for (final item in items) {
          final itemId = _uuid.v4();
          await _db.into(_db.purchaseItems).insert(PurchaseItemsCompanion.insert(
            id: itemId,
            purchaseId: id,
            productId: item['productId'] as String,
            quantity: (item['quantity'] as num).toDouble(),
            unitPrice: (item['unitPrice'] as num).toDouble(),
            taxRate: Value((item['taxRate'] as num?)?.toDouble() ?? 0.0),
            taxAmount: Value((item['taxAmount'] as num?)?.toDouble() ?? 0.0),
            discountAmount: Value((item['discountAmount'] as num?)?.toDouble() ?? 0.0),
            totalPrice: item['totalPrice'].toDouble(),
          ));
        }
      }

      final purchase = await _getPurchaseById(id);
      if (purchase == null) {
        return const Failure(NotFoundException('Purchase updated but not found'));
      }

      AppLogger.i('Purchase updated: ${purchase.orderNumber}');
      return Success(purchase);
    } on DatabaseException catch (e) {
      AppLogger.e('Database error updating purchase', e);
      return Failure(DatabaseException('Failed to update purchase: ${e.message}', originalError: e));
    } catch (e, stack) {
      AppLogger.e('Failed to update purchase', e, stack);
      return Failure(AppException('Failed to update purchase', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<void>> delete(String id) async {
    try {
      final existing = await (_db.select(_db.purchases)..where((p) => p.id.equals(id))).getSingleOrNull();
      if (existing == null) {
        return const Failure(NotFoundException('Purchase not found'));
      }

      await (_db.update(_db.purchases)..where((p) => p.id.equals(id))).write(PurchasesCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ));

      AppLogger.i('Purchase soft-deleted: ${existing.orderNumber}');
      return const Success(null);
    } catch (e, stack) {
      AppLogger.e('Failed to delete purchase', e, stack);
      return Failure(AppException('Failed to delete purchase', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<PurchaseModel>> getById(String id) async {
    try {
      final purchase = await _getPurchaseById(id);
      if (purchase == null) {
        return const Failure(NotFoundException('Purchase not found'));
      }
      return Success(purchase);
    } catch (e, stack) {
      AppLogger.e('Failed to get purchase by id', e, stack);
      return Failure(AppException('Failed to get purchase', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<PurchaseModel>> approve(String id, String approvedBy) async {
    try {
      final existing = await (_db.select(_db.purchases)..where((p) => p.id.equals(id))).getSingleOrNull();
      if (existing == null) {
        return const Failure(NotFoundException('Purchase not found'));
      }
      if (existing.status != 'pending') {
        return const Failure(ValidationException('Only pending purchases can be approved'));
      }

      final now = DateTime.now();
      await (_db.update(_db.purchases)..where((p) => p.id.equals(id))).write(PurchasesCompanion(
        status: const Value('approved'),
        approvedBy: Value(approvedBy),
        updatedAt: Value(now),
      ));

      final purchase = await _getPurchaseById(id);
      AppLogger.i('Purchase approved: ${existing.orderNumber}');
      return Success(purchase!);
    } catch (e, stack) {
      AppLogger.e('Failed to approve purchase', e, stack);
      return Failure(AppException('Failed to approve purchase', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<PurchaseModel>> receive(String id,
      {required List<ReceiptLine> lines, String? performedBy}) async {
    try {
      final existing = await (_db.select(_db.purchases)..where((p) => p.id.equals(id))).getSingleOrNull();
      if (existing == null) {
        return const Failure(NotFoundException('Purchase not found'));
      }
      if (existing.status != 'approved' && existing.status != 'partially_received') {
        return const Failure(ValidationException('Only approved or partially received purchases can receive stock'));
      }

      // Pre-validate lines against items
      final items = await (_db.select(_db.purchaseItems)..where((pi) => pi.purchaseId.equals(id))).get();
      final itemMap = {for (final i in items) i.id: i};

      double totalThisReceipt = 0.0;
      for (final line in lines) {
        final item = itemMap[line.purchaseItemId];
        if (item == null) {
          return Failure(ValidationException('Unknown purchase item: ${line.purchaseItemId}'));
        }
        if (line.totalQty <= 0) continue;

        final remaining = item.quantity - item.receivedQuantity;
        if (line.totalQty > remaining + 0.0001) {
          return Failure(ValidationException(
              'Cannot receive ${line.totalQty} of "${item.productId}". Remaining: $remaining'));
        }
        if (line.substituteProductId != null && line.substituteQty > 0) {
          final sub = await (_db.select(_db.products)
                ..where((p) => p.id.equals(line.substituteProductId!) & p.isDeleted.equals(false)))
              .getSingleOrNull();
          if (sub == null) {
            return const Failure(ValidationException('Substitute product not found or inactive'));
          }
          if (sub.id == item.productId && line.qtyAsOrdered <= 0) {
            return const Failure(ValidationException('Substitute product is the same as the ordered product'));
          }
        }
        totalThisReceipt += line.totalQty;
      }
      if (totalThisReceipt <= 0) {
        return const Failure(ValidationException('Enter at least one quantity to receive'));
      }

      final now = DateTime.now();

      await _db.transaction(() async {
        for (final line in lines) {
          if (line.totalQty <= 0) continue;
          final item = itemMap[line.purchaseItemId]!;
          String? lineNote;

          Future<void> addStock(String productId, double qty) async {
            final lastTx = await (_db.select(_db.inventoryTransactions)
                  ..where((t) => t.productId.equals(productId))
                  ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
                  ..limit(1))
                .get();
            final currentBalance = lastTx.isEmpty ? 0.0 : lastTx.first.balanceAfter;
            final balanceAfter = currentBalance + qty;
            await _db.into(_db.inventoryTransactions).insert(InventoryTransactionsCompanion.insert(
              id: _uuid.v4(),
              productId: productId,
              type: 'stock_in',
              quantity: qty,
              unitPrice: Value(item.unitPrice),
              totalPrice: Value(qty * item.unitPrice),
              balanceBefore: Value(currentBalance),
              balanceAfter: Value(balanceAfter),
              reference: Value(id),
              referenceType: const Value('purchase'),
              notes: Value(lineNote ?? 'Purchase ${existing.orderNumber} received'),
              transactionDate: Value(now),
            ));
          }

          if (line.qtyAsOrdered > 0) {
            await addStock(item.productId, line.qtyAsOrdered);
          }

          if (line.substituteProductId != null && line.substituteQty > 0) {
            String? orderedName;
            String? substituteName;
            final orderedProduct = await (_db.select(_db.products)..where((p) => p.id.equals(item.productId))).getSingleOrNull();
            orderedName = orderedProduct?.name;
            final substituteProduct = await (_db.select(_db.products)..where((p) => p.id.equals(line.substituteProductId!))).getSingleOrNull();
            substituteName = substituteProduct?.name ?? line.substituteProductId;

            lineNote =
                'Received ${line.substituteQty}x [$substituteName] in place of [${orderedName ?? item.productId}]';
            await (_db.update(_db.purchaseItems)..where((pi) => pi.id.equals(item.id))).write(
              PurchaseItemsCompanion(notes: Value(lineNote)),
            );
            await addStock(line.substituteProductId!, line.substituteQty);
          }

          final newReceived = (item.receivedQuantity + line.totalQty).clamp(0.0, item.quantity);
          await (_db.update(_db.purchaseItems)..where((pi) => pi.id.equals(item.id))).write(
            PurchaseItemsCompanion(receivedQuantity: Value(newReceived)),
          );
        }

        // Refresh received state to determine status
        final refreshed = await (_db.select(_db.purchaseItems)..where((pi) => pi.purchaseId.equals(id))).get();
        final allComplete = refreshed.every((i) => i.receivedQuantity >= i.quantity - 0.0001);
        final anyReceived = refreshed.any((i) => i.receivedQuantity > 0);

        await (_db.update(_db.purchases)..where((p) => p.id.equals(id))).write(PurchasesCompanion(
          status: Value(allComplete
              ? 'received'
              : (anyReceived ? 'partially_received' : existing.status)),
          receivedDate: allComplete ? Value(now) : const Value.absent(),
          updatedAt: Value(now),
        ));
      });

      final purchase = await _getPurchaseById(id);
      AppLogger.i('Purchase receipt recorded: ${existing.orderNumber}');
      return Success(purchase!);
    } catch (e, stack) {
      AppLogger.e('Failed to receive purchase', e, stack);
      return Failure(AppException('Failed to receive purchase', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<PurchaseModel>> closeOrder(String id, {String? performedBy}) async {
    try {
      final existing = await (_db.select(_db.purchases)..where((p) => p.id.equals(id))).getSingleOrNull();
      if (existing == null) {
        return const Failure(NotFoundException('Purchase not found'));
      }
      if (existing.status != 'partially_received') {
        return const Failure(ValidationException('Only partially received purchases can be closed'));
      }

      await (_db.update(_db.purchases)..where((p) => p.id.equals(id))).write(PurchasesCompanion(
        status: const Value('closed'),
        updatedAt: Value(DateTime.now()),
      ));

      final purchase = await _getPurchaseById(id);
      AppLogger.i('Purchase closed with shortfall: ${existing.orderNumber}');
      return Success(purchase!);
    } catch (e, stack) {
      AppLogger.e('Failed to close purchase', e, stack);
      return Failure(AppException('Failed to close purchase', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<PurchaseModel>> cancel(String id) async {
    try {
      final existing = await (_db.select(_db.purchases)..where((p) => p.id.equals(id))).getSingleOrNull();
      if (existing == null) {
        return const Failure(NotFoundException('Purchase not found'));
      }
      if (existing.status != 'pending' && existing.status != 'approved') {
        return const Failure(ValidationException('Purchase cannot be cancelled in its current state'));
      }

      await (_db.update(_db.purchases)..where((p) => p.id.equals(id))).write(PurchasesCompanion(
        status: const Value('cancelled'),
        updatedAt: Value(DateTime.now()),
      ));

      final purchase = await _getPurchaseById(id);
      AppLogger.i('Purchase cancelled: ${existing.orderNumber}');
      return Success(purchase!);
    } catch (e, stack) {
      AppLogger.e('Failed to cancel purchase', e, stack);
      return Failure(AppException('Failed to cancel purchase', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<List<PurchaseModel>>> getAll({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
    String? status,
    String? supplierId,
    DateTime? startDate,
    DateTime? endDate,
    String sortBy = 'createdAt',
    bool sortAscending = false,
  }) async {
    try {
      final query = _db.select(_db.purchases)
        ..where((p) => p.isDeleted.equals(false));

      if (status != null && status.isNotEmpty) {
        query.where((p) => p.status.equals(status));
      }
      if (supplierId != null && supplierId.isNotEmpty) {
        query.where((p) => p.supplierId.equals(supplierId));
      }
      if (startDate != null) {
        query.where((p) => p.orderDate.isBiggerThanValue(startDate));
      }
      if (endDate != null) {
        query.where((p) => p.orderDate.isSmallerThanValue(endDate));
      }

      // final totalCount = await query.get().then((r) => r.length);
      final offset = (page - 1) * pageSize;
      query.limit(pageSize, offset: offset);

      switch (sortBy) {
        case 'orderNumber':
          query.orderBy([(p) => sortAscending ? OrderingTerm.asc(p.orderNumber) : OrderingTerm.desc(p.orderNumber)]);
          break;
        case 'totalAmount':
          query.orderBy([(p) => sortAscending ? OrderingTerm.asc(p.totalAmount) : OrderingTerm.desc(p.totalAmount)]);
          break;
        case 'status':
          query.orderBy([(p) => sortAscending ? OrderingTerm.asc(p.status) : OrderingTerm.desc(p.status)]);
          break;
        case 'orderDate':
          query.orderBy([(p) => sortAscending ? OrderingTerm.asc(p.orderDate) : OrderingTerm.desc(p.orderDate)]);
          break;
        default:
          query.orderBy([(p) => sortAscending ? OrderingTerm.asc(p.createdAt) : OrderingTerm.desc(p.createdAt)]);
      }

      final purchases = await query.get();
      final models = await Future.wait(purchases.map((p) => _buildPurchaseModel(p)));

      AppLogger.i('Purchases fetched: ${purchases.length} (page $page)');
      return Success(models);
    } catch (e, stack) {
      AppLogger.e('Failed to fetch purchases', e, stack);
      return Failure(AppException('Failed to fetch purchases', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<List<PurchaseModel>>> search(String query, {
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) async {
    try {
      final searchTerm = '%${query.toLowerCase()}%';
      final offset = (page - 1) * pageSize;

      final searchQuery = _db.select(_db.purchases)
        ..where((p) => p.isDeleted.equals(false) & (
          p.orderNumber.lower().like(searchTerm)
        ))
        ..orderBy([(p) => OrderingTerm.desc(p.createdAt)])
        ..limit(pageSize, offset: offset);

      final purchases = await searchQuery.get();
      final models = await Future.wait(purchases.map((p) => _buildPurchaseModel(p)));

      AppLogger.i('Purchases search: ${models.length} results for "$query"');
      return Success(models);
    } catch (e, stack) {
      AppLogger.e('Failed to search purchases', e, stack);
      return Failure(AppException('Failed to search purchases', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<int>> getTotalCount({
    String? status,
    String? supplierId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final query = _db.select(_db.purchases)
        ..where((p) => p.isDeleted.equals(false));

      if (status != null && status.isNotEmpty) {
        query.where((p) => p.status.equals(status));
      }
      if (supplierId != null && supplierId.isNotEmpty) {
        query.where((p) => p.supplierId.equals(supplierId));
      }
      if (startDate != null) {
        query.where((p) => p.orderDate.isBiggerThanValue(startDate));
      }
      if (endDate != null) {
        query.where((p) => p.orderDate.isSmallerThanValue(endDate));
      }

      final count = await query.get().then((r) => r.length);
      return Success(count);
    } catch (e, stack) {
      AppLogger.e('Failed to get purchase count', e, stack);
      return Failure(AppException('Failed to get purchase count', originalError: e, stackTrace: stack));
    }
  }

  Future<String> _generateOrderNumber() async {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    if (dateStr != _lastOrderDate) {
      _orderSequence = 0;
      _lastOrderDate = dateStr;
    }

    _orderSequence++;
    final seq = _orderSequence.toString().padLeft(4, '0');
    return 'PO-$dateStr-$seq';
  }

  Future<PurchaseModel?> _getPurchaseById(String id) async {
    final purchase = await (_db.select(_db.purchases)..where((p) => p.id.equals(id))).getSingleOrNull();
    if (purchase == null) return null;
    return _buildPurchaseModel(purchase);
  }

  Future<PurchaseModel> _buildPurchaseModel(Purchase p) async {
    String? supplierName;
    if (p.supplierId.isNotEmpty) {
      final supplier = await (_db.select(_db.suppliers)..where((s) => s.id.equals(p.supplierId))).getSingleOrNull();
      supplierName = supplier?.companyName;
    }
    final items = await (_db.select(_db.purchaseItems)..where((pi) => pi.purchaseId.equals(p.id))).get();
    final itemModels = await Future.wait(items.map((pi) async {
      String? productName;
      if (pi.productId.isNotEmpty) {
        final product = await (_db.select(_db.products)..where((pr) => pr.id.equals(pi.productId))).getSingleOrNull();
        productName = product?.name;
      }
      return PurchaseItemModel.fromPurchaseItem(pi, productName: productName);
    }));

    return PurchaseModel.fromPurchase(p,
      supplierName: supplierName,

      createdByName: null,
      approvedByName: null,
      items: itemModels,
    );
  }


}
