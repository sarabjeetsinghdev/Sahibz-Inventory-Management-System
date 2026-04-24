/// Purchase Item model class
///
/// This class represents a purchase item with its details.
class PurchaseItem {
  /// Unique identifier for this purchase item.
  final int id;

  /// Unique identifier for the purchase this item belongs to.
  final String purchaseId;

  /// Unique identifier for the supplier who provided this item.
  final String? supplierId;

  /// Unique identifier for this purchase item.
  final String? uniqueId;

  /// Name of the product.
  final String productName;

  /// Cost of the product.
  final double cost;

  /// Quantity of the product.
  final double quantity;

  /// Discount applied to the product.
  final double discount;

  /// Total cost of the product.
  final double? total;

  /// Date of the purchase.
  final String date;

  PurchaseItem({
    required this.id,
    required this.purchaseId,
    this.supplierId,
    this.uniqueId,
    required this.productName,
    required this.cost,
    required this.quantity,
    required this.discount,
    this.total,
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
      'quantity': quantity,
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
      discount: json['discount'],
      total: json['total'],
      date: json['date'],
    );
  }

  // Comparison operator
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PurchaseItem &&
        other.purchaseId == purchaseId &&
        other.supplierId == supplierId &&
        other.uniqueId == uniqueId &&
        other.productName == productName &&
        other.cost == cost &&
        other.quantity == quantity &&
        other.discount == discount &&
        other.date == date;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        purchaseId.hashCode ^
        supplierId.hashCode ^
        uniqueId.hashCode ^
        productName.hashCode ^
        cost.hashCode ^
        quantity.hashCode ^
        discount.hashCode ^
        total.hashCode ^
        date.hashCode;
  }
}
