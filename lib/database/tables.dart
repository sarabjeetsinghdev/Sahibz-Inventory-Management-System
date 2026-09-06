import 'package:drift/drift.dart';

// Categories Table
class Categories extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get image => text().nullable()();
  TextColumn get parentId => text().references(Categories, #id).nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Suppliers Table
class Suppliers extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get companyName => text()();
  TextColumn get contactPerson => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get state => text().nullable()();
  TextColumn get pincode => text().nullable()();
  TextColumn get gstNumber => text().nullable()();
  TextColumn get panNumber => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Customers Table
class Customers extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get state => text().nullable()();
  TextColumn get pincode => text().nullable()();
  TextColumn get gstNumber => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
// Products Table
class Products extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get name => text()();
  TextColumn get sku => text().unique()();
  TextColumn get barcode => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get categoryId => text().references(Categories, #id).nullable()();
  TextColumn get supplierId => text().references(Suppliers, #id).nullable()();
  RealColumn get costPrice => real().withDefault(const Constant(0.0))();
  RealColumn get sellingPrice => real().withDefault(const Constant(0.0))();
  RealColumn get taxRate => real().withDefault(const Constant(0.0))();
  TextColumn get taxType => text().withDefault(const Constant('percentage'))(); // percentage, fixed
  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  RealColumn get reorderLevel => real().withDefault(const Constant(0.0))();
  TextColumn get image => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Inventory Transactions Table
class InventoryTransactions extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get type => text()(); // stock_in, stock_out, adjustment, transfer_in, transfer_out
  RealColumn get quantity => real()();
  RealColumn get unitPrice => real().withDefault(const Constant(0.0))();
  RealColumn get totalPrice => real().withDefault(const Constant(0.0))();
  RealColumn get balanceBefore => real().withDefault(const Constant(0.0))();
  RealColumn get balanceAfter => real().withDefault(const Constant(0.0))();
  TextColumn get reference => text().nullable()(); // Purchase/Sale Order ID
  TextColumn get referenceType => text().nullable()(); // purchase, sale, adjustment, transfer
  TextColumn get notes => text().nullable()();
  TextColumn get batchNumber => text().nullable()();
  TextColumn get serialNumber => text().nullable()();
  TextColumn get performedBy => text().nullable()();
  DateTimeColumn get transactionDate => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// Purchases Table
class Purchases extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get orderNumber => text().unique()();
  TextColumn get supplierId => text().references(Suppliers, #id)();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending, approved, received, cancelled
  RealColumn get subtotal => real().withDefault(const Constant(0.0))();
  RealColumn get taxAmount => real().withDefault(const Constant(0.0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0.0))();
  RealColumn get shippingAmount => real().withDefault(const Constant(0.0))();
  RealColumn get totalAmount => real().withDefault(const Constant(0.0))();
  TextColumn get notes => text().nullable()();
  TextColumn get billingAddress => text().nullable()();
  TextColumn get shippingAddress => text().nullable()();
  TextColumn get paymentMethod => text().nullable()();
  TextColumn get paymentStatus => text().withDefault(const Constant('unpaid'))();
  TextColumn get createdBy => text().nullable()();
  TextColumn get approvedBy => text().nullable()();
  DateTimeColumn get orderDate => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get expectedDelivery => dateTime().nullable()();
  DateTimeColumn get receivedDate => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Purchase Items Table
class PurchaseItems extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get purchaseId => text().references(Purchases, #id)();
  TextColumn get productId => text().references(Products, #id)();
  RealColumn get quantity => real()();
  RealColumn get unitPrice => real()();
  RealColumn get taxRate => real().withDefault(const Constant(0.0))();
  RealColumn get taxAmount => real().withDefault(const Constant(0.0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0.0))();
  RealColumn get totalPrice => real()();
  RealColumn get receivedQuantity => real().withDefault(const Constant(0.0))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// Sales Table
class Sales extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get invoiceNumber => text().unique()();
  TextColumn get customerId => text().references(Customers, #id).nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending, completed, cancelled
  RealColumn get subtotal => real().withDefault(const Constant(0.0))();
  RealColumn get taxAmount => real().withDefault(const Constant(0.0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0.0))();
  RealColumn get totalAmount => real().withDefault(const Constant(0.0))();
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))();
  RealColumn get dueAmount => real().withDefault(const Constant(0.0))();
  TextColumn get paymentMethod => text().nullable()();
  TextColumn get paymentStatus => text().withDefault(const Constant('unpaid'))(); // unpaid, partial, paid
  TextColumn get notes => text().nullable()();
  TextColumn get billingAddress => text().nullable()();
  TextColumn get shippingAddress => text().nullable()();
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get saleDate => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Sales Items Table
class SalesItems extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get saleId => text().references(Sales, #id)();
  TextColumn get productId => text().references(Products, #id)();
  RealColumn get quantity => real()();
  RealColumn get unitPrice => real()();
  RealColumn get taxRate => real().withDefault(const Constant(0.0))();
  RealColumn get taxAmount => real().withDefault(const Constant(0.0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0.0))();
  RealColumn get totalPrice => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// Settings Table
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  TextColumn get group => text().nullable()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}

// Audit Logs Table
class AuditLogs extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get userId => text().nullable()();
  TextColumn get action => text()(); // create, update, delete, login, logout, export
  TextColumn get entityType => text()(); // product, category, supplier, etc.
  TextColumn get entityId => text().nullable()();
  TextColumn get oldValues => text().nullable()(); // JSON
  TextColumn get newValues => text().nullable()(); // JSON
  TextColumn get ipAddress => text().nullable()();
  TextColumn get userAgent => text().nullable()();
  TextColumn get details => text().nullable()();
  DateTimeColumn get performedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
