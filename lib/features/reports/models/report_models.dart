class ReportFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? type;
  final String? status;
  final String? categoryId;
  final String? supplierId;
  final String? customerId;
  final String? productId;
  final String? search;

  const ReportFilter({
    this.startDate,
    this.endDate,
    this.type,
    this.status,
    this.categoryId,
    this.supplierId,
    this.customerId,
    this.productId,
    this.search,
  });

  ReportFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    String? status,
    String? categoryId,
    String? supplierId,
    String? customerId,
    String? productId,
    String? search,
  }) {
    return ReportFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
      status: status ?? this.status,
      categoryId: categoryId ?? this.categoryId,
      supplierId: supplierId ?? this.supplierId,
      customerId: customerId ?? this.customerId,
      productId: productId ?? this.productId,
      search: search ?? this.search,
    );
  }

  Map<String, dynamic> toJson() => {
    'startDate': startDate?.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'type': type,
    'status': status,
    'categoryId': categoryId,
    'supplierId': supplierId,
    'customerId': customerId,
    'productId': productId,
    'search': search,
  };

  factory ReportFilter.fromJson(Map<String, dynamic> json) => ReportFilter(
    startDate: json['startDate'] != null ? DateTime.parse(json['startDate'] as String) : null,
    endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
    type: json['type'] as String?,
    status: json['status'] as String?,
    categoryId: json['categoryId'] as String?,
    supplierId: json['supplierId'] as String?,
    customerId: json['customerId'] as String?,
    productId: json['productId'] as String?,
    search: json['search'] as String?,
  );
}

class ReportSummary {
  final double totalAmount;
  final int totalCount;
  final double averageAmount;
  final double minAmount;
  final double maxAmount;

  const ReportSummary({
    this.totalAmount = 0.0,
    this.totalCount = 0,
    this.averageAmount = 0.0,
    this.minAmount = 0.0,
    this.maxAmount = 0.0,
  });

  factory ReportSummary.fromValues(List<num> values) {
    if (values.isEmpty) return const ReportSummary();
    final double total = values.fold(0.0, (sum, v) => sum + v.toDouble());
    final double min = values.map((v) => v.toDouble()).reduce((a, b) => a < b ? a : b);
    final double max = values.map((v) => v.toDouble()).reduce((a, b) => a > b ? a : b);
    return ReportSummary(
      totalAmount: total,
      totalCount: values.length,
      averageAmount: total / values.length,
      minAmount: min,
      maxAmount: max,
    );
  }

  Map<String, dynamic> toJson() => {
    'totalAmount': totalAmount,
    'totalCount': totalCount,
    'averageAmount': averageAmount,
    'minAmount': minAmount,
    'maxAmount': maxAmount,
  };

  factory ReportSummary.fromJson(Map<String, dynamic> json) => ReportSummary(
    totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
    totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
    averageAmount: (json['averageAmount'] as num?)?.toDouble() ?? 0.0,
    minAmount: (json['minAmount'] as num?)?.toDouble() ?? 0.0,
    maxAmount: (json['maxAmount'] as num?)?.toDouble() ?? 0.0,
  );
}

class InventoryReportRow {
  final String productId;
  final String productName;
  final String sku;
  final String? categoryName;
  final double quantity;
  final double costPrice;
  final double sellingPrice;
  final double stockValue;
  final double potentialRevenue;
  final double reorderLevel;

  const InventoryReportRow({
    required this.productId,
    required this.productName,
    required this.sku,
    this.categoryName,
    this.quantity = 0.0,
    this.costPrice = 0.0,
    this.sellingPrice = 0.0,
    this.stockValue = 0.0,
    this.potentialRevenue = 0.0,
    this.reorderLevel = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'sku': sku,
    'categoryName': categoryName,
    'quantity': quantity,
    'costPrice': costPrice,
    'sellingPrice': sellingPrice,
    'stockValue': stockValue,
    'potentialRevenue': potentialRevenue,
    'reorderLevel': reorderLevel,
  };
}

class InventoryValuationRow {
  final String? productId;
  final String? productName;
  final String? sku;
  final double quantity;
  final double unitCost;
  final double totalValue;

  const InventoryValuationRow({
    this.productId,
    this.productName,
    this.sku,
    this.quantity = 0.0,
    this.unitCost = 0.0,
    this.totalValue = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'sku': sku,
    'quantity': quantity,
    'unitCost': unitCost,
    'totalValue': totalValue,
  };
}

class StockMovementRow {
  final String transactionId;
  final DateTime? date;
  final String productName;
  final String sku;
  final String type;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final double balanceAfter;
  final String? reference;
  final String? notes;

  const StockMovementRow({
    required this.transactionId,
    this.date,
    required this.productName,
    required this.sku,
    required this.type,
    this.quantity = 0.0,
    this.unitPrice = 0.0,
    this.totalPrice = 0.0,
    this.balanceAfter = 0.0,
    this.reference,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'transactionId': transactionId,
    'date': date?.toIso8601String(),
    'productName': productName,
    'sku': sku,
    'type': type,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'totalPrice': totalPrice,
    'balanceAfter': balanceAfter,
    'reference': reference,
    'notes': notes,
  };
}

class SalesReportRow {
  final String invoiceNumber;
  final DateTime? saleDate;
  final String? customerName;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final double paidAmount;
  final double dueAmount;
  final String paymentStatus;
  final String status;
  final int itemCount;

