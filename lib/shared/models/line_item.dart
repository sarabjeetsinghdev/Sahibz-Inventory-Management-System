class LineItem {
  String? productId;
  String productName;
  double quantity;
  double unitPrice;
  double total;
  String? productSku;

  LineItem({
    this.productId,
    required this.productName,
    this.quantity = 1,
    this.unitPrice = 0,
    this.total = 0,
    this.productSku,
  });

  double get calculatedTotal => quantity * unitPrice;
}
