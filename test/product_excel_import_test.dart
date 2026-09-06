import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahibz_inventory/database/database.dart';
import 'package:sahibz_inventory/features/audit_logs/repositories/audit_log_repository.dart';
import 'package:sahibz_inventory/features/categories/repositories/category_repository.dart';
import 'package:sahibz_inventory/features/inventory/repositories/inventory_repository.dart';
import 'package:sahibz_inventory/features/products/repositories/product_repository.dart';
import 'package:sahibz_inventory/features/products/services/product_excel_importer.dart';
import 'package:sahibz_inventory/features/suppliers/repositories/supplier_repository.dart';

Uint8List buildSheet(List<List<Object?>> rows) {
  final excel = Excel.createExcel();
  final sheet = excel[excel.getDefaultSheet()!];
  for (final row in rows) {
    sheet.appendRow([
      for (final v in row)
        if (v == null)
          null
        else if (v is int)
          IntCellValue(v)
        else if (v is double)
          DoubleCellValue(v)
        else
          TextCellValue(v.toString()),
    ]);
  }
  return Uint8List.fromList(excel.encode()!);
}

void main() {
  late AppDatabase db;
  late ProductExcelImportService service;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    service = ProductExcelImportService(
      db: db,
      products: ProductRepository(database: db),
      categories: CategoryRepository(database: db),
      suppliers: SupplierRepository(database: db),
      inventory: InventoryRepository(database: db),
      auditLogRepo: AuditLogRepository(database: db),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('imports valid rows, skips duplicates and bad rows', () async {
    final bytes = buildSheet([
      [
        'Name',
        'SKU',
        'Barcode',
        'Description',
        'Category',
        'Supplier',
        'Cost Price',
        'Selling Price',
        'Quantity',
        'Reorder Level',
        'Unit',
        'Status'
      ],
      [
        'Widget A',
        'WGT-001',
        '',
        'First widget',
        'Gadgets',
        'Acme Co',
        100,
        150.5,
        10,
        2,
        'pcs',
        'active'
      ],
      [
        'Widget B',
        'WGT-002',
        '',
        '',
        'Gadgets',
        '',
        50,
        75,
        0,
        5,
        'box',
        'inactive'
      ],
      ['Widget A copy', 'WGT-001', '', '', '', '', 1, 2, 1, 0, '', ''],
      ['No Sku Here', '', '', '', '', '', 1, 2, 1, 0, '', ''],
      [],
    ]);

    final result = await service.importBytes(bytes);

    expect(result.imported, 3);
    expect(result.skipped, 1);
    expect(result.categoriesCreated, 1);
    expect(result.suppliersCreated, 1);
    expect(result.stockEntries, 2);

    final products = await db.select(db.products).get();
    expect(products.length, 3);

    final a = products.firstWhere((p) => p.sku == 'WGT-001');
    expect(a.name, 'Widget A');
    expect(a.costPrice, 100);
    expect(a.sellingPrice, 150.5);
    expect(a.unit, 'pcs');
    expect(a.taxRate, 12.0);

    final auto = products.firstWhere((p) => p.name == 'No Sku Here');
    expect(auto.sku.isNotEmpty, true);

    final txs = await db.select(db.inventoryTransactions).get();
    expect(txs.length, 2);
    expect(txs.first.quantity, 10);
    expect(txs.first.type, 'stock_in');
  });

  test('imports DESCRIPTION/COST/SRP/UNIT sheet without SKU column',
      () async {
    final bytes = buildSheet([
      ['DESCRIPTION', 'COST', 'SRP', 'UNIT'],
      ['ABSOLUTE 1L', 19.44, 27.00, 'PC'],
      ['ABSOLUTE 6L', 63.61, 80.75, 'PC'],
      ['ACETONE', 10.68, 15.00, 'PC'],
    ]);

    final result = await service.importBytes(bytes);

    expect(result.imported, 3);
    expect(result.skipped, 0);

    final products = await db.select(db.products).get();
    expect(products.length, 3);

    final a = products.firstWhere((p) => p.name == 'ABSOLUTE 1L');
    expect(a.costPrice, 19.44);
    expect(a.sellingPrice, 27.0);
    expect(a.unit, 'PC');
    expect(a.sku.startsWith('ABS-'), true);

    final skus = products.map((p) => p.sku).toSet();
    expect(skus.length, 3);
  });

  test('explicit tax column overrides settings VAT', () async {
    final bytes = buildSheet([
      ['Name', 'SKU', 'Tax'],
      ['Taxed Item', 'TAX-001', 5],
      ['Untaxed Item', 'TAX-002', ''],
    ]);

    final result = await service.importBytes(bytes);
    expect(result.imported, 2);

    final products = await db.select(db.products).get();
    expect(
        products.firstWhere((p) => p.sku == 'TAX-001').taxRate, 5.0);
    expect(
        products.firstWhere((p) => p.sku == 'TAX-002').taxRate, 12.0);
  });

  test('reports progress while importing', () async {
    final rows = <List<Object?>>[
      ['Name', 'SKU']
    ];
    for (var i = 0; i < 12; i++) {
      rows.add(['Item $i', 'PRG-$i']);
    }
    final bytes = buildSheet(rows);

    final seen = <List<int>>[];
    final result = await service.importBytes(bytes,
        onProgress: (done, total) => seen.add([done, total]));

    expect(result.imported, 12);
    expect(seen.isNotEmpty, true);
    expect(seen.last, [12, 12]);
    expect(seen.first[1], 12);
  });

  test('finds headers below a title row', () async {
    final bytes = buildSheet([
      ['MEDICINE PRICE LIST', '', '', ''],
      ['DESCRIPTION', 'COST', 'SRP', 'UNIT'],
      ['ABSOLUTE 1L', 19.44, 27.00, 'PC'],
      ['ACETONE', 10.68, 15.00, 'PC'],
    ]);

    final seen = <List<int>>[];
    final result = await service.importBytes(bytes,
        onProgress: (done, total) => seen.add([done, total]));

    expect(result.imported, 2);
    expect(result.skipped, 0);
    expect(seen.isNotEmpty, true);
    expect(seen.first, [0, 2]);

    final products = await db.select(db.products).get();
    expect(products.length, 2);
    expect(
        products.firstWhere((p) => p.name == 'ABSOLUTE 1L').sellingPrice,
        27.0);
  });

  test('replace policy overwrites existing product', () async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    final products = ProductRepository(database: db);
    final created = await products.create(name: 'Old Name', sku: 'REP-001');
    expect(created.isSuccess, true);
    addTearDown(() async => db.close());

    final svc = ProductExcelImportService(
      db: db,
      products: products,
      categories: CategoryRepository(database: db),
      suppliers: SupplierRepository(database: db),
      inventory: InventoryRepository(database: db),
      auditLogRepo: AuditLogRepository(database: db),
    );

    final bytes = buildSheet([
      ['Name', 'SKU', 'Cost Price', 'Selling Price'],
      ['New Name', 'REP-001', 200, 300],
    ]);

    final result = await svc.importBytes(bytes,
        duplicatePolicy: DuplicatePolicy.replace);

    expect(result.imported, 0);
    expect(result.replaced, 1);
    expect(result.skipped, 0);

    final rows = await db.select(db.products).get();
    expect(rows.length, 1);
    expect(rows.first.name, 'New Name');
    expect(rows.first.costPrice, 200);
    expect(rows.first.sellingPrice, 300);
  });

  test('discard policy soft-deletes existing product', () async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    final products = ProductRepository(database: db);
    final created = await products.create(name: 'Gone Soon', sku: 'DEL-001');
    expect(created.isSuccess, true);
    addTearDown(() async => db.close());

    final svc = ProductExcelImportService(
      db: db,
      products: products,
      categories: CategoryRepository(database: db),
      suppliers: SupplierRepository(database: db),
      inventory: InventoryRepository(database: db),
      auditLogRepo: AuditLogRepository(database: db),
    );

    final bytes = buildSheet([
      ['Name', 'SKU'],
      ['Gone Soon', 'DEL-001'],
      ['Fresh Item', 'NEW-001'],
    ]);

    final result = await svc.importBytes(bytes,
        duplicatePolicy: DuplicatePolicy.discard);

    expect(result.discarded, 1);
    expect(result.imported, 1);

    final gone =
        await (db.select(db.products)..where((p) => p.sku.equals('DEL-001')))
            .getSingle();
    expect(gone.isDeleted, true);
    final fresh =
        await (db.select(db.products)..where((p) => p.sku.equals('NEW-001')))
            .getSingle();
    expect(fresh.isDeleted, false);
  });

  test('matches duplicates by name when sheet has no SKU column', () async {
    final bytes = buildSheet([
      ['DESCRIPTION', 'COST', 'SRP', 'UNIT'],
      ['ABSOLUTE 1L', 19.44, 27.00, 'PC'],
      ['ACETONE', 10.68, 15.00, 'PC'],
    ]);

    final first = await service.importBytes(bytes);
    expect(first.imported, 2);

    final again = await service.importBytes(bytes);
    expect(again.imported, 0);
    expect(again.skipped, 2);

    final changed = buildSheet([
      ['DESCRIPTION', 'COST', 'SRP', 'UNIT'],
      ['ABSOLUTE 1L', 25.00, 35.00, 'PC'],
      ['ACETONE', 10.68, 15.00, 'PC'],
    ]);
    final replaced = await service.importBytes(changed,
        duplicatePolicy: DuplicatePolicy.replace);
    expect(replaced.replaced, 2);
    expect(replaced.imported, 0);

    final products = await db.select(db.products).get();
    expect(products.length, 2);
    expect(
        products.firstWhere((p) => p.name == 'ABSOLUTE 1L').costPrice, 25.0);
  });

  test('rejects sheet without Name and SKU columns', () async {
    final bytes = buildSheet([
      ['Foo', 'Bar'],
      ['a', 'b'],
    ]);
    expect(() => service.importBytes(bytes), throwsA(isA<Exception>()));
  });
}