  const SalesReportRow({
    required this.invoiceNumber,
    this.saleDate,
    this.customerName,
    this.subtotal = 0.0,
    this.taxAmount = 0.0,
    this.discountAmount = 0.0,
    this.totalAmount = 0.0,
    this.paidAmount = 0.0,
    this.dueAmount = 0.0,
    this.paymentStatus = 'unpaid',
    this.status = 'pending',
    this.itemCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'invoiceNumber': invoiceNumber,
    'saleDate': saleDate?.toIso8601String(),
    'customerName': customerName,
    'subtotal': subtotal,
    'taxAmount': taxAmount,
    'discountAmount': discountAmount,
    'totalAmount': totalAmount,
    'paidAmount': paidAmount,
    'dueAmount': dueAmount,
    'paymentStatus': paymentStatus,
    'status': status,
    'itemCount': itemCount,
  };
}

class PurchaseReportRow {
  final String orderNumber;
  final DateTime? orderDate;
  final String? supplierName;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double shippingAmount;
  final double totalAmount;
  final String paymentStatus;
  final String status;
  final int itemCount;

  const PurchaseReportRow({
    required this.orderNumber,
    this.orderDate,
    this.supplierName,
    this.subtotal = 0.0,
    this.taxAmount = 0.0,
    this.discountAmount = 0.0,
    this.shippingAmount = 0.0,
    this.totalAmount = 0.0,
    this.paymentStatus = 'unpaid',
    this.status = 'pending',
    this.itemCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'orderNumber': orderNumber,
    'orderDate': orderDate?.toIso8601String(),
    'supplierName': supplierName,
    'subtotal': subtotal,
    'taxAmount': taxAmount,
    'discountAmount': discountAmount,
    'shippingAmount': shippingAmount,
    'totalAmount': totalAmount,
    'paymentStatus': paymentStatus,
    'status': status,
    'itemCount': itemCount,
  };
}

class SupplierReportRow {
  final String supplierId;
  final String companyName;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final int totalPurchases;
  final double totalAmount;
  final double averageOrderValue;
  final int totalItems;
  final String status;

  const SupplierReportRow({
    required this.supplierId,
    required this.companyName,
    this.contactPerson,
    this.phone,
    this.email,
    this.totalPurchases = 0,
    this.totalAmount = 0.0,
    this.averageOrderValue = 0.0,
    this.totalItems = 0,
    this.status = 'active',
  });

  Map<String, dynamic> toJson() => {
    'supplierId': supplierId,
    'companyName': companyName,
    'contactPerson': contactPerson,
    'phone': phone,
    'email': email,
    'totalPurchases': totalPurchases,
    'totalAmount': totalAmount,
    'averageOrderValue': averageOrderValue,
    'totalItems': totalItems,
    'status': status,
  };
}

class CustomerReportRow {
  final String customerId;
  final String name;
  final String? phone;
  final String? email;
  final int totalSales;
  final double totalAmount;
  final double averageOrderValue;
  final double totalPaid;
  final double totalDue;
  final String status;

  const CustomerReportRow({
    required this.customerId,
    required this.name,
    this.phone,
    this.email,
    this.totalSales = 0,
    this.totalAmount = 0.0,
    this.averageOrderValue = 0.0,
    this.totalPaid = 0.0,
    this.totalDue = 0.0,
    this.status = 'active',
  });

  Map<String, dynamic> toJson() => {
    'customerId': customerId,
    'name': name,
    'phone': phone,
    'email': email,
    'totalSales': totalSales,
    'totalAmount': totalAmount,
    'averageOrderValue': averageOrderValue,
    'totalPaid': totalPaid,
    'totalDue': totalDue,
    'status': status,
  };
}

class FinancialSummaryRow {
  final double totalRevenue;
  final double totalCost;
  final double grossProfit;
  final double grossMargin;
  final double totalExpenses;
  final double netProfit;
  final double netMargin;
  final double totalTax;
  final double totalDiscount;
  final double outstandingReceivables;
  final double outstandingPayables;

  const FinancialSummaryRow({
    this.totalRevenue = 0.0,
    this.totalCost = 0.0,
    this.grossProfit = 0.0,
    this.grossMargin = 0.0,
    this.totalExpenses = 0.0,
    this.netProfit = 0.0,
    this.netMargin = 0.0,
    this.totalTax = 0.0,
    this.totalDiscount = 0.0,
    this.outstandingReceivables = 0.0,
    this.outstandingPayables = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'totalRevenue': totalRevenue,
    'totalCost': totalCost,
    'grossProfit': grossProfit,
    'grossMargin': grossMargin,
    'totalExpenses': totalExpenses,
    'netProfit': netProfit,
    'netMargin': netMargin,
    'totalTax': totalTax,
    'totalDiscount': totalDiscount,
    'outstandingReceivables': outstandingReceivables,
    'outstandingPayables': outstandingPayables,
  };
}

class AuditReportRow {
  final String id;
  final DateTime? performedAt;
  final String? userName;
  final String action;
  final String entityType;
  final String? entityId;
  final String? details;

  const AuditReportRow({
    required this.id,
    this.performedAt,
    this.userName,
    required this.action,
    required this.entityType,
    this.entityId,
    this.details,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'performedAt': performedAt?.toIso8601String(),
    'userName': userName,
    'action': action,
    'entityType': entityType,
    'entityId': entityId,
    'details': details,
  };
}
