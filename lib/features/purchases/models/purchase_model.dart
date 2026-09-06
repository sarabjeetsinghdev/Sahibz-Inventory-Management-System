import 'package:sahibz_inventory/database/database.dart';

class PurchaseItemModel {
  final String id;
  final String purchaseId;
  final String productId;
  final String? productName;
  final double quantity;
  final double unitPrice;
  final double taxRate;
  final double taxAmount;
  final double discountAmount;
  final double totalPrice;
  final double receivedQuantity;
  final String? notes;

  const PurchaseItemModel({
    required this.id,
    required this.purchaseId,
    required this.productId,
    this.productName,
    this.quantity = 0.0,
    this.unitPrice = 0.0,
    this.taxRate = 0.0,
    this.taxAmount = 0.0,
    this.discountAmount = 0.0,
    this.totalPrice = 0.0,
    this.receivedQuantity = 0.0,
    this.notes,
  });

  PurchaseItemModel copyWith({
    String? id,
    String? purchaseId,
    String? productId,
    String? productName,
    double? quantity,
    double? unitPrice,
    double? taxRate,
    double? taxAmount,
    double? discountAmount,
    double? totalPrice,
    double? receivedQuantity,
    String? notes,
  }) {
    return PurchaseItemModel(
      id: id ?? this.id,
      purchaseId: purchaseId ?? this.purchaseId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      totalPrice: totalPrice ?? this.totalPrice,
      receivedQuantity: receivedQuantity ?? this.receivedQuantity,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'purchaseId': purchaseId,
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'taxRate': taxRate,
    'taxAmount': taxAmount,
    'discountAmount': discountAmount,
    'totalPrice': totalPrice,
    'receivedQuantity': receivedQuantity,
    'notes': notes,
  };

  factory PurchaseItemModel.fromJson(Map<String, dynamic> json) => PurchaseItemModel(
    id: json['id'] as String,
    purchaseId: json['purchaseId'] as String,
    productId: json['productId'] as String,
    productName: json['productName'] as String?,
    quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
    unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
    taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0.0,
    taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
    discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
    totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
    receivedQuantity: (json['receivedQuantity'] as num?)?.toDouble() ?? 0.0,
    notes: json['notes'] as String?,
  );

  static PurchaseItemModel fromPurchaseItem(PurchaseItem pi, {String? productName}) {
    return PurchaseItemModel(
      id: pi.id,
      purchaseId: pi.purchaseId,
      productId: pi.productId,
      productName: productName,
      quantity: pi.quantity,
      unitPrice: pi.unitPrice,
      taxRate: pi.taxRate,
      taxAmount: pi.taxAmount,
      discountAmount: pi.discountAmount,
      totalPrice: pi.totalPrice,
      receivedQuantity: pi.receivedQuantity,
      notes: pi.notes,
    );
  }
}

class PurchaseModel {
  final String id;
  final String orderNumber;
  final String supplierId;
  final String? supplierName;

  final String status;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double shippingAmount;
  final double totalAmount;
  final String? notes;
  final String? billingAddress;
  final String? shippingAddress;
  final String? paymentMethod;
  final String paymentStatus;
  final String createdBy;
  final String? createdByName;
  final String? approvedBy;
  final String? approvedByName;
  final DateTime? orderDate;
  final DateTime? expectedDelivery;
  final DateTime? receivedDate;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<PurchaseItemModel> items;

  const PurchaseModel({
    required this.id,
    required this.orderNumber,
    required this.supplierId,
    this.supplierName,

    this.status = 'pending',
    this.subtotal = 0.0,
    this.taxAmount = 0.0,
    this.discountAmount = 0.0,
    this.shippingAmount = 0.0,
    this.totalAmount = 0.0,
    this.notes,
    this.billingAddress,
    this.shippingAddress,
    this.paymentMethod,
    this.paymentStatus = 'unpaid',
    required this.createdBy,
    this.createdByName,
    this.approvedBy,
    this.approvedByName,
    this.orderDate,
    this.expectedDelivery,
    this.receivedDate,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
    this.items = const [],
  });

