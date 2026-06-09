/// Purchase Item model class
///
/// This class represents a purchase item with its details.
class PurchaseItem {
  /// Unique identifier for this purchase item.
  final int id;

  /// Unique identifier for the purchase this item belongs to.
  final String purchaseId;

  /// Unique identifier for the supplier who provided this item.
  final String supplierId;

  /// Unique identifier for this purchase item.
  final String? uniqueId;

  /// Name of the product.
  final String productName;

  /// Cost of the product.
  double cost;

  /// Quantity of the product.
  double quantity;

  /// Quantity left of the product.
  double quantityLeft;

  /// Discount applied to the product.
  double discount;

  /// Total cost of the product.
  final double? total;

  /// Tax applied to the product.
  final double tax;
  
  /// Selling price of the product.
  final double sellingPrice;

  /// Date of the purchase.
  final String date;

  PurchaseItem({
    required this.id,
    required this.purchaseId,
    required this.supplierId,
    this.uniqueId,
    required this.productName,
    required this.cost,
    required this.quantity,
    required this.quantityLeft,
    required this.discount,
    this.total,
    required this.sellingPrice,
    required this.tax,
    required this.date,
  });

  /// Converts this PurchaseItem to a JSON map.
  ///
  /// This method is used to serialize the PurchaseItem object to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purchase_id': purchaseId,
      'supplier_id': supplierId,
      'unique_id': uniqueId,
      'product_name': productName,
      'cost': cost,
      'selling_price': sellingPrice,
      'quantity': quantity,
      'quantity_left': quantityLeft,
      'tax': tax,
      'discount': discount,
      'total': total,
      'date': date,
    };
  }

  /// Creates a PurchaseItem from a JSON map.
  ///
  /// This method is used to deserialize a JSON map to a PurchaseItem object.
  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    return PurchaseItem(
      id: json['id'],
      purchaseId: json['purchase_id'],
      supplierId: json['supplier_id'],
      uniqueId: json['unique_id'],
      productName: json['product_name'],
      cost: json['cost'],
      quantity: json['quantity'],
      quantityLeft: json['quantity_left'],
      discount: json['discount'],
      total: json['total'],
      sellingPrice: json['selling_price'],
      tax: json['tax'],
      date: json['date'],
    );
  }

  /// Copy with
  PurchaseItem copyWith({
    int? id,
    String? purchaseId,
    String? supplierId,
    String? uniqueId,
    String? productName,
    double? cost,
    double? quantity,
    double? quantityLeft,
    double? discount,
    double? total,
    double? sellingPrice,
    double? tax,
    String? date,
  }) {
    return PurchaseItem(
      id: id ?? this.id,
      purchaseId: purchaseId ?? this.purchaseId,
      supplierId: supplierId ?? this.supplierId,
      uniqueId: uniqueId ?? this.uniqueId,
      productName: productName ?? this.productName,
      cost: cost ?? this.cost,
      quantity: quantity ?? this.quantity,
      quantityLeft: quantityLeft ?? this.quantityLeft,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      tax: tax ?? this.tax,
      date: date ?? this.date,
    );
  }
}
