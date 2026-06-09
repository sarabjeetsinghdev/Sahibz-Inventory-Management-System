class Sale {
  final int id;
  final String? saleId;
  final String? referenceNumber;
  final String paymentMethod;
  final double grossTotal;
  final double totalTax;
  final double totalDiscount;
  final double? netTotal;
  final DateTime date;

  Sale({
    required this.id,
    this.saleId,
    this.referenceNumber,
    required this.paymentMethod,
    required this.grossTotal,
    required this.totalTax,
    required this.totalDiscount,
    this.netTotal,
    required this.date,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'],
      saleId: json['sale_id'],
      referenceNumber: json['reference_number'],
      paymentMethod: json['payment_method'],
      grossTotal: json['gross_total'],
      totalTax: json['total_tax'],
      totalDiscount: json['total_discount'],
      netTotal: json['net_total'],
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sale_id': saleId,
      'reference_number': referenceNumber,
      'payment_method': paymentMethod,
      'gross_total': grossTotal,
      'total_tax': totalTax,
      'total_discount': totalDiscount,
      'net_total': netTotal,
      'date': date.toIso8601String(),
    };
  }

  Sale copyWith({
    int? id,
    String? saleId,
    String? referenceNumber,
    String? paymentMethod,
    double? grossTotal,
    double? totalTax,
    double? totalDiscount,
    double? netTotal,
    DateTime? date,
  }) {
    return Sale(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      grossTotal: grossTotal ?? this.grossTotal,
      totalTax: totalTax ?? this.totalTax,
      totalDiscount: totalDiscount ?? this.totalDiscount,
      netTotal: netTotal ?? this.netTotal,
      date: date ?? this.date,
    );
  }
}
