import 'dart:async';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:excel/excel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sahibz_inventory/core/exceptions.dart';
import 'package:sahibz_inventory/core/logger.dart';
import 'package:sahibz_inventory/database/database.dart';
import 'package:sahibz_inventory/features/audit_logs/repositories/audit_log_repository.dart';
import 'package:sahibz_inventory/features/categories/repositories/category_repository.dart';
import 'package:sahibz_inventory/features/inventory/repositories/inventory_repository.dart';
import 'package:sahibz_inventory/features/products/repositories/product_repository.dart';
import 'package:sahibz_inventory/features/suppliers/repositories/supplier_repository.dart';

enum DuplicatePolicy { skip, replace, discard }

class ProductImportResult {
  final int imported;
  final int skipped;
  final int replaced;
  final int discarded;
  final int categoriesCreated;
  final int suppliersCreated;
  final int stockEntries;
  final List<String> errors;

  const ProductImportResult({
    this.imported = 0,
    this.skipped = 0,
    this.replaced = 0,
    this.discarded = 0,
    this.categoriesCreated = 0,
    this.suppliersCreated = 0,
    this.stockEntries = 0,
    this.errors = const [],
  });

  String get summary {
    final parts = <String>[
      '$imported product${imported == 1 ? '' : 's'} imported',
    ];
    if (replaced > 0) {
      parts.add('$replaced replaced');
    }
    if (discarded > 0) {
      parts.add('$discarded deleted');
    }
    parts.add('$skipped skipped');
    if (categoriesCreated > 0) {
      parts.add(
          '$categoriesCreated categor${categoriesCreated == 1 ? 'y' : 'ies'} created');
    }
    if (suppliersCreated > 0) {
      parts.add(
          '$suppliersCreated supplier${suppliersCreated == 1 ? '' : 's'} created');
    }
    if (stockEntries > 0) {
      parts.add('$stockEntries opening stock entr${stockEntries == 1 ? 'y' : 'ies'}');
    }
    return parts.join(' • ');
  }
}

final productExcelImportServiceProvider =
    Provider<ProductExcelImportService>((ref) {
  return ProductExcelImportService(
    db: ref.watch(databaseProvider),
    products: ref.watch(productRepositoryProvider),
    categories: ref.watch(categoryRepositoryProvider),
    suppliers: ref.watch(supplierRepositoryProvider),
    inventory: ref.watch(inventoryRepositoryProvider),
    auditLogRepo: ref.watch(auditLogRepositoryProvider),
  );
});

class ProductExcelImportService {
  final AppDatabase _db;
  final ProductRepository _products;
  final CategoryRepository _categories;
  final SupplierRepository _suppliers;
  final InventoryRepository _inventory;
  final AuditLogRepository _auditLogRepo;

  ProductExcelImportService({
    required AppDatabase db,
    required ProductRepository products,
    required CategoryRepository categories,
    required SupplierRepository suppliers,
    required InventoryRepository inventory,
    required AuditLogRepository auditLogRepo,
  })  : _db = db,
        _products = products,
        _categories = categories,
        _suppliers = suppliers,
        _inventory = inventory,
        _auditLogRepo = auditLogRepo;

  static const _aliases = <String, Set<String>>{
    'name': {
      'name',
      'product',
      'productname',
      'item',
      'itemname',
      'title',
      'producttitle',
      'description',
      'productdescription'
    },
    'sku': {'sku', 'code', 'productcode', 'itemcode', 'productsku'},
    'barcode': {'barcode', 'ean', 'upc', 'barcodes'},
    'description': {
      'description',
      'desc',
      'details',
      'notes',
      'remark',
      'remarks'
    },
    'category': {'category', 'categoryname', 'cat', 'group', 'department'},
    'supplier': {'supplier', 'suppliername', 'vendor', 'vendorname'},
    'costPrice': {
      'costprice',
      'cost',
      'purchaseprice',
      'buyprice',
      'rate',
      'purchasecost',
      'unitcost'
    },
    'sellingPrice': {
      'sellingprice',
      'sellprice',
      'price',
      'saleprice',
      'mrp',
      'retail',
      'retailprice',
      'sellingrate',
      'srp',
      'suggestedretailprice',
      'suggestedprice'
    },
    'quantity': {
      'quantity',
      'qty',
      'stock',
      'openingstock',
      'openingqty',
      'onhand'
    },
    'reorderLevel': {
      'reorderlevel',
      'reorder',
      'reorderpoint',
      'minstock',
      'minimumstock',
      'minimum',
      'minqty'
    },
    'unit': {'unit', 'uom', 'units'},
    'status': {'status', 'state'},
    'taxRate': {'taxrate', 'tax', 'vat', 'gst', 'taxpercent'},
  };

