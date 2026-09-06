import 'package:sahibz_inventory/database/database.dart';

class ProductModel {
  final String id;
  final String name;
  final String sku;
  final String? barcode;
  final String? description;
  final String? categoryId;
  final String? categoryName;
  final String? supplierId;
  final String? supplierName;
  final double costPrice;
  final double sellingPrice;
  final double taxRate;
  final String taxType;
  final String unit;
  final double quantity;
  final double reorderLevel;
  final String? image;
  final String status;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.sku,
    this.barcode,
    this.description,
    this.categoryId,
    this.categoryName,
    this.supplierId,
    this.supplierName,
    this.costPrice = 0.0,
    this.sellingPrice = 0.0,
    this.taxRate = 0.0,
    this.taxType = 'percentage',
    this.unit = 'pcs',
    this.quantity = 0.0,
    this.reorderLevel = 0.0,
    this.image,
    this.status = 'active',
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  double get profit => sellingPrice - costPrice;
  double get profitMargin => costPrice > 0 ? (profit / costPrice) * 100 : 0;
  bool get isLowStock => quantity > 0 && quantity <= reorderLevel;
  bool get isOutOfStock => quantity <= 0;
  String get displayName => '$name ($sku)';

  ProductModel copyWith({
    String? id,
    String? name,
    String? sku,
    String? barcode,
    String? description,
    String? categoryId,
    String? categoryName,
    String? supplierId,
    String? supplierName,
    double? costPrice,
    double? sellingPrice,
    double? taxRate,
    String? taxType,
    String? unit,
    double? quantity,
    double? reorderLevel,
    String? image,
    String? status,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      taxRate: taxRate ?? this.taxRate,
      taxType: taxType ?? this.taxType,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      image: image ?? this.image,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sku': sku,
    'barcode': barcode,
    'description': description,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'supplierId': supplierId,
    'supplierName': supplierName,
    'costPrice': costPrice,
    'sellingPrice': sellingPrice,
    'taxRate': taxRate,
    'taxType': taxType,
    'unit': unit,
    'quantity': quantity,
    'reorderLevel': reorderLevel,
    'image': image,
    'status': status,
    'isDeleted': isDeleted,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
    id: json['id'] as String,
    name: json['name'] as String,
    sku: json['sku'] as String,
    barcode: json['barcode'] as String?,
    description: json['description'] as String?,
    categoryId: json['categoryId'] as String?,
    categoryName: json['categoryName'] as String?,
    supplierId: json['supplierId'] as String?,
    supplierName: json['supplierName'] as String?,
    costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0.0,
    sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0.0,
    taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0.0,
    taxType: json['taxType'] as String? ?? 'percentage',
    unit: json['unit'] as String? ?? 'pcs',
    quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
    reorderLevel: (json['reorderLevel'] as num?)?.toDouble() ?? 0.0,
    image: json['image'] as String?,
    status: json['status'] as String? ?? 'active',
    isDeleted: json['isDeleted'] as bool? ?? false,
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
  );

  static ProductModel fromProduct(Product p, {String? categoryName, String? supplierName, double quantity = 0.0}) {
    return ProductModel(
      id: p.id,
      name: p.name,
      sku: p.sku,
      barcode: p.barcode,
      description: p.description,
      categoryId: p.categoryId,
      categoryName: categoryName,
      supplierId: p.supplierId,
      supplierName: supplierName,
      costPrice: p.costPrice,
      sellingPrice: p.sellingPrice,
      taxRate: p.taxRate,
      taxType: p.taxType,
      unit: p.unit,
      quantity: quantity,
      reorderLevel: p.reorderLevel,
      image: p.image,
      status: p.status,
      isDeleted: p.isDeleted,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
    );
  }
}
