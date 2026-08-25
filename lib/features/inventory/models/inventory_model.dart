import 'package:sahibz_inventory/database/database.dart';

class InventoryTransactionModel {
  final String id;
  final String productId;
  final String? productName;
  final String type;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final double balanceBefore;
  final double balanceAfter;
  final String? reference;
  final String? referenceType;
  final String? notes;
  final String? batchNumber;
  final String? serialNumber;
  final String? performedBy;
  final DateTime? transactionDate;
  final DateTime? createdAt;

  const InventoryTransactionModel({
    required this.id,
    required this.productId,
    this.productName,
    required this.type,
    required this.quantity,
    this.unitPrice = 0.0,
    this.totalPrice = 0.0,
    this.balanceBefore = 0.0,
    this.balanceAfter = 0.0,
    this.reference,
    this.referenceType,
    this.notes,
    this.batchNumber,
    this.serialNumber,
    this.performedBy,
    this.transactionDate,
    this.createdAt,
  });

  bool get isStockIn => type == 'stock_in' || type == 'transfer_in';
  bool get isStockOut => type == 'stock_out' || type == 'transfer_out';
  bool get isAdjustment => type == 'adjustment';
  bool get isTransfer => type == 'transfer_in' || type == 'transfer_out';

  String get typeLabel {
    switch (type) {
      case 'stock_in':
        return 'Stock In';
      case 'stock_out':
        return 'Stock Out';
      case 'adjustment':
        return 'Adjustment';
      case 'transfer_in':
        return 'Transfer In';
      case 'transfer_out':
        return 'Transfer Out';
      default:
        return type;
    }
  }

  InventoryTransactionModel copyWith({
    String? id,
    String? productId,
    String? productName,
    String? type,
    double? quantity,
    double? unitPrice,
    double? totalPrice,
    double? balanceBefore,
    double? balanceAfter,
    String? reference,
    String? referenceType,
    String? notes,
    String? batchNumber,
    String? serialNumber,
    String? performedBy,
    DateTime? transactionDate,
    DateTime? createdAt,
  }) {
    return InventoryTransactionModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      balanceBefore: balanceBefore ?? this.balanceBefore,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      reference: reference ?? this.reference,
      referenceType: referenceType ?? this.referenceType,
      notes: notes ?? this.notes,
      batchNumber: batchNumber ?? this.batchNumber,
      serialNumber: serialNumber ?? this.serialNumber,
      performedBy: performedBy ?? this.performedBy,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'productName': productName,
    'type': type,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'totalPrice': totalPrice,
    'balanceBefore': balanceBefore,
    'balanceAfter': balanceAfter,
    'reference': reference,
    'referenceType': referenceType,
    'notes': notes,
    'batchNumber': batchNumber,
    'serialNumber': serialNumber,
    'performedBy': performedBy,
    'transactionDate': transactionDate?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
  };

  factory InventoryTransactionModel.fromJson(Map<String, dynamic> json) =>
      InventoryTransactionModel(
        id: json['id'] as String,
        productId: json['productId'] as String,
        productName: json['productName'] as String?,
        type: json['type'] as String,
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
        totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
        balanceBefore: (json['balanceBefore'] as num?)?.toDouble() ?? 0.0,
        balanceAfter: (json['balanceAfter'] as num?)?.toDouble() ?? 0.0,
        reference: json['reference'] as String?,
        referenceType: json['referenceType'] as String?,
        notes: json['notes'] as String?,
        batchNumber: json['batchNumber'] as String?,
        serialNumber: json['serialNumber'] as String?,
        performedBy: json['performedBy'] as String?,
        transactionDate: json['transactionDate'] != null
            ? DateTime.parse(json['transactionDate'] as String)
            : null,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );

  static InventoryTransactionModel fromInventoryTransaction(
    InventoryTransaction t, {
    String? productName,
  }) {
    return InventoryTransactionModel(
      id: t.id,
      productId: t.productId,
      productName: productName,
      type: t.type,
      quantity: t.quantity,
      unitPrice: t.unitPrice,
      totalPrice: t.totalPrice,
      balanceBefore: t.balanceBefore,
      balanceAfter: t.balanceAfter,
      reference: t.reference,
      referenceType: t.referenceType,
      notes: t.notes,
      batchNumber: t.batchNumber,
      serialNumber: t.serialNumber,
      performedBy: t.performedBy,
      transactionDate: t.transactionDate,
      createdAt: t.createdAt,
    );
  }
}

class StockSummaryModel {
  final String productId;
  final String productName;
  final String? productSku;
  final double totalQuantity;
  final double reorderLevel;

  const StockSummaryModel({
    required this.productId,
    required this.productName,
    this.productSku,
    required this.totalQuantity,
    this.reorderLevel = 0.0,
  });

  bool get isLowStock => totalQuantity > 0 && totalQuantity <= reorderLevel;
  bool get isOutOfStock => totalQuantity <= 0;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'productSku': productSku,
    'totalQuantity': totalQuantity,
    'reorderLevel': reorderLevel,
  };

  factory StockSummaryModel.fromJson(Map<String, dynamic> json) =>
      StockSummaryModel(
        productId: json['productId'] as String,
        productName: json['productName'] as String,
        productSku: json['productSku'] as String?,
        totalQuantity: (json['totalQuantity'] as num?)?.toDouble() ?? 0.0,
        reorderLevel: (json['reorderLevel'] as num?)?.toDouble() ?? 0.0,
      );
}