  static String _normalizeHeader(Object? value) {
    return _cellString(value).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static Object? _unwrapCell(Object? value) {
    if (value == null ||
        value is String ||
        value is num ||
        value is bool ||
        value is DateTime) {
      return value;
    }
    if (value is TextCellValue) return value.value.text ?? '';
    if (value is IntCellValue) return value.value;
    if (value is DoubleCellValue) return value.value;
    if (value is BoolCellValue) return value.value;
    if (value is DateCellValue) return value.asDateTimeLocal();
    if (value is DateTimeCellValue) return value.asDateTimeLocal();
    if (value is FormulaCellValue) return value.formula;
    try {
      return (value as dynamic).value;
    } catch (_) {
      return value.toString();
    }
  }

  static String _cellString(Object? value) {
    final v = _unwrapCell(value);
    if (v == null) return '';
    if (v is DateTime) return v.toIso8601String().split('T').first;
    if (v is double) {
      return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
    }
    return v.toString().trim();
  }

  static double _cellNumber(Object? value) {
    final v = _unwrapCell(value);
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    final cleaned =
        v.toString().replaceAll(',', '').replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  Future<ProductImportResult> importBytes(
    Uint8List bytes, {
    void Function(int done, int total)? onProgress,
    DuplicatePolicy duplicatePolicy = DuplicatePolicy.skip,
  }) async {
    final excel = Excel.decodeBytes(bytes);

    Sheet? sheet;
    for (final entry in excel.tables.entries) {
      if (entry.value.rows.isNotEmpty) {
        sheet = entry.value;
        break;
      }
    }
    if (sheet == null || sheet.rows.isEmpty) {
      throw const AppException('Excel file is empty');
    }

    // Auto-detect the header row: scan the first few rows so title rows,
    // blank rows, or notes above the real headers don't break the import.
    Map<String, int> colIndex = {};
    var headerIdx = -1;
    final scanLimit =
        sheet.rows.length < 5 ? sheet.rows.length : 5;
    for (var h = 0; h < scanLimit; h++) {
      final candidate = <String, int>{};
      for (var c = 0; c < sheet.rows[h].length; c++) {
        final normalized = _normalizeHeader(sheet.rows[h][c]?.value);
        if (normalized.isEmpty) continue;
        for (final field in _aliases.keys) {
          if (_aliases[field]!.contains(normalized) &&
              !candidate.containsKey(field)) {
            candidate[field] = c;
            break;
          }
        }
      }
      if (candidate.containsKey('name')) {
        headerIdx = h;
        colIndex = candidate;
        break;
      }
    }

    if (headerIdx < 0) {
      throw const AppException(
          'Excel must contain a Name (or Description) column');
    }
    final hasSkuColumn = colIndex.containsKey('sku');
    final dataStart = headerIdx + 1;
    final total = sheet.rows.length - dataStart;
    onProgress?.call(0, total);

    double settingsVat = 0.0;
    try {
      final vatRow = await (_db.select(_db.settings)
            ..where((s) => s.key.equals('tax_rate')))
          .getSingleOrNull();
      settingsVat = double.tryParse(vatRow?.value.trim() ?? '') ?? 0.0;
    } catch (_) {}

    final existingProducts = await (_db.select(_db.products)
          ..where((p) => p.isDeleted.equals(false)))
        .get();
    final existingSkuIds = {
      for (final p in existingProducts) p.sku.trim().toLowerCase(): p.id
    };
    final existingNameIds = {
      for (final p in existingProducts) p.name.trim().toLowerCase(): p.id
    };

    final catRows = await (_db.select(_db.categories)
          ..where((c) => c.isDeleted.equals(false)))
        .get();
    final categoryIds = {
      for (final c in catRows) c.name.trim().toLowerCase(): c.id
    };

    final supRows = await (_db.select(_db.suppliers)
          ..where((s) => s.isDeleted.equals(false)))
        .get();
    final supplierIds = {
      for (final s in supRows) s.companyName.trim().toLowerCase(): s.id
    };

    var imported = 0;
    var skipped = 0;
    var replaced = 0;
    var discarded = 0;
    var categoriesCreated = 0;
    var suppliersCreated = 0;
    var stockEntries = 0;
    var autoSkuSeq = 1;
    final errors = <String>[];

    void recordSkipped(int rowNum, String reason) {
      skipped++;
      if (errors.length < 20) {
        errors.add('Row $rowNum: skipped ($reason)');
      }
    }

    String generateSku(String productName) {
      final base = productName
          .toUpperCase()
          .replaceAll(RegExp(r'[^A-Z0-9]'), '')
          .padRight(3, 'X')
          .substring(0, 3);
      String candidate;
      do {
        candidate = '$base-${(autoSkuSeq++).toString().padLeft(4, '0')}';
      } while (existingSkuIds.containsKey(candidate.toLowerCase()));
      return candidate;
    }

    Object? cellAt(List<Data?> row, String field) {
      final idx = colIndex[field];
      if (idx == null || idx >= row.length) return null;
      return row[idx]?.value;
    }

    for (var r = dataStart; r < sheet.rows.length; r++) {
      final done = r - dataStart + 1;
      if (onProgress != null &&
          (done <= 2 || done % 5 == 0 || r == sheet.rows.length - 1)) {
        onProgress(done, total);
      }
      final row = sheet.rows[r];
      final rowNum = r + 1;
      if (row.every((c) => _cellString(c?.value).isEmpty)) continue;

      final name = _cellString(cellAt(row, 'name'));
      if (name.isEmpty) {
        recordSkipped(rowNum, 'missing Name/Description');
        continue;
      }
      var sku = hasSkuColumn ? _cellString(cellAt(row, 'sku')) : '';
      final nameKey = name.trim().toLowerCase();
      final String? existingId;
      final String matchDesc;
      if (sku.isNotEmpty) {
        existingId = existingSkuIds[sku.toLowerCase()];
        matchDesc = 'duplicate SKU "$sku"';
      } else {
        existingId = existingNameIds[nameKey];
        matchDesc = 'duplicate product "$name"';
        if (existingId == null) {
          sku = generateSku(name);
        }
      }
      final skuKey = sku.toLowerCase();

      final statusRaw = _cellString(cellAt(row, 'status')).toLowerCase();
      final status =
          (statusRaw == 'active' || statusRaw == 'inactive') ? statusRaw : 'active';
      final unitRaw = _cellString(cellAt(row, 'unit'));
      final costPrice = _cellNumber(cellAt(row, 'costPrice'));
      final sellingPrice = _cellNumber(cellAt(row, 'sellingPrice'));
      final quantity = _cellNumber(cellAt(row, 'quantity'));
      final reorderLevel = _cellNumber(cellAt(row, 'reorderLevel'));
      final double taxRate;
      if (colIndex.containsKey('taxRate') &&
          _cellString(cellAt(row, 'taxRate')).isNotEmpty) {
        taxRate = _cellNumber(cellAt(row, 'taxRate'));
      } else {
        taxRate = settingsVat;
      }
      final categoryRaw = _cellString(cellAt(row, 'category'));
      final supplierRaw = _cellString(cellAt(row, 'supplier'));
      final barcodeRaw = _cellString(cellAt(row, 'barcode'));
      final descRaw = _cellString(cellAt(row, 'description'));

      if (existingId != null && duplicatePolicy == DuplicatePolicy.skip) {
        recordSkipped(rowNum, matchDesc);
        continue;
      }
      if (existingId != null && duplicatePolicy == DuplicatePolicy.discard) {
        final del = await _products.delete(existingId);
        if (del.isSuccess) {
          discarded++;
          if (skuKey.isNotEmpty) existingSkuIds.remove(skuKey);
          existingNameIds.removeWhere((k, v) => v == existingId);
          unawaited(_auditLogRepo.logAction(
            userId: 'admin',
            action: 'delete',
            entityType: 'product',
            details: 'Duplicate discarded on Excel import ($matchDesc)',
          ));
        } else {
          recordSkipped(rowNum, del.error.message);
        }
        continue;
      }
      final replaceId = (existingId != null &&
              duplicatePolicy == DuplicatePolicy.replace)
          ? existingId
          : null;

      String? categoryId;
      if (categoryRaw.isNotEmpty) {
        final key = categoryRaw.toLowerCase();
        categoryId = categoryIds[key];
        if (categoryId == null) {
          final resolved = await _categories.create(name: categoryRaw);
          if (resolved.isSuccess) {
            categoryId = resolved.value.id;
            categoryIds[key] = categoryId;
            categoriesCreated++;
          } else {
            recordSkipped(rowNum, resolved.error.message);
            continue;
          }
        }
      }

      String? supplierId;
      if (supplierRaw.isNotEmpty) {
        final key = supplierRaw.toLowerCase();
        supplierId = supplierIds[key];
        if (supplierId == null) {
          final resolved =
              await _suppliers.create(companyName: supplierRaw);
          if (resolved.isSuccess) {
            supplierId = resolved.value.id;
            supplierIds[key] = supplierId;
            suppliersCreated++;
          } else {
            recordSkipped(rowNum, resolved.error.message);
            continue;
          }
        }
      }

      if (replaceId != null) {
        final updated = await _products.update(
          id: replaceId,
          name: name,
          barcode: barcodeRaw.isEmpty ? null : barcodeRaw,
          description: descRaw.isEmpty ? null : descRaw,
          categoryId: categoryId,
          supplierId: supplierId,
          costPrice: costPrice,
          sellingPrice: sellingPrice,
          taxRate: taxRate,
          unit: unitRaw.isEmpty ? 'pcs' : unitRaw,
          reorderLevel: reorderLevel < 0 ? 0.0 : reorderLevel,
          status: status,
        );
        if (updated.isSuccess) {
          replaced++;
          existingNameIds.removeWhere((k, v) => v == replaceId);
          existingNameIds[name.trim().toLowerCase()] = replaceId;
          unawaited(_auditLogRepo.logAction(
            userId: 'admin',
            action: 'update',
            entityType: 'product',
            entityId: replaceId,
            newValues: updated.value.toJson(),
            details: 'Replaced on Excel import',
          ));
        } else {
          recordSkipped(rowNum, updated.error.message);
        }
        continue;
      }

      final created = await _products.create(
        name: name,
        sku: sku,
        barcode: barcodeRaw.isEmpty ? null : barcodeRaw,
        description: descRaw.isEmpty ? null : descRaw,
        categoryId: categoryId,
        supplierId: supplierId,
        costPrice: costPrice,
        sellingPrice: sellingPrice,
        taxRate: taxRate,
        unit: unitRaw.isEmpty ? 'pcs' : unitRaw,
        reorderLevel: reorderLevel < 0 ? 0.0 : reorderLevel,
        status: status,
      );

      if (!created.isSuccess) {
        recordSkipped(rowNum, created.error.message);
        continue;
      }

      existingSkuIds[skuKey] = created.value.id;
      existingNameIds[name.trim().toLowerCase()] = created.value.id;
      imported++;
      unawaited(_auditLogRepo.logAction(
        userId: 'admin',
        action: 'create',
        entityType: 'product',
        entityId: created.value.id,
        newValues: created.value.toJson(),
        details: 'Imported from Excel',
      ));

      if (quantity > 0) {
        final stock = await _inventory.stockIn(
          productId: created.value.id,
          quantity: quantity,
          unitPrice: costPrice,
          notes: 'Opening stock (Excel import)',
          referenceType: 'import',
        );
        if (stock.isSuccess) {
          stockEntries++;
        } else if (errors.length < 20) {
          errors.add('Row $rowNum: product added but stock failed');
        }
      }
    }

    onProgress?.call(total, total);
    AppLogger.i(
        'Product Excel import: $imported imported, $replaced replaced, $discarded discarded, $skipped skipped');
    return ProductImportResult(
      imported: imported,
      skipped: skipped,
      replaced: replaced,
      discarded: discarded,
      categoriesCreated: categoriesCreated,
      suppliersCreated: suppliersCreated,
      stockEntries: stockEntries,
      errors: errors,
    );
  }

}
