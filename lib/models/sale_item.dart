class SaleItem {
  final int id;
  final String saleId;
  final String purchaseId;
  final String? uniqueId;
  final String supplierId;
  final String productName;
  final double quantity;
  final double price;
  final double discount;
  final double tax;
  final double? netTotal;
  final double? netProfit;
  final double cost;
  final String date;

  SaleItem({
    required this.id,
    required this.saleId,
    required this.purchaseId,
    this.uniqueId,
    required this.supplierId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.discount,
    required this.tax,
    this.netTotal,
    this.netProfit,
    required this.cost,
    required this.date,
  });

  factory SaleItem.fromJson(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'],
      saleId: map['sale_id'],
      purchaseId: map['purchase_id'],
      uniqueId: map['unique_id'],
      supplierId: map['supplier_id'],
      productName: map['product_name'],
      quantity: map['quantity'],
      price: map['price'],
      discount: map['discount'],
      tax: map['tax'],
      netTotal: map['net_total'],
      netProfit: map['net_profit'],
      cost: map['cost'],
      date: map['date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sale_id': saleId,
      'purchase_id': purchaseId,
      'unique_id': uniqueId,
      'supplier_id': supplierId,
      'product_name': productName,
      'quantity': quantity,
      'price': price,
      'discount': discount,
      'tax': tax,
      'net_total': netTotal,
      'net_profit': netProfit,
      'cost': cost,
      'date': date,
    };
  }


  SaleItem copyWith({
    int? id,
    String? saleId,
    String? purchaseId,
    String? uniqueId,
    String? supplierId,
    String? productName,
    double? quantity,
    double? price,
    double? discount,
    double? tax,
    double? netTotal,
    double? netProfit,
    double? cost,
    String? date,
  }) {
    return SaleItem(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      purchaseId: purchaseId ?? this.purchaseId,
      uniqueId: uniqueId ?? this.uniqueId,
      supplierId: supplierId ?? this.supplierId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      netTotal: netTotal ?? this.netTotal,
      netProfit: netProfit ?? this.netProfit,
      cost: cost ?? this.cost,
      date: date ?? this.date,
    );
  }


}