  PurchaseModel copyWith({
    String? id,
    String? orderNumber,
    String? supplierId,
    String? supplierName,

    String? status,
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
    String? createdBy,
    String? createdByName,
    String? approvedBy,
    String? approvedByName,
    DateTime? orderDate,
    DateTime? expectedDelivery,
    DateTime? receivedDate,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<PurchaseItemModel>? items,
  }) {
    return PurchaseModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,

      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      shippingAmount: shippingAmount ?? this.shippingAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      billingAddress: billingAddress ?? this.billingAddress,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedByName: approvedByName ?? this.approvedByName,
      orderDate: orderDate ?? this.orderDate,
      expectedDelivery: expectedDelivery ?? this.expectedDelivery,
      receivedDate: receivedDate ?? this.receivedDate,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderNumber': orderNumber,
    'supplierId': supplierId,
    'supplierName': supplierName,

    'status': status,
    'subtotal': subtotal,
    'taxAmount': taxAmount,
    'discountAmount': discountAmount,
    'shippingAmount': shippingAmount,
    'totalAmount': totalAmount,
    'notes': notes,
    'billingAddress': billingAddress,
    'shippingAddress': shippingAddress,
    'paymentMethod': paymentMethod,
    'paymentStatus': paymentStatus,
    'createdBy': createdBy,
    'createdByName': createdByName,
    'approvedBy': approvedBy,
    'approvedByName': approvedByName,
    'orderDate': orderDate?.toIso8601String(),
    'expectedDelivery': expectedDelivery?.toIso8601String(),
    'receivedDate': receivedDate?.toIso8601String(),
    'isDeleted': isDeleted,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'items': items.map((i) => i.toJson()).toList(),
  };

  factory PurchaseModel.fromJson(Map<String, dynamic> json) => PurchaseModel(
    id: json['id'] as String,
    orderNumber: json['orderNumber'] as String,
    supplierId: json['supplierId'] as String,
    supplierName: json['supplierName'] as String?,

    status: json['status'] as String? ?? 'pending',
    subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
    discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
    shippingAmount: (json['shippingAmount'] as num?)?.toDouble() ?? 0.0,
    totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
    notes: json['notes'] as String?,
    billingAddress: json['billingAddress'] as String?,
    shippingAddress: json['shippingAddress'] as String?,
    paymentMethod: json['paymentMethod'] as String?,
    paymentStatus: json['paymentStatus'] as String? ?? 'unpaid',
    createdBy: json['createdBy'] as String,
    createdByName: json['createdByName'] as String?,
    approvedBy: json['approvedBy'] as String?,
    approvedByName: json['approvedByName'] as String?,
    orderDate: json['orderDate'] != null ? DateTime.parse(json['orderDate'] as String) : null,
    expectedDelivery: json['expectedDelivery'] != null ? DateTime.parse(json['expectedDelivery'] as String) : null,
    receivedDate: json['receivedDate'] != null ? DateTime.parse(json['receivedDate'] as String) : null,
    isDeleted: json['isDeleted'] as bool? ?? false,
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    items: (json['items'] as List<dynamic>?)?.map((e) => PurchaseItemModel.fromJson(e as Map<String, dynamic>)).toList() ?? [],
  );

  static PurchaseModel fromPurchase(Purchase p, {String? supplierName, String? createdByName, String? approvedByName, List<PurchaseItemModel>? items}) {
    return PurchaseModel(
      id: p.id,
      orderNumber: p.orderNumber,
      supplierId: p.supplierId,
      supplierName: supplierName,

      status: p.status,
      subtotal: p.subtotal,
      taxAmount: p.taxAmount,
      discountAmount: p.discountAmount,
      shippingAmount: p.shippingAmount,
      totalAmount: p.totalAmount,
      notes: p.notes,
      billingAddress: p.billingAddress,
      shippingAddress: p.shippingAddress,
      paymentMethod: p.paymentMethod,
      paymentStatus: p.paymentStatus,
      createdBy: p.createdBy!,
      createdByName: createdByName,
      approvedBy: p.approvedBy,
      approvedByName: approvedByName,
      orderDate: p.orderDate,
      expectedDelivery: p.expectedDelivery,
      receivedDate: p.receivedDate,
      isDeleted: p.isDeleted,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
      items: items ?? [],
    );
  }

  bool get canApprove => status == 'pending';
  bool get canReceive => status == 'approved' || status == 'partially_received';
  bool get canClose => status == 'partially_received';
  bool get canCancel => status == 'pending' || status == 'approved';

  double get totalOrderedQuantity =>
      items.fold(0.0, (sum, i) => sum + i.quantity);
  double get totalReceivedQuantity =>
      items.fold(0.0, (sum, i) => sum + i.receivedQuantity);

  bool get isPartiallyReceived => status == 'partially_received';
}
