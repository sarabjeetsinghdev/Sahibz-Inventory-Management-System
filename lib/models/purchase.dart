
/// Purchase model class
/// 
/// This class represents a purchase with its details.
class Purchase {
  
  /// Unique identifier for this purchase.
  final int id;
  
  /// Unique identifier for this purchase to connect with purchase items.
  final String? purchaseId;
  
  /// Invoice number for this purchase.
  final String invoiceNumber;
  
  /// Payment method used for this purchase.
  final String paymentMethod;
  
  /// Total cost before tax for this purchase.
  final double totalCostBeforeTax;
  
  /// Total tax amount for this purchase.
  final double totalTaxAmount;

  /// Total cost after tax for this purchase.
  final double? totalCostAfterTax;
  
  /// Total discount for this purchase.
  final double totalDiscount;
  
  /// Grand total for this purchase.
  final double? grandTotal;
  
  /// Date of this purchase.
  final DateTime date;

  Purchase({
    required this.id,
    required this.purchaseId,
    required this.invoiceNumber,
    required this.paymentMethod,
    required this.totalCostBeforeTax,
    required this.totalTaxAmount,
    this.totalCostAfterTax,
    required this.totalDiscount,
    this.grandTotal,
    required this.date,
  });


  /// Converts this Purchase object to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purchase_id': purchaseId,
      'invoice_number': invoiceNumber,
      'payment_method': paymentMethod,
      'total_cost_before_tax': totalCostBeforeTax,
      'total_tax_amount': totalTaxAmount,
      'total_cost_after_tax': totalCostAfterTax,
      'total_discount': totalDiscount,
      'grand_total': grandTotal,
      'date': date.toIso8601String(),
    };
  }

  /// Creates a Purchase object from a JSON map.
  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'],
      purchaseId: json['purchase_id'],
      invoiceNumber: json['invoice_number'],
      paymentMethod: json['payment_method'],
      totalCostBeforeTax: json['total_cost_before_tax'],
      totalTaxAmount: json['total_tax_amount'],
      totalCostAfterTax: json['total_cost_after_tax'],
      totalDiscount: json['total_discount'],
      grandTotal: json['grand_total'],
      date: DateTime.parse(json['date']),
    );
  }
}