// ignore_for_file: unused_local_variable

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahibz_inventory/core/result.dart';
import 'package:sahibz_inventory/core/exceptions.dart';
import 'package:sahibz_inventory/core/logger.dart';
import 'package:sahibz_inventory/database/database.dart';
import 'package:sahibz_inventory/features/reports/models/report_models.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ReportRepository(database: db);
});

class ReportRepository {
  final AppDatabase _db;

  ReportRepository({required AppDatabase database}) : _db = database;

  Future<Result<List<InventoryReportRow>>> getInventoryReport({ReportFilter? filters}) async {
    try {
      final products = await (_db.select(_db.products)..where((p) => p.isDeleted.equals(false))).get();
      final results = <InventoryReportRow>[];

      for (final product in products) {
        if (filters != null) {
          if (filters.categoryId != null && filters.categoryId!.isNotEmpty && product.categoryId != filters.categoryId) continue;
          if (filters.supplierId != null && filters.supplierId!.isNotEmpty && product.supplierId != filters.supplierId) continue;
          if (filters.status != null && filters.status!.isNotEmpty && product.status != filters.status) continue;
          if (filters.search != null && filters.search!.isNotEmpty) {
            final term = filters.search!.toLowerCase();
            if (!product.name.toLowerCase().contains(term) && !product.sku.toLowerCase().contains(term)) continue;
          }
        }

        String? categoryName;
        if (product.categoryId != null && product.categoryId!.isNotEmpty) {
          final cat = await (_db.select(_db.categories)..where((c) => c.id.equals(product.categoryId!))).getSingleOrNull();
          categoryName = cat?.name;
        }

        double totalQty = 0.0;
        final txs = await (_db.select(_db.inventoryTransactions)..where((t) => t.productId.equals(product.id))).get();
        if (txs.isNotEmpty) {
          totalQty = txs.last.balanceAfter;
        }

        results.add(InventoryReportRow(
          productId: product.id,
          productName: product.name,
          sku: product.sku,
          categoryName: categoryName,
          quantity: totalQty,
          costPrice: product.costPrice,
          sellingPrice: product.sellingPrice,
          stockValue: totalQty * product.costPrice,
          potentialRevenue: totalQty * product.sellingPrice,
          reorderLevel: product.reorderLevel,
        ));
      }

      return Success(results);
    } catch (e, stack) {
      AppLogger.e('Failed to get inventory report', e, stack);
      return Failure(AppException('Failed to generate inventory report', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<List<InventoryValuationRow>>> getInventoryValuationReport() async {
    try {
      final products = await (_db.select(_db.products)..where((p) => p.isDeleted.equals(false))).get();
      final rows = <InventoryValuationRow>[];

      for (final product in products) {
        double qty = 0.0;
        final lastTx = await (_db.select(_db.inventoryTransactions)
          ..where((t) => t.productId.equals(product.id))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
          ..limit(1)
        ).get();
        if (lastTx.isNotEmpty) qty = lastTx.first.balanceAfter;

        if (qty > 0) {
          String? categoryName;
          if (product.categoryId != null && product.categoryId!.isNotEmpty) {
            final cat = await (_db.select(_db.categories)..where((c) => c.id.equals(product.categoryId!))).getSingleOrNull();
            categoryName = cat?.name;
          }
          rows.add(InventoryValuationRow(
            productId: product.id,
            productName: product.name,
            sku: product.sku,
            categoryId: product.categoryId,
            categoryName: categoryName,
            quantity: qty,
            unitCost: product.costPrice,
            totalValue: qty * product.costPrice,
          ));
        }
      }

      return Success(rows);
    } catch (e, stack) {
      AppLogger.e('Failed to get inventory valuation report', e, stack);
      return Failure(AppException('Failed to generate inventory valuation report', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<List<StockMovementRow>>> getStockMovementReport({ReportFilter? filters}) async {
    try {
      var query = _db.select(_db.inventoryTransactions);

      if (filters != null) {
        if (filters.startDate != null) {
          query.where((t) => t.transactionDate.isBiggerThanValue(filters.startDate!));
        }
        if (filters.endDate != null) {
          query.where((t) => t.transactionDate.isSmallerThanValue(filters.endDate!));
        }
        if (filters.productId != null && filters.productId!.isNotEmpty) {
          query.where((t) => t.productId.equals(filters.productId!));
        }
      }

      query.orderBy([(t) => OrderingTerm.desc(t.transactionDate)]);

      final transactions = await query.get();
      final rows = <StockMovementRow>[];

      for (final t in transactions) {
        String? productName;
        final product = await (_db.select(_db.products)..where((p) => p.id.equals(t.productId))).getSingleOrNull();
        productName = product?.name;

        rows.add(StockMovementRow(
          transactionId: t.id,
          date: t.transactionDate,
          productName: productName ?? '',
          sku: product?.sku ?? '',
          type: t.type,
          quantity: t.quantity,
          unitPrice: t.unitPrice,
          totalPrice: t.totalPrice,
          balanceAfter: t.balanceAfter,
          reference: t.reference,
          notes: t.notes,
        ));
      }

      return Success(rows);
    } catch (e, stack) {
      AppLogger.e('Failed to get stock movement report', e, stack);
      return Failure(AppException('Failed to generate stock movement report', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<List<SalesReportRow>>> getSalesReport({ReportFilter? filters}) async {
    try {
      var query = _db.select(_db.sales)..where((s) => s.isDeleted.equals(false));

      if (filters != null) {
        if (filters.startDate != null) query.where((s) => s.saleDate.isBiggerThanValue(filters.startDate!));
        if (filters.endDate != null) query.where((s) => s.saleDate.isSmallerThanValue(filters.endDate!));
        if (filters.status != null && filters.status!.isNotEmpty) query.where((s) => s.status.equals(filters.status!));
        if (filters.customerId != null && filters.customerId!.isNotEmpty) query.where((s) => s.customerId.equals(filters.customerId!));
      }

      query.orderBy([(s) => OrderingTerm.desc(s.saleDate)]);

      final sales = await query.get();
      final rows = <SalesReportRow>[];

      for (final s in sales) {
        String? customerName;
        if (s.customerId != null && s.customerId!.isNotEmpty) {
          final c = await (_db.select(_db.customers)..where((c) => c.id.equals(s.customerId!))).getSingleOrNull();
          customerName = c?.name;
        }

        rows.add(SalesReportRow(
          invoiceNumber: s.invoiceNumber,
          saleDate: s.saleDate,
          customerName: customerName,
          subtotal: s.subtotal,
          taxAmount: s.taxAmount,
          discountAmount: s.discountAmount,
          totalAmount: s.totalAmount,
          paidAmount: s.paidAmount,
          dueAmount: s.dueAmount,
          paymentStatus: s.paymentStatus,
          status: s.status,
        ));
      }

      return Success(rows);
    } catch (e, stack) {
      AppLogger.e('Failed to get sales report', e, stack);
      return Failure(AppException('Failed to generate sales report', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<List<PurchaseReportRow>>> getPurchaseReport({ReportFilter? filters}) async {
    try {
      var query = _db.select(_db.purchases)..where((p) => p.isDeleted.equals(false));

      if (filters != null) {
        if (filters.startDate != null) query.where((p) => p.orderDate.isBiggerThanValue(filters.startDate!));
        if (filters.endDate != null) query.where((p) => p.orderDate.isSmallerThanValue(filters.endDate!));
        if (filters.status != null && filters.status!.isNotEmpty) query.where((p) => p.status.equals(filters.status!));
        if (filters.supplierId != null && filters.supplierId!.isNotEmpty) query.where((p) => p.supplierId.equals(filters.supplierId!));
      }

      query.orderBy([(p) => OrderingTerm.desc(p.orderDate)]);

      final purchases = await query.get();
      final rows = <PurchaseReportRow>[];

      for (final p in purchases) {
        String? supplierName;
        if (p.supplierId.isNotEmpty) {
          final s = await (_db.select(_db.suppliers)..where((s) => s.id.equals(p.supplierId))).getSingleOrNull();
          supplierName = s?.companyName;
        }

        rows.add(PurchaseReportRow(
          orderNumber: p.orderNumber,
          orderDate: p.orderDate,
          supplierName: supplierName,
          subtotal: p.subtotal,
          taxAmount: p.taxAmount,
          discountAmount: p.discountAmount,
          shippingAmount: p.shippingAmount,
          totalAmount: p.totalAmount,
          paymentStatus: p.paymentStatus,
          status: p.status,
        ));
      }

      return Success(rows);
    } catch (e, stack) {
      AppLogger.e('Failed to get purchase report', e, stack);
      return Failure(AppException('Failed to generate purchase report', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<List<SupplierReportRow>>> getSupplierReport({ReportFilter? filters}) async {
    try {
      final suppliers = await (_db.select(_db.suppliers)..where((s) => s.isDeleted.equals(false))).get();

      final rows = <SupplierReportRow>[];
      for (final supplier in suppliers) {
        if (filters != null && filters.search != null && filters.search!.isNotEmpty) {
          if (!supplier.companyName.toLowerCase().contains(filters.search!.toLowerCase())) continue;
        }

        // Get purchase stats
        final purchases = await (_db.select(_db.purchases)
          ..where((p) => p.supplierId.equals(supplier.id) & p.isDeleted.equals(false))
        ).get();

        final totalPurchaseAmount = purchases.fold(0.0, (sum, p) => sum + p.totalAmount);
        final totalPurchases = purchases.length;
        final lastPurchaseDate = purchases.isNotEmpty ? purchases.map((p) => p.orderDate).reduce((a, b) => a.isAfter(b) ? a : b) : null;

        rows.add(SupplierReportRow(
          supplierId: supplier.id,
          companyName: supplier.companyName,
          contactPerson: supplier.contactPerson,
          phone: supplier.phone,
          email: supplier.email,
          totalPurchases: totalPurchases,
          totalAmount: totalPurchaseAmount,
          averageOrderValue: totalPurchases > 0 ? totalPurchaseAmount / totalPurchases : 0.0,
          status: supplier.status,
        ));
      }

      rows.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
      return Success(rows);
    } catch (e, stack) {
      AppLogger.e('Failed to get supplier report', e, stack);
      return Failure(AppException('Failed to generate supplier report', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<List<CustomerReportRow>>> getCustomerReport({ReportFilter? filters}) async {
    try {
      final customers = await (_db.select(_db.customers)..where((c) => c.isDeleted.equals(false))).get();

      final rows = <CustomerReportRow>[];
      for (final customer in customers) {
        if (filters != null && filters.search != null && filters.search!.isNotEmpty) {
          if (!customer.name.toLowerCase().contains(filters.search!.toLowerCase())) continue;
        }

        final sales = await (_db.select(_db.sales)
          ..where((s) => s.customerId.equals(customer.id) & s.isDeleted.equals(false))
        ).get();

        final totalSalesAmount = sales.fold(0.0, (sum, s) => sum + s.totalAmount);
        final totalSales = sales.length;
        final totalDue = sales.fold(0.0, (sum, s) => sum + s.dueAmount);
        final lastSaleDate = sales.isNotEmpty ? sales.map((s) => s.saleDate).reduce((a, b) => a.isAfter(b) ? a : b) : null;

        rows.add(CustomerReportRow(
          customerId: customer.id,
          name: customer.name,
          phone: customer.phone,
          email: customer.email,
          totalSales: totalSales,
          totalAmount: totalSalesAmount,
          averageOrderValue: totalSales > 0 ? totalSalesAmount / totalSales : 0.0,
          totalPaid: totalSalesAmount - totalDue,
          totalDue: totalDue,
          status: customer.status,
        ));
      }

      rows.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
      return Success(rows);
    } catch (e, stack) {
      AppLogger.e('Failed to get customer report', e, stack);
      return Failure(AppException('Failed to generate customer report', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<FinancialSummaryRow>> getFinancialSummary({ReportFilter? filters}) async {
    try {
      final now = DateTime.now();
      final startDate = filters?.startDate ?? DateTime(now.year, now.month, 1);
      final endDate = filters?.endDate ?? now;

      // Total sales in period
      final salesQuery = _db.select(_db.sales)
        ..where((s) => s.isDeleted.equals(false) & s.saleDate.isBiggerThanValue(startDate) & s.saleDate.isSmallerThanValue(endDate));
      final sales = await salesQuery.get();
      final totalSales = sales.fold(0.0, (sum, s) => sum + s.totalAmount);
      final totalPaid = sales.fold(0.0, (sum, s) => sum + s.paidAmount);
      final totalDue = sales.fold(0.0, (sum, s) => sum + s.dueAmount);
      final salesCount = sales.length;

      // Total purchases in period
      final purchasesQuery = _db.select(_db.purchases)
        ..where((p) => p.isDeleted.equals(false) & p.orderDate.isBiggerThanValue(startDate) & p.orderDate.isSmallerThanValue(endDate));
      final purchases = await purchasesQuery.get();
      final totalPurchases = purchases.fold(0.0, (sum, p) => sum + p.totalAmount);
      final purchasesCount = purchases.length;

      // Inventory value
      final products = await (_db.select(_db.products)..where((p) => p.isDeleted.equals(false))).get();
      double inventoryValue = 0.0;
      for (final product in products) {
        final lastTx = await (_db.select(_db.inventoryTransactions)
          ..where((t) => t.productId.equals(product.id))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
          ..limit(1)
        ).get();
        if (lastTx.isNotEmpty) {
          inventoryValue += lastTx.first.balanceAfter * product.costPrice;
        }
      }

      final profit = totalSales - totalPurchases;

      return Success(FinancialSummaryRow(
        totalRevenue: totalSales,
        totalCost: totalPurchases,
        grossProfit: profit,
        grossMargin: totalSales > 0 ? (profit / totalSales * 100) : 0.0,
        totalExpenses: 0.0,
        netProfit: profit,
        netMargin: totalSales > 0 ? (profit / totalSales * 100) : 0.0,
        totalTax: sales.fold(0.0, (sum, s) => sum + s.taxAmount),
        totalDiscount: sales.fold(0.0, (sum, s) => sum + s.discountAmount),
        outstandingReceivables: totalDue,
        outstandingPayables: 0.0,
      ));
    } catch (e, stack) {
      AppLogger.e('Failed to get financial summary', e, stack);
      return Failure(AppException('Failed to generate financial summary', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<List<AuditReportRow>>> getAuditReport({ReportFilter? filters}) async {
    try {
      var query = _db.select(_db.auditLogs);

      if (filters != null) {
        if (filters.startDate != null) query.where((a) => a.performedAt.isBiggerThanValue(filters.startDate!));
        if (filters.endDate != null) query.where((a) => a.performedAt.isSmallerThanValue(filters.endDate!));
      }

      query.orderBy([(a) => OrderingTerm.desc(a.performedAt)]);

      final logs = await query.get();
      final rows = <AuditReportRow>[];

      for (final log in logs) {
        rows.add(AuditReportRow(
          id: log.id,
          performedAt: log.performedAt,
          userName: null,
          action: log.action,
          entityType: log.entityType,
          entityId: log.entityId,
          details: log.details,
        ));
      }

      return Success(rows);
    } catch (e, stack) {
      AppLogger.e('Failed to get audit report', e, stack);
      return Failure(AppException('Failed to generate audit report', originalError: e, stackTrace: stack));
    }
  }
}
