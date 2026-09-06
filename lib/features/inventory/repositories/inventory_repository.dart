import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:sahibz_inventory/core/result.dart';
import 'package:sahibz_inventory/core/exceptions.dart';
import 'package:sahibz_inventory/core/logger.dart';
import 'package:sahibz_inventory/core/constants.dart';
import 'package:sahibz_inventory/database/database.dart';
import 'package:sahibz_inventory/features/inventory/models/inventory_model.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return InventoryRepository(database: db);
});

class InventoryRepository {
  final AppDatabase _db;
  final Uuid _uuid;

  InventoryRepository({
    required AppDatabase database,
  })  : _db = database,
        _uuid = const Uuid();

  Future<Result<InventoryTransactionModel>> stockIn({
    required String productId,
    required double quantity,
    double unitPrice = 0.0,
    String? reference,
    String? referenceType,
    String? notes,
    String? batchNumber,
    String? serialNumber,
    String? performedBy,
  }) async {
    try {
      if (quantity <= 0) {
        return const Failure(ValidationException('Stock in quantity must be greater than zero'));
      }

      final product = await _validateProduct(productId);
      if (product == null) {
        return const Failure(NotFoundException('Product not found'));
      }

      final currentBalance = await _getCurrentBalance(productId);
      final balanceAfter = currentBalance + quantity;
      final totalPrice = quantity * unitPrice;

      final id = _uuid.v4();
      final now = DateTime.now();

      await _db.into(_db.inventoryTransactions).insert(InventoryTransactionsCompanion.insert(
        id: id,
        productId: productId,

        type: 'stock_in',
        quantity: quantity,
        unitPrice: Value(unitPrice),
        totalPrice: Value(totalPrice),
        balanceBefore: Value(currentBalance),
        balanceAfter: Value(balanceAfter),
        reference: reference != null ? Value(reference) : const Value.absent(),
        referenceType: referenceType != null ? Value(referenceType) : const Value.absent(),
        notes: notes != null ? Value(notes) : const Value.absent(),
        batchNumber: batchNumber != null ? Value(batchNumber) : const Value.absent(),
        serialNumber: serialNumber != null ? Value(serialNumber) : const Value.absent(),
        performedBy: performedBy != null ? Value(performedBy) : const Value.absent(),
        transactionDate: Value(now),
      ));

      final transaction = await _getTransactionById(id);
      if (transaction == null) {
        return const Failure(NotFoundException('Transaction created but not found'));
      }

      AppLogger.i('Stock in: ${product.name} x $quantity');
      return Success(transaction);
    } catch (e, stack) {
      AppLogger.e('Failed to record stock in', e, stack);
      return Failure(AppException('Failed to record stock in', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<InventoryTransactionModel>> stockOut({
    required String productId,
    required double quantity,
    double unitPrice = 0.0,
    String? reference,
    String? referenceType,
    String? notes,
    String? batchNumber,
    String? serialNumber,
    String? performedBy,
  }) async {
    try {
      if (quantity <= 0) {
        return const Failure(ValidationException('Stock out quantity must be greater than zero'));
      }

      final product = await _validateProduct(productId);
      if (product == null) {
        return const Failure(NotFoundException('Product not found'));
      }

      final currentBalance = await _getCurrentBalance(productId);
      if (currentBalance < quantity) {
        return Failure(ValidationException(
          'Insufficient stock. Available: $currentBalance, Requested: $quantity',
        ));
      }

      final balanceAfter = currentBalance - quantity;
      final totalPrice = quantity * unitPrice;

      final id = _uuid.v4();
      final now = DateTime.now();

      await _db.into(_db.inventoryTransactions).insert(InventoryTransactionsCompanion.insert(
        id: id,
        productId: productId,

        type: 'stock_out',
        quantity: -quantity,
        unitPrice: Value(unitPrice),
        totalPrice: Value(totalPrice),
        balanceBefore: Value(currentBalance),
        balanceAfter: Value(balanceAfter),
        reference: reference != null ? Value(reference) : const Value.absent(),
        referenceType: referenceType != null ? Value(referenceType) : const Value.absent(),
        notes: notes != null ? Value(notes) : const Value.absent(),
        batchNumber: batchNumber != null ? Value(batchNumber) : const Value.absent(),
        serialNumber: serialNumber != null ? Value(serialNumber) : const Value.absent(),
        performedBy: performedBy != null ? Value(performedBy) : const Value.absent(),
        transactionDate: Value(now),
      ));

      final transaction = await _getTransactionById(id);
      if (transaction == null) {
        return const Failure(NotFoundException('Transaction created but not found'));
      }

      AppLogger.i('Stock out: ${product.name} x $quantity');
      return Success(transaction);
    } catch (e, stack) {
      AppLogger.e('Failed to record stock out', e, stack);
      return Failure(AppException('Failed to record stock out', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<InventoryTransactionModel>> adjustStock({
    required String productId,
    required double newQuantity,
    String? reason,
    String? performedBy,
  }) async {
    try {
      final product = await _validateProduct(productId);
      if (product == null) {
        return const Failure(NotFoundException('Product not found'));
      }

      final currentBalance = await _getCurrentBalance(productId);
      final adjustmentAmount = newQuantity - currentBalance;

      if (adjustmentAmount == 0) {
        return Failure(ValidationException('No adjustment needed. Current balance is already $currentBalance'));
      }

      final id = _uuid.v4();
      final now = DateTime.now();

      await _db.into(_db.inventoryTransactions).insert(InventoryTransactionsCompanion.insert(
        id: id,
        productId: productId,

        type: 'adjustment',
        quantity: adjustmentAmount,
        unitPrice: const Value(0.0),
        totalPrice: const Value(0.0),
        balanceBefore: Value(currentBalance),
        balanceAfter: Value(newQuantity),
        reference: reason != null ? Value(reason) : const Value.absent(),
        referenceType: const Value('adjustment'),
        notes: reason != null ? Value('Adjustment: $reason') : const Value.absent(),
        performedBy: performedBy != null ? Value(performedBy) : const Value.absent(),
        transactionDate: Value(now),
      ));

      final transaction = await _getTransactionById(id);
      if (transaction == null) {
        return const Failure(NotFoundException('Adjustment transaction created but not found'));
      }

      AppLogger.i('Stock adjustment: ${product.name} ($currentBalance -> $newQuantity)');
      return Success(transaction);
    } catch (e, stack) {
      AppLogger.e('Failed to adjust stock', e, stack);
      return Failure(AppException('Failed to adjust stock', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<List<InventoryTransactionModel>>> transferStock({
    required String productId,
    required double quantity,
    String? notes,
    String? performedBy,
  }) async {
    try {
      if (quantity <= 0) {
        return const Failure(ValidationException('Transfer quantity must be greater than zero'));
      }

      final product = await _validateProduct(productId);
      if (product == null) {
        return const Failure(NotFoundException('Product not found'));
      }

      final sourceBalance = await _getCurrentBalance(productId);
      if (sourceBalance < quantity) {
        return Failure(ValidationException(
          'Insufficient stock. Available: $sourceBalance, Requested: $quantity',
        ));
      }

      final now = DateTime.now();
      final transferRef = _uuid.v4();

      final outId = _uuid.v4();
      final outBalanceAfter = sourceBalance - quantity;

      await _db.into(_db.inventoryTransactions).insert(InventoryTransactionsCompanion.insert(
        id: outId,
        productId: productId,

        type: 'transfer_out',
        quantity: -quantity,
        unitPrice: const Value(0.0),
        totalPrice: const Value(0.0),
        balanceBefore: Value(sourceBalance),
        balanceAfter: Value(outBalanceAfter),
        reference: Value(transferRef),
        referenceType: const Value('transfer'),
        notes: notes != null ? Value(notes) : const Value.absent(),
        performedBy: performedBy != null ? Value(performedBy) : const Value.absent(),
        transactionDate: Value(now),
      ));

      final inId = _uuid.v4();

      await _db.into(_db.inventoryTransactions).insert(InventoryTransactionsCompanion.insert(
        id: inId,
        productId: productId,

        type: 'transfer_in',
        quantity: quantity,
        unitPrice: const Value(0.0),
        totalPrice: const Value(0.0),
        balanceBefore: Value(outBalanceAfter),
        balanceAfter: Value(sourceBalance),
        reference: Value(transferRef),
        referenceType: const Value('transfer'),
        notes: notes != null ? Value(notes) : const Value.absent(),
        performedBy: performedBy != null ? Value(performedBy) : const Value.absent(),
        transactionDate: Value(now),
      ));

      final outTx = await _getTransactionById(outId);
      final inTx = await _getTransactionById(inId);

      final transactions = <InventoryTransactionModel>[];
      if (outTx != null) transactions.add(outTx);
      if (inTx != null) transactions.add(inTx);

      AppLogger.i('Stock transfer: ${product.name} x $quantity');
      return Success(transactions);
    } catch (e, stack) {
      AppLogger.e('Failed to transfer stock', e, stack);
      return Failure(AppException('Failed to transfer stock', originalError: e, stackTrace: stack));
    }
  }

  static const _linkedReferenceTypes = {'sale', 'sale_cancel', 'purchase'};

  Future<void> _recomputeBalances(String productId) async {
    final txs = await (_db.select(_db.inventoryTransactions)
      ..where((t) => t.productId.equals(productId))
      ..orderBy([
        (t) => OrderingTerm.asc(t.transactionDate),
        (t) => OrderingTerm.asc(t.createdAt),
      ])
    ).get();

    double running = 0.0;
    for (final t in txs) {
      final after = running + t.quantity;
      if (after < -0.000001) {
        throw const ValidationException(
            'Insufficient stock. This change would drive balance negative.');
      }
      await (_db.update(_db.inventoryTransactions)
            ..where((tx) => tx.id.equals(t.id)))
          .write(InventoryTransactionsCompanion(
        balanceBefore: Value(running),
        balanceAfter: Value(after),
      ));
      running = after;
    }
  }

  Future<Result<InventoryTransactionModel>> updateTransaction({
    required String id,
    required double quantity,
    double? unitPrice,
    String? notes,
    String? batchNumber,
    String? serialNumber,
  }) async {
    try {
      final existing = await (_db.select(_db.inventoryTransactions)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (existing == null) {
        return const Failure(NotFoundException('Transaction not found'));
      }
      if (existing.referenceType != null &&
          _linkedReferenceTypes.contains(existing.referenceType)) {
        return const Failure(ValidationException(
            'Linked to a sale or purchase. Reverse it there instead.'));
      }

      final price = unitPrice ?? existing.unitPrice;
      await _db.transaction(() async {
        await (_db.update(_db.inventoryTransactions)
              ..where((t) => t.id.equals(id)))
            .write(InventoryTransactionsCompanion(
          quantity: Value(quantity),
          unitPrice: Value(price),
          totalPrice: Value(quantity.abs() * price),
          notes: notes != null ? Value(notes) : const Value.absent(),
          batchNumber:
              batchNumber != null ? Value(batchNumber) : const Value.absent(),
          serialNumber:
              serialNumber != null ? Value(serialNumber) : const Value.absent(),
        ));
        await _recomputeBalances(existing.productId);
      });

      final transaction = await _getTransactionById(id);
      if (transaction == null) {
        return const Failure(NotFoundException('Transaction updated but not found'));
      }
      AppLogger.i('Transaction updated: $id');
      return Success(transaction);
    } on ValidationException catch (e) {
      return Failure(e);
    } catch (e, stack) {
      AppLogger.e('Failed to update transaction', e, stack);
      return Failure(AppException('Failed to update transaction',
          originalError: e, stackTrace: stack));
    }
  }

  Future<Result<void>> deleteTransaction(String id) async {
    try {
      final existing = await (_db.select(_db.inventoryTransactions)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (existing == null) {
        return const Failure(NotFoundException('Transaction not found'));
      }
      if (existing.referenceType != null &&
          _linkedReferenceTypes.contains(existing.referenceType)) {
        return const Failure(ValidationException(
            'Linked to a sale or purchase. Reverse it there instead.'));
      }

      await _db.transaction(() async {
        await (_db.delete(_db.inventoryTransactions)
              ..where((t) => t.id.equals(id)))
            .go();
        await _recomputeBalances(existing.productId);
      });

      AppLogger.i('Transaction deleted: $id');
      return const Success(null);
    } on ValidationException catch (e) {
      return Failure(e);
    } catch (e, stack) {
      AppLogger.e('Failed to delete transaction', e, stack);
      return Failure(AppException('Failed to delete transaction',
          originalError: e, stackTrace: stack));
    }
  }

  Future<Result<void>> deleteProductInventory(String productId) async {
    try {
      final product = await _validateProduct(productId);
      if (product == null) {
        return const Failure(NotFoundException('Product not found'));
      }

      await (_db.delete(_db.inventoryTransactions)
            ..where((t) => t.productId.equals(productId)))
          .go();

      AppLogger.i('All inventory deleted for product: ${product.name}');
      return const Success(null);
    } catch (e, stack) {
      AppLogger.e('Failed to delete product inventory', e, stack);
      return Failure(AppException('Failed to delete inventory',
          originalError: e, stackTrace: stack));
    }
  }

  Future<Result<List<InventoryTransactionModel>>> getTransactionHistory({
    String? productId,
    String? type,
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final query = _db.select(_db.inventoryTransactions);

      if (productId != null && productId.isNotEmpty) {
        query.where((t) => t.productId.equals(productId));
      }
      if (type != null && type.isNotEmpty) {
        if (type == 'transfer') {
          query.where((t) => t.type.like('transfer%'));
        } else {
          query.where((t) => t.type.equals(type));
        }
      }
      if (startDate != null) {
        query.where((t) => t.transactionDate.isBiggerThanValue(startDate));
      }
      if (endDate != null) {
        query.where((t) => t.transactionDate.isSmallerThanValue(endDate));
      }

      query.orderBy([(t) => OrderingTerm.desc(t.transactionDate)]);

      final offset = (page - 1) * pageSize;
      query.limit(pageSize, offset: offset);

      final transactions = await query.get();
      final models = await Future.wait(transactions.map((t) => _buildTransactionModel(t)));

      AppLogger.i('Transaction history: ${transactions.length} records');
      return Success(models);
    } catch (e, stack) {
      AppLogger.e('Failed to get transaction history', e, stack);
      return Failure(AppException('Failed to get transaction history', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<double>> getCurrentStock(String productId) async {
    try {
      final balance = await _getCurrentBalance(productId);
      return Success(balance);
    } catch (e, stack) {
      AppLogger.e('Failed to get current stock', e, stack);
      return Failure(AppException('Failed to get current stock', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<List<StockSummaryModel>>> getAllCurrentStock({
    String? searchQuery,
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) async {
    try {
      final subquery = _db.selectOnly(_db.inventoryTransactions)
        ..addColumns([
          _db.inventoryTransactions.productId,
          _db.inventoryTransactions.balanceAfter.max(),
        ])
        ..groupBy([_db.inventoryTransactions.productId]);

      final rows = await subquery.get();

      final dateQuery = _db.selectOnly(_db.inventoryTransactions)
        ..addColumns([
          _db.inventoryTransactions.productId,
          _db.inventoryTransactions.transactionDate.max(),
        ])
        ..groupBy([_db.inventoryTransactions.productId]);
      final dateRows = await dateQuery.get();
      final lastUpdatedMap = <String, DateTime>{};
      for (final row in dateRows) {
        final productId = row.read(_db.inventoryTransactions.productId);
        final date = row.read(_db.inventoryTransactions.transactionDate.max());
        if (productId != null && date != null) {
          lastUpdatedMap[productId] = date;
        }
      }

      final stockMap = <String, StockSummaryModel>{};

      for (final row in rows) {
        final productId = row.read(_db.inventoryTransactions.productId)!;
        final balance = row.read(_db.inventoryTransactions.balanceAfter.max()) ?? 0.0;

        if (balance <= 0 && searchQuery == null) continue;

        final product = await (_db.select(_db.products)..where((p) => p.id.equals(productId))).getSingleOrNull();
        if (product == null || product.isDeleted) continue;

        if (searchQuery != null && searchQuery.isNotEmpty) {
          final term = searchQuery.toLowerCase();
          if (!product.name.toLowerCase().contains(term) &&
              !product.sku.toLowerCase().contains(term)) {
            continue;
          }
        }

        stockMap[productId] = StockSummaryModel(
          productId: product.id,
          productName: product.name,
          productSku: product.sku,
          totalQuantity: balance,
          reorderLevel: product.reorderLevel,
          costPrice: product.costPrice,
          sellingPrice: product.sellingPrice,
          lastUpdated: lastUpdatedMap[productId],
        );
      }

      final stocks = stockMap.values.toList()
        ..sort((a, b) => a.productName.compareTo(b.productName));

      final offset = (page - 1) * pageSize;
      final paginated = stocks.skip(offset).take(pageSize).toList();

      return Success(paginated);
    } catch (e, stack) {
      AppLogger.e('Failed to get current stock', e, stack);
      return Failure(AppException('Failed to get current stock', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<List<StockSummaryModel>>> getLowStockItems() async {
    try {
      final products = await (_db.select(_db.products)
        ..where((p) => p.isDeleted.equals(false) & p.reorderLevel.isBiggerThanValue(0.0))
      ).get();

      final lowStockItems = <StockSummaryModel>[];

      for (final product in products) {
        final lastTx = await (_db.select(_db.inventoryTransactions)
          ..where((t) => t.productId.equals(product.id))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
          ..limit(1)
        ).get();

        if (lastTx.isNotEmpty) {
          final balance = lastTx.first.balanceAfter;
          if (balance > 0 && balance <= product.reorderLevel) {
            lowStockItems.add(StockSummaryModel(
              productId: product.id,
              productName: product.name,
              productSku: product.sku,
              totalQuantity: balance,
              reorderLevel: product.reorderLevel,
              costPrice: product.costPrice,
              sellingPrice: product.sellingPrice,
              lastUpdated: lastTx.first.transactionDate,
            ));
          }
        }
      }

      lowStockItems.sort((a, b) => a.totalQuantity.compareTo(b.totalQuantity));
      return Success(lowStockItems);
    } catch (e, stack) {
      AppLogger.e('Failed to get low stock items', e, stack);
      return Failure(AppException('Failed to get low stock items', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<List<StockSummaryModel>>> getOutOfStockItems() async {
    try {
      final products = await (_db.select(_db.products)
        ..where((p) => p.isDeleted.equals(false))
      ).get();

      const zeroBalance = 0.0;
      final outOfStockItems = <StockSummaryModel>[];

      for (final product in products) {
        final lastTx = await (_db.select(_db.inventoryTransactions)
          ..where((t) => t.productId.equals(product.id))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
          ..limit(1)
        ).get();

        if (lastTx.isNotEmpty && lastTx.first.balanceAfter <= zeroBalance) {
          outOfStockItems.add(StockSummaryModel(
            productId: product.id,
            productName: product.name,
            productSku: product.sku,
            totalQuantity: lastTx.first.balanceAfter,
            reorderLevel: product.reorderLevel,
            costPrice: product.costPrice,
            sellingPrice: product.sellingPrice,
            lastUpdated: lastTx.first.transactionDate,
          ));
        }
      }

      outOfStockItems.sort((a, b) => a.productName.compareTo(b.productName));
      return Success(outOfStockItems);
    } catch (e, stack) {
      AppLogger.e('Failed to get out of stock items', e, stack);
      return Failure(AppException('Failed to get out of stock items', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<int>> getTotalTransactionCount({
    String? productId,
    String? type,
  }) async {
    try {
      final query = _db.select(_db.inventoryTransactions);

      if (productId != null && productId.isNotEmpty) {
        query.where((t) => t.productId.equals(productId));
      }
      if (type != null && type.isNotEmpty) {
        if (type == 'transfer') {
          query.where((t) => t.type.like('transfer%'));
        } else {
          query.where((t) => t.type.equals(type));
        }
      }

      final count = await query.get().then((r) => r.length);
      return Success(count);
    } catch (e, stack) {
      AppLogger.e('Failed to get transaction count', e, stack);
      return Failure(AppException('Failed to get transaction count', originalError: e, stackTrace: stack));
    }
  }

  Future<double> _getCurrentBalance(String productId) async {
    final lastTx = await (_db.select(_db.inventoryTransactions)
      ..where((t) => t.productId.equals(productId))
      ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
      ..limit(1)
    ).get();

    if (lastTx.isEmpty) return 0.0;
    return lastTx.first.balanceAfter;
  }

  Future<Product?> _validateProduct(String productId) async {
    return await (_db.select(_db.products)..where((p) => p.id.equals(productId) & p.isDeleted.equals(false))).getSingleOrNull();
  }

  Future<InventoryTransactionModel?> _getTransactionById(String id) async {
    final t = await (_db.select(_db.inventoryTransactions)..where((tx) => tx.id.equals(id))).getSingleOrNull();
    if (t == null) return null;
    return _buildTransactionModel(t);
  }

  Future<InventoryTransactionModel> _buildTransactionModel(InventoryTransaction t) async {
    String? productName;
    final product = await (_db.select(_db.products)..where((p) => p.id.equals(t.productId))).getSingleOrNull();
    productName = product?.name;

    return InventoryTransactionModel.fromInventoryTransaction(
      t,
      productName: productName,
    );
  }
}
