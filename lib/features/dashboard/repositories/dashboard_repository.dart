import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import 'package:sahibz_inventory/core/result.dart';
import 'package:sahibz_inventory/core/exceptions.dart';
import 'package:sahibz_inventory/core/logger.dart';
import 'package:sahibz_inventory/database/database.dart';
import 'package:sahibz_inventory/features/dashboard/models/dashboard_models.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DashboardRepository(database: db);
});

class DashboardRepository {
  final AppDatabase _db;

  DashboardRepository({required AppDatabase database}) : _db = database;

  Future<Result<DashboardStats>> getDashboardStats() async {
    try {
      final tasks = await Future.wait([
        _countProducts(),
        _countCategories(),
        _countSuppliers(),
        _countCustomers(),
        _computeInventoryStats(),
        _computeTodaySales(),
        _computeMonthlySales(),
        _computeTodayPurchases(),
        _computeMonthlyPurchases(),
      ]);

      final stats = DashboardStats(
        totalProducts: tasks[0] as int,
        totalCategories: tasks[1] as int,
        totalSuppliers: tasks[2] as int,
        totalCustomers: tasks[3] as int,
        inventoryValue: (tasks[4] as _InventoryStats).value,
        lowStockProducts: (tasks[4] as _InventoryStats).lowStock,
        outOfStockProducts: (tasks[4] as _InventoryStats).outOfStock,
        todaySales: tasks[5] as double,
        monthlySales: tasks[6] as double,
        todayPurchases: tasks[7] as double,
        monthlyPurchases: tasks[8] as double,
      );

      AppLogger.i('Dashboard stats loaded successfully');
      return Success(stats);
    } catch (e, stack) {
      AppLogger.e('Failed to load dashboard stats', e, stack);
      return Failure(AppException('Failed to load dashboard stats', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<List<SalesDataPoint>>> getSalesTrend({String period = 'daily'}) async {
    try {
      final range = _getDateRange(period);
      final rows = await _db.customSelect(
        'SELECT strftime(\'%Y-%m-%d\', sale_date, \'unixepoch\') as date, '
        'SUM(total_amount) as amount '
        'FROM sales WHERE is_deleted = ? AND sale_date >= ? AND sale_date <= ? '
        'GROUP BY strftime(\'%Y-%m-%d\', sale_date, \'unixepoch\') '
        'ORDER BY strftime(\'%Y-%m-%d\', sale_date, \'unixepoch\')',
        variables: [
          Variable.withBool(false),
          Variable.withDateTime(range.start),
          Variable.withDateTime(range.end),
        ],
      ).get();

      final points = rows.map((r) {
        final dateStr = r.data['date'] as String;
        final amount = (r.data['amount'] as num?)?.toDouble() ?? 0.0;
        return SalesDataPoint(date: DateTime.parse(dateStr), amount: amount);
      }).toList();

      return Success(_fillMissingDates(points, range));
    } catch (e, stack) {
      AppLogger.e('Failed to load sales trend', e, stack);
      return Failure(AppException('Failed to load sales trend', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<List<PurchaseDataPoint>>> getPurchaseTrend({String period = 'daily'}) async {
    try {
      final range = _getDateRange(period);
      final rows = await _db.customSelect(
        'SELECT strftime(\'%Y-%m-%d\', order_date, \'unixepoch\') as date, '
        'SUM(total_amount) as amount '
        'FROM purchases WHERE is_deleted = ? AND order_date >= ? AND order_date <= ? '
        'GROUP BY strftime(\'%Y-%m-%d\', order_date, \'unixepoch\') '
        'ORDER BY strftime(\'%Y-%m-%d\', order_date, \'unixepoch\')',
        variables: [
          Variable.withBool(false),
          Variable.withDateTime(range.start),
          Variable.withDateTime(range.end),
        ],
      ).get();

      final points = rows.map((r) {
        final dateStr = r.data['date'] as String;
        final amount = (r.data['amount'] as num?)?.toDouble() ?? 0.0;
        return PurchaseDataPoint(date: DateTime.parse(dateStr), amount: amount);
      }).toList();

      return Success(_fillMissingDatesPurchase(points, range));
    } catch (e, stack) {
      AppLogger.e('Failed to load purchase trend', e, stack);
      return Failure(AppException('Failed to load purchase trend', originalError: e, stackTrace: stack));
    }
  }

  Future<Result<List<InventoryDataPoint>>> getInventoryTrend({String period = 'daily'}) async {
    try {
      final range = _getDateRange(period);
      final rows = await _db.customSelect(
        'SELECT strftime(\'%Y-%m-%d\', transaction_date, \'unixepoch\') as date, '
        'SUM(CASE WHEN type IN (\'stock_in\', \'transfer_in\') THEN quantity ELSE 0 END) - '
        'SUM(CASE WHEN type IN (\'stock_out\', \'transfer_out\') THEN quantity ELSE 0 END) as net_change '
        'FROM inventory_transactions '
        'WHERE transaction_date >= ? AND transaction_date <= ? '
        'GROUP BY strftime(\'%Y-%m-%d\', transaction_date, \'unixepoch\') '
        'ORDER BY strftime(\'%Y-%m-%d\', transaction_date, \'unixepoch\')',
        variables: [
          Variable.withDateTime(range.start),
          Variable.withDateTime(range.end),
        ],
      ).get();

      final points = rows.map((r) {
        final dateStr = r.data['date'] as String;
        final netChange = (r.data['net_change'] as num?)?.toDouble() ?? 0.0;
        return InventoryDataPoint(date: DateTime.parse(dateStr), quantity: netChange);
      }).toList();

      if (points.isEmpty) {
        return const Success(<InventoryDataPoint>[]);
      }

      return Success(_fillMissingDatesInventory(points, range));
    } catch (e, stack) {
      AppLogger.e('Failed to load inventory trend', e, stack);
      return Failure(AppException('Failed to load inventory trend', originalError: e, stackTrace: stack));
    }
  }

  Future<int> _countProducts() async {
    final r = await _db.customSelect(
      'SELECT COUNT(*) as cnt FROM products WHERE is_deleted = ?',
      variables: [Variable.withBool(false)],
    ).get();
    return (r.first.data['cnt'] as int?) ?? 0;
  }

  Future<int> _countCategories() async {
    final r = await _db.customSelect(
      'SELECT COUNT(*) as cnt FROM categories WHERE is_deleted = ?',
      variables: [Variable.withBool(false)],
    ).get();
    return (r.first.data['cnt'] as int?) ?? 0;
  }

  Future<int> _countSuppliers() async {
    final r = await _db.customSelect(
      'SELECT COUNT(*) as cnt FROM suppliers WHERE is_deleted = ?',
      variables: [Variable.withBool(false)],
    ).get();
    return (r.first.data['cnt'] as int?) ?? 0;
  }

  Future<int> _countCustomers() async {
    final r = await _db.customSelect(
      'SELECT COUNT(*) as cnt FROM customers WHERE is_deleted = ?',
      variables: [Variable.withBool(false)],
    ).get();
    return (r.first.data['cnt'] as int?) ?? 0;
  }

  Future<_InventoryStats> _computeInventoryStats() async {
    final rows = await _db.customSelect(
      'SELECT p.id, p.cost_price, p.reorder_level, '
      'COALESCE(SUM(it.quantity), 0) as current_stock '
      'FROM products p '
      'LEFT JOIN inventory_transactions it ON it.product_id = p.id '
      'WHERE p.is_deleted = ? '
      'GROUP BY p.id',
      variables: [Variable.withBool(false)],
    ).get();

    double inventoryValue = 0;
    int lowStock = 0;
    int outOfStock = 0;

    for (final r in rows) {
      final costPrice = (r.data['cost_price'] as num?)?.toDouble() ?? 0.0;
      final currentStock = (r.data['current_stock'] as num?)?.toDouble() ?? 0.0;
      final reorderLevel = (r.data['reorder_level'] as num?)?.toDouble() ?? 0.0;

      inventoryValue += costPrice * currentStock;

      if (currentStock <= 0) {
        outOfStock++;
      } else if (reorderLevel > 0 && currentStock <= reorderLevel) {
        lowStock++;
      }
    }

    return _InventoryStats(inventoryValue, lowStock, outOfStock);
  }

  Future<double> _computeTodaySales() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final r = await _db.customSelect(
      'SELECT COALESCE(SUM(total_amount), 0) as total FROM sales '
      'WHERE is_deleted = ? AND sale_date >= ? AND sale_date < ?',
      variables: [
        Variable.withBool(false),
        Variable.withDateTime(start),
        Variable.withDateTime(end),
      ],
    ).get();
    return (r.first.data['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> _computeMonthlySales() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    final r = await _db.customSelect(
      'SELECT COALESCE(SUM(total_amount), 0) as total FROM sales '
      'WHERE is_deleted = ? AND sale_date >= ? AND sale_date < ?',
      variables: [
        Variable.withBool(false),
        Variable.withDateTime(start),
        Variable.withDateTime(end),
      ],
    ).get();
    return (r.first.data['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> _computeTodayPurchases() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final r = await _db.customSelect(
      'SELECT COALESCE(SUM(total_amount), 0) as total FROM purchases '
      'WHERE is_deleted = ? AND order_date >= ? AND order_date < ?',
      variables: [
        Variable.withBool(false),
        Variable.withDateTime(start),
        Variable.withDateTime(end),
      ],
    ).get();
    return (r.first.data['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> _computeMonthlyPurchases() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    final r = await _db.customSelect(
      'SELECT COALESCE(SUM(total_amount), 0) as total FROM purchases '
      'WHERE is_deleted = ? AND order_date >= ? AND order_date < ?',
      variables: [
        Variable.withBool(false),
        Variable.withDateTime(start),
        Variable.withDateTime(end),
      ],
    ).get();
    return (r.first.data['total'] as num?)?.toDouble() ?? 0.0;
  }

  _DateRange _getDateRange(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'weekly':
        return _DateRange(
          start: now.subtract(const Duration(days: 7)),
          end: now.add(const Duration(days: 1)),
        );
      case 'monthly':
        return _DateRange(
          start: now.subtract(const Duration(days: 30)),
          end: now.add(const Duration(days: 1)),
        );
      default:
        return _DateRange(
          start: now.subtract(const Duration(days: 30)),
          end: now.add(const Duration(days: 1)),
        );
    }
  }

  List<SalesDataPoint> _fillMissingDates(List<SalesDataPoint> points, _DateRange range) {
    final map = {for (final p in points) _ymd(p.date): p.amount};
    final result = <SalesDataPoint>[];
    var current = range.start.startOfDay;
    while (!current.isAfter(range.end)) {
      final key = _ymd(current);
      result.add(SalesDataPoint(date: current, amount: map[key] ?? 0.0));
      current = current.add(const Duration(days: 1));
    }
    return result;
  }

  List<PurchaseDataPoint> _fillMissingDatesPurchase(List<PurchaseDataPoint> points, _DateRange range) {
    final map = {for (final p in points) _ymd(p.date): p.amount};
    final result = <PurchaseDataPoint>[];
    var current = range.start.startOfDay;
    while (!current.isAfter(range.end)) {
      final key = _ymd(current);
      result.add(PurchaseDataPoint(date: current, amount: map[key] ?? 0.0));
      current = current.add(const Duration(days: 1));
    }
    return result;
  }

  List<InventoryDataPoint> _fillMissingDatesInventory(List<InventoryDataPoint> points, _DateRange range) {
    final map = {for (final p in points) _ymd(p.date): p.quantity};
    final result = <InventoryDataPoint>[];
    var current = range.start.startOfDay;
    while (!current.isAfter(range.end)) {
      final key = _ymd(current);
      result.add(InventoryDataPoint(date: current, quantity: map[key] ?? 0.0));
      current = current.add(const Duration(days: 1));
    }
    return result;
  }

  String _ymd(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _InventoryStats {
  final double value;
  final int lowStock;
  final int outOfStock;
  const _InventoryStats(this.value, this.lowStock, this.outOfStock);
}

class _DateRange {
  final DateTime start;
  final DateTime end;
  const _DateRange({required this.start, required this.end});
}

extension _DateTimeHelper on DateTime {
  DateTime get startOfDay => DateTime(year, month, day);
}
