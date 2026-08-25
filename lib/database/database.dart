import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tables.dart';
import 'package:sahibz_inventory/core/paths.dart';
part 'database.g.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('Must be overridden in ProviderScope');
});

@DriftDatabase(tables: [
  Categories,
  Suppliers,
  Customers,
  Products,
  InventoryTransactions,
  Purchases,
  PurchaseItems,
  Sales,
  SalesItems,
  Settings,
  AuditLogs,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase({QueryExecutor? executor})
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _seedInitialData();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(purchaseItems, purchaseItems.notes);
        }
      },
    );
  }

  Future<void> _seedInitialData() async {
    final settings = {
      'company_name': 'SahibZ Enterprise',
      'company_phone': '+91-9876543210',
      'company_email': 'info@sahibz.com',
      'company_address': '123 Business Park, Mumbai, Maharashtra',
      'company_tin': '123-456-789-000',
      'currency': 'PHP',
      'currency_symbol': '\u20B1',
      'tax_rate': '12.0',
      'date_format': 'dd/MM/yyyy',
      'time_format': 'HH:mm',
      'language': 'en',
      'theme': 'light',
      'low_stock_threshold': '10',
      'auto_backup': 'false',
      'backup_frequency': 'daily',
      'username': 'admin',
      'password': 'admin',
    };
    for (final entry in settings.entries) {
      await into(this.settings).insert(
        SettingsCompanion.insert(key: entry.key, value: entry.value),
      );
    }
  }

  Future<void> resetDatabase() async {
    await (update(categories)..write(CategoriesCompanion(parentId: Value(null))));
    await delete(auditLogs).go();
    await delete(salesItems).go();
    await delete(sales).go();
    await delete(purchaseItems).go();
    await delete(purchases).go();
    await delete(inventoryTransactions).go();
    await delete(products).go();
    await delete(customers).go();
    await delete(suppliers).go();
    await delete(categories).go();
    await delete(settings).go();
    await _seedInitialData();
  }

  @override
  Future<void> close() async {
    await super.close();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final file = File(await AppPaths.databasePath);
    return NativeDatabase(file);
  });
}
