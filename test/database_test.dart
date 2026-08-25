import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart' show NativeDatabase;
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';
import 'package:sahibz_inventory/database/database.dart';

void main() {
  late AppDatabase database;
  const uuid = Uuid();

  setUp(() {
    database = AppDatabase(executor: NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('Seed Data', () {
    test('settings have all required keys', () async {
      final settings = await database.select(database.settings).get();
      expect(settings.length, greaterThanOrEqualTo(10));
      final keys = settings.map((s) => s.key).toList();
      expect(keys, containsAll(['company_name', 'currency', 'tax_rate', 'language', 'theme']));
      final companyName = settings.firstWhere((s) => s.key == 'company_name');
      expect(companyName.value, 'SahibZ Enterprise');
    });
  });

  String _id() => uuid.v4();

  group('CRUD - Products', () {
    test('create product with required fields', () async {
      final id = _id();
      await database.into(database.products).insert(ProductsCompanion.insert(
        id: id, name: 'Widget A', sku: 'WIDGET-A-001',
      ));
      final product = await (database.select(database.products)
        ..where((t) => t.id.equals(id))).getSingle();
      expect(product.name, 'Widget A');
      expect(product.sku, 'WIDGET-A-001');
      expect(product.status, 'active');
      expect(product.isDeleted, isFalse);
    });

    test('create product with all fields', () async {
      final id = _id();
      await database.into(database.products).insert(ProductsCompanion.insert(
        id: id, name: 'Widget B', sku: 'WIDGET-B-001',
        costPrice: const Value(50.0), sellingPrice: const Value(75.0),
        unit: const Value('pcs'), reorderLevel: const Value(10.0),
      ));
      final p = await (database.select(database.products)
        ..where((t) => t.id.equals(id))).getSingle();
      expect(p.costPrice, 50.0);
      expect(p.sellingPrice, 75.0);
      expect(p.unit, 'pcs');
    });

    test('read all products', () async {
      await database.into(database.products).insert(ProductsCompanion.insert(
        id: _id(), name: 'P1', sku: 'READ-TEST-1',
      ));
      await database.into(database.products).insert(ProductsCompanion.insert(
        id: _id(), name: 'P2', sku: 'READ-TEST-2',
      ));
      final all = await database.select(database.products).get();
      expect(all.length, greaterThanOrEqualTo(2));
    });

    test('update product name and price', () async {
      final id = _id();
      await database.into(database.products).insert(ProductsCompanion.insert(
        id: id, name: 'Old Name', sku: 'UPDATE-TEST',
      ));
      await (database.update(database.products)
        ..where((t) => t.id.equals(id)))
        .write(ProductsCompanion(name: Value('New Name'), sellingPrice: Value(99.99)));
      final updated = await (database.select(database.products)
        ..where((t) => t.id.equals(id))).getSingle();
      expect(updated.name, 'New Name');
      expect(updated.sellingPrice, 99.99);
    });

    test('soft delete product', () async {
      final id = _id();
      await database.into(database.products).insert(ProductsCompanion.insert(
        id: id, name: 'Delete Me', sku: 'SOFT-DEL',
      ));
      await (database.update(database.products)
        ..where((t) => t.id.equals(id)))
        .write(ProductsCompanion(isDeleted: const Value(true)));
      final deleted = await (database.select(database.products)
        ..where((t) => t.id.equals(id))).getSingle();
      expect(deleted.isDeleted, isTrue);
    });

    test('sku must be unique', () async {
      await database.into(database.products).insert(ProductsCompanion.insert(
        id: _id(), name: 'First', sku: 'DUPE-SKU',
      ));
      expect(
        () async => await database.into(database.products).insert(
          ProductsCompanion.insert(id: _id(), name: 'Second', sku: 'DUPE-SKU'),
        ),
        throwsA(anything),
      );
    });
  });

  group('CRUD - Categories', () {
    test('create parent and child category', () async {
      final parentId = _id();
      final childId = _id();
      await database.into(database.categories).insert(CategoriesCompanion.insert(
        id: parentId, name: 'Electronics',
      ));
      await database.into(database.categories).insert(CategoriesCompanion.insert(
        id: childId, name: 'Smartphones', parentId: Value(parentId),
      ));
      final child = await (database.select(database.categories)
        ..where((t) => t.id.equals(childId))).getSingle();
      expect(child.parentId, parentId);
      expect(child.name, 'Smartphones');
    });

    test('update category status', () async {
      final id = _id();
      await database.into(database.categories).insert(CategoriesCompanion.insert(
        id: id, name: 'Temp',
      ));
      await (database.update(database.categories)
        ..where((t) => t.id.equals(id)))
        .write(CategoriesCompanion(status: Value('inactive')));
      final updated = await (database.select(database.categories)
        ..where((t) => t.id.equals(id))).getSingle();
      expect(updated.status, 'inactive');
    });
  });

  group('CRUD - Suppliers', () {
    test('create supplier with required fields', () async {
      final id = _id();
      await database.into(database.suppliers).insert(SuppliersCompanion.insert(
        id: id, companyName: 'Acme Corp',
      ));
      final s = await (database.select(database.suppliers)
        ..where((t) => t.id.equals(id))).getSingle();
      expect(s.companyName, 'Acme Corp');
      expect(s.status, 'active');
    });

    test('create supplier with all optional fields', () async {
      final id = _id();
      await database.into(database.suppliers).insert(SuppliersCompanion.insert(
        id: id, companyName: 'Beta Inc', contactPerson: Value('John'),
        phone: Value('+1-555-0100'), email: Value('j@beta.com'),
        city: Value('NYC'), gstNumber: Value('GST123'),
      ));
      final s = await (database.select(database.suppliers)
        ..where((t) => t.id.equals(id))).getSingle();
      expect(s.contactPerson, 'John');
      expect(s.phone, '+1-555-0100');
    });

    test('soft delete supplier', () async {
      final id = _id();
      await database.into(database.suppliers).insert(SuppliersCompanion.insert(
        id: id, companyName: 'Delete Co',
      ));
      await (database.update(database.suppliers)
        ..where((t) => t.id.equals(id)))
        .write(SuppliersCompanion(isDeleted: Value(true)));
      final deleted = await (database.select(database.suppliers)
        ..where((t) => t.id.equals(id))).getSingle();
      expect(deleted.isDeleted, isTrue);
    });
  });

  group('CRUD - Customers', () {
    test('create customer with required fields', () async {
      final id = _id();
      await database.into(database.customers).insert(CustomersCompanion.insert(
        id: id, name: 'Jane Smith',
      ));
      final c = await (database.select(database.customers)
        ..where((t) => t.id.equals(id))).getSingle();
      expect(c.name, 'Jane Smith');
      expect(c.status, 'active');
    });

    test('create customer with optional fields', () async {
      final id = _id();
      await database.into(database.customers).insert(CustomersCompanion.insert(
        id: id, name: 'John Doe', phone: Value('+1-555-0200'),
        email: Value('john@doe.com'),
      ));
      final c = await (database.select(database.customers)
        ..where((t) => t.id.equals(id))).getSingle();
      expect(c.phone, '+1-555-0200');
      expect(c.email, 'john@doe.com');
    });
  });

  group('CRUD - Inventory Transactions', () {
    test('create stock_in transaction', () async {
      final productId = _id();
      final txId = _id();
      await database.into(database.products).insert(ProductsCompanion.insert(
        id: productId, name: 'Inv Product', sku: 'INV-TEST-001',
      ));
      await database.into(database.inventoryTransactions).insert(
        InventoryTransactionsCompanion.insert(
          id: txId, productId: productId,
          type: 'stock_in', quantity: 200.0,
          unitPrice: const Value(25.0), totalPrice: const Value(5000.0),
          balanceBefore: const Value(0.0), balanceAfter: const Value(200.0),
        ),
      );
      final tx = await (database.select(database.inventoryTransactions)
        ..where((t) => t.id.equals(txId))).getSingle();
      expect(tx.type, 'stock_in');
      expect(tx.quantity, 200.0);
      expect(tx.balanceAfter, 200.0);
    });

    test('stock_out reduces balance', () async {
      final productId = _id();
      final txIn = _id();
      final txOut = _id();
      await database.into(database.products).insert(ProductsCompanion.insert(
        id: productId, name: 'Inv Product 2', sku: 'INV-TEST-002',
      ));
      await database.into(database.inventoryTransactions).insert(
        InventoryTransactionsCompanion.insert(
          id: txIn, productId: productId,
          type: 'stock_in', quantity: 100.0,
          unitPrice: const Value(10.0), totalPrice: const Value(1000.0),
          balanceBefore: const Value(0.0), balanceAfter: const Value(100.0),
        ),
      );
      await database.into(database.inventoryTransactions).insert(
        InventoryTransactionsCompanion.insert(
          id: txOut, productId: productId,
          type: 'stock_out', quantity: 30.0,
          unitPrice: const Value(10.0), totalPrice: const Value(300.0),
          balanceBefore: const Value(100.0), balanceAfter: const Value(70.0),
        ),
      );
      final tx = await (database.select(database.inventoryTransactions)
        ..where((t) => t.id.equals(txOut))).getSingle();
      expect(tx.balanceBefore, 100.0);
      expect(tx.balanceAfter, 70.0);
    });
  });

  group('CRUD - Purchases with Items', () {
    test('create purchase with line items', () async {
      final supplierId = _id();
      final productId = _id();
      final purchaseId = _id();
      final itemId = _id();
      await database.into(database.suppliers).insert(SuppliersCompanion.insert(
        id: supplierId, companyName: 'Supplier Co',
      ));
      await database.into(database.products).insert(ProductsCompanion.insert(
        id: productId, name: 'Purchase Product', sku: 'PUR-TEST',
      ));
      await database.into(database.purchases).insert(PurchasesCompanion.insert(
        id: purchaseId, orderNumber: 'PO-2024-001',
        supplierId: supplierId,
        createdBy: Value(_id()),
        subtotal: const Value(500.0), totalAmount: const Value(590.0),
        taxAmount: const Value(90.0),
      ));
      await database.into(database.purchaseItems).insert(PurchaseItemsCompanion.insert(
        id: itemId, purchaseId: purchaseId, productId: productId,
        quantity: 10.0, unitPrice: 50.0, totalPrice: 500.0,
      ));
      final purchase = await (database.select(database.purchases)
        ..where((t) => t.id.equals(purchaseId))).getSingle();
      expect(purchase.orderNumber, 'PO-2024-001');
      expect(purchase.status, 'pending');
      final items = await (database.select(database.purchaseItems)
        ..where((t) => t.purchaseId.equals(purchaseId))).get();
      expect(items.length, 1);
      expect(items.first.quantity, 10.0);
    });
  });

  group('CRUD - Sales with Items', () {
    test('create completed sale', () async {
      final customerId = _id();
      final productId = _id();
      final saleId = _id();
      final itemId = _id();
      await database.into(database.customers).insert(CustomersCompanion.insert(
        id: customerId, name: 'Test Customer',
      ));
      await database.into(database.products).insert(ProductsCompanion.insert(
        id: productId, name: 'Sale Product', sku: 'SALE-TEST',
      ));
      await database.into(database.sales).insert(SalesCompanion.insert(
        id: saleId, invoiceNumber: 'INV-2024-001',
        customerId: Value(customerId),
        createdBy: Value(_id()),
        subtotal: const Value(300.0), totalAmount: const Value(354.0),
        taxAmount: const Value(54.0), paidAmount: const Value(354.0),
        dueAmount: const Value(0.0), paymentStatus: const Value('paid'),
      ));
      await database.into(database.salesItems).insert(SalesItemsCompanion.insert(
        id: itemId, saleId: saleId, productId: productId,
        quantity: 5.0, unitPrice: 60.0, totalPrice: 300.0,
      ));
      final sale = await (database.select(database.sales)
        ..where((t) => t.id.equals(saleId))).getSingle();
      expect(sale.invoiceNumber, 'INV-2024-001');
      expect(sale.paymentStatus, 'paid');
      final items = await (database.select(database.salesItems)
        ..where((t) => t.saleId.equals(saleId))).get();
      expect(items.length, 1);
      expect(items.first.quantity, 5.0);
    });
  });

  group('CRUD - Settings', () {
    test('create and update setting', () async {
      await database.into(database.settings).insert(SettingsCompanion.insert(
        key: 'test_key', value: 'test_value',
      ));
      final setting = await (database.select(database.settings)
        ..where((t) => t.key.equals('test_key'))).getSingle();
      expect(setting.value, 'test_value');
      await (database.update(database.settings)
        ..where((t) => t.key.equals('test_key')))
        .write(SettingsCompanion(value: Value('updated_value')));
      final updated = await (database.select(database.settings)
        ..where((t) => t.key.equals('test_key'))).getSingle();
      expect(updated.value, 'updated_value');
    });
  });
  group('CRUD - Audit Logs', () {
    test('create audit log entry', () async {
      final id = _id();
      await database.into(database.auditLogs).insert(AuditLogsCompanion.insert(
        id: id, action: 'create', entityType: 'product',
        entityId: Value(_id()),
      ));
      final log = await (database.select(database.auditLogs)
        ..where((t) => t.id.equals(id))).getSingle();
      expect(log.action, 'create');
      expect(log.entityType, 'product');
    });
  });


}
