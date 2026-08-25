import 'package:sahibz_inventory/database/database.dart';

class SaleItemModel {
  final String id;
  final String saleId;
  final String productId;
  final String? productName;
  final double quantity;
  final double unitPrice;
  final double taxRate;
  final double taxAmount;
  final double discountAmount;
  final double totalPrice;

  const SaleItemModel({
    required this.id,
    required this.saleId,
    required this.productId,
    this.productName,
    this.quantity = 0.0,
    this.unitPrice = 0.0,
    this.taxRate = 0.0,
    this.taxAmount = 0.0,
    this.discountAmount = 0.0,
    this.totalPrice = 0.0,
  });

  SaleItemModel copyWith({
    String? id,
    String? saleId,
    String? productId,
    String? productName,
    double? quantity,
    double? unitPrice,
    double? taxRate,
    double? taxAmount,
    double? discountAmount,
    double? totalPrice,
  }) {
    return SaleItemModel(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'saleId': saleId,
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'taxRate': taxRate,
    'taxAmount': taxAmount,
    'discountAmount': discountAmount,
    'totalPrice': totalPrice,
  };

  factory SaleItemModel.fromJson(Map<String, dynamic> json) => SaleItemModel(
    id: json['id'] as String,
    saleId: json['saleId'] as String,
    productId: json['productId'] as String,
    productName: json['productName'] as String?,
    quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
    unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
    taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0.0,
    taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
    discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
    totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
  );

  static SaleItemModel fromSaleItem(SalesItem si, {String? productName}) {
    return SaleItemModel(
      id: si.id,
      saleId: si.saleId,
      productId: si.productId,
      productName: productName,
      quantity: si.quantity,
      unitPrice: si.unitPrice,
      taxRate: si.taxRate,
      taxAmount: si.taxAmount,
      discountAmount: si.discountAmount,
      totalPrice: si.totalPrice,
    );
  }
}

class SaleModel {
  final String id;
  final String invoiceNumber;
  final String? customerId;
  final String? customerName;
  final String status;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final double paidAmount;
  final double dueAmount;
  final String? paymentMethod;
  final String paymentStatus;
  final String? notes;
  final String? billingAddress;
  final String? shippingAddress;
  final String createdBy;
  final String? createdByName;
  final DateTime? saleDate;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<SaleItemModel> items;

  const SaleModel({
    required this.id,
    required this.invoiceNumber,
    this.customerId,
    this.customerName,
    this.status = 'pending',
    this.subtotal = 0.0,
    this.taxAmount = 0.0,
    this.discountAmount = 0.0,
    this.totalAmount = 0.0,
    this.paidAmount = 0.0,
    this.dueAmount = 0.0,
    this.paymentMethod,
    this.paymentStatus = 'unpaid',
    this.notes,
    this.billingAddress,
    this.shippingAddress,
    required this.createdBy,
    this.createdByName,
    this.saleDate,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
    this.items = const [],
  });

  SaleModel copyWith({
    String? id,
    String? invoiceNumber,
    String? customerId,
    String? customerName,
    String? status,
    double? subtotal,
    double? taxAmount,
    double? discountAmount,
    double? totalAmount,
    double? paidAmount,
    double? dueAmount,
    String? paymentMethod,
    String? paymentStatus,
    String? notes,
    String? billingAddress,
    String? shippingAddress,
    String? createdBy,
    String? createdByName,
    DateTime? saleDate,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<SaleItemModel>? items,
  }) {
    return SaleModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      dueAmount: dueAmount ?? this.dueAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      billingAddress: billingAddress ?? this.billingAddress,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      saleDate: saleDate ?? this.saleDate,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'invoiceNumber': invoiceNumber,
    'customerId': customerId,
    'customerName': customerName,
    'status': status,
    'subtotal': subtotal,
    'taxAmount': taxAmount,
    'discountAmount': discountAmount,
    'totalAmount': totalAmount,
    'paidAmount': paidAmount,
    'dueAmount': dueAmount,
    'paymentMethod': paymentMethod,
    'paymentStatus': paymentStatus,
    'notes': notes,
    'billingAddress': billingAddress,
    'shippingAddress': shippingAddress,
    'createdBy': createdBy,
    'createdByName': createdByName,
    'saleDate': saleDate?.toIso8601String(),
    'isDeleted': isDeleted,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'items': items.map((i) => i.toJson()).toList(),
  };

  factory SaleModel.fromJson(Map<String, dynamic> json) => SaleModel(
    id: json['id'] as String,
    invoiceNumber: json['invoiceNumber'] as String,
    customerId: json['customerId'] as String?,
    customerName: json['customerName'] as String?,
    status: json['status'] as String? ?? 'pending',
    subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
    discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
    totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
    paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
    dueAmount: (json['dueAmount'] as num?)?.toDouble() ?? 0.0,
    paymentMethod: json['paymentMethod'] as String?,
    paymentStatus: json['paymentStatus'] as String? ?? 'unpaid',
    notes: json['notes'] as String?,
    billingAddress: json['billingAddress'] as String?,
    shippingAddress: json['shippingAddress'] as String?,
    createdBy: json['createdBy'] as String,
    createdByName: json['createdByName'] as String?,
    saleDate: json['saleDate'] != null ? DateTime.parse(json['saleDate'] as String) : null,
    isDeleted: json['isDeleted'] as bool? ?? false,
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    items: (json['items'] as List<dynamic>?)?.map((e) => SaleItemModel.fromJson(e as Map<String, dynamic>)).toList() ?? [],
  );

  static SaleModel fromSale(Sale s, {String? customerName, String? createdByName, List<SaleItemModel>? items}) {
    return SaleModel(
      id: s.id,
      invoiceNumber: s.invoiceNumber,
      customerId: s.customerId,
      customerName: customerName,
      status: s.status,
      subtotal: s.subtotal,
      taxAmount: s.taxAmount,
      discountAmount: s.discountAmount,
      totalAmount: s.totalAmount,
      paidAmount: s.paidAmount,
      dueAmount: s.dueAmount,
      paymentMethod: s.paymentMethod,
      paymentStatus: s.paymentStatus,
      notes: s.notes,
      billingAddress: s.billingAddress,
      shippingAddress: s.shippingAddress,
      createdBy: s.createdBy!,
      createdByName: createdByName,
      saleDate: s.saleDate,
      isDeleted: s.isDeleted,
      createdAt: s.createdAt,
      updatedAt: s.updatedAt,
      items: items ?? [],
    );
  }

  bool get canComplete => status == 'pending';
  bool get canCancel => status == 'pending';
}
