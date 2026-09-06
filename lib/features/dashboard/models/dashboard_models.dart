class DashboardStats {
  final int totalProducts;
  final int totalCategories;
  final int totalSuppliers;
  final int totalCustomers;
  final double inventoryValue;
  final double todaySales;
  final double monthlySales;
  final double todayPurchases;
  final double monthlyPurchases;
  final int lowStockProducts;
  final int outOfStockProducts;

  const DashboardStats({
    this.totalProducts = 0,
    this.totalCategories = 0,
    this.totalSuppliers = 0,
    this.totalCustomers = 0,
    this.inventoryValue = 0.0,
    this.todaySales = 0.0,
    this.monthlySales = 0.0,
    this.todayPurchases = 0.0,
    this.monthlyPurchases = 0.0,
    this.lowStockProducts = 0,
    this.outOfStockProducts = 0,
  });

  DashboardStats copyWith({
    int? totalProducts,
    int? totalCategories,
    int? totalSuppliers,
    int? totalCustomers,
    double? inventoryValue,
    double? todaySales,
    double? monthlySales,
    double? todayPurchases,
    double? monthlyPurchases,
    int? lowStockProducts,
    int? outOfStockProducts,
  }) {
    return DashboardStats(
      totalProducts: totalProducts ?? this.totalProducts,
      totalCategories: totalCategories ?? this.totalCategories,
      totalSuppliers: totalSuppliers ?? this.totalSuppliers,
      totalCustomers: totalCustomers ?? this.totalCustomers,
      inventoryValue: inventoryValue ?? this.inventoryValue,
      todaySales: todaySales ?? this.todaySales,
      monthlySales: monthlySales ?? this.monthlySales,
      todayPurchases: todayPurchases ?? this.todayPurchases,
      monthlyPurchases: monthlyPurchases ?? this.monthlyPurchases,
      lowStockProducts: lowStockProducts ?? this.lowStockProducts,
      outOfStockProducts: outOfStockProducts ?? this.outOfStockProducts,
    );
  }

  Map<String, dynamic> toJson() => {
    'totalProducts': totalProducts,
    'totalCategories': totalCategories,
    'totalSuppliers': totalSuppliers,
    'totalCustomers': totalCustomers,
    'inventoryValue': inventoryValue,
    'todaySales': todaySales,
    'monthlySales': monthlySales,
    'todayPurchases': todayPurchases,
    'monthlyPurchases': monthlyPurchases,
    'lowStockProducts': lowStockProducts,
    'outOfStockProducts': outOfStockProducts,
  };

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
    totalProducts: (json['totalProducts'] as num?)?.toInt() ?? 0,
    totalCategories: (json['totalCategories'] as num?)?.toInt() ?? 0,
    totalSuppliers: (json['totalSuppliers'] as num?)?.toInt() ?? 0,
    totalCustomers: (json['totalCustomers'] as num?)?.toInt() ?? 0,
    inventoryValue: (json['inventoryValue'] as num?)?.toDouble() ?? 0.0,
    todaySales: (json['todaySales'] as num?)?.toDouble() ?? 0.0,
    monthlySales: (json['monthlySales'] as num?)?.toDouble() ?? 0.0,
    todayPurchases: (json['todayPurchases'] as num?)?.toDouble() ?? 0.0,
    monthlyPurchases: (json['monthlyPurchases'] as num?)?.toDouble() ?? 0.0,
    lowStockProducts: (json['lowStockProducts'] as num?)?.toInt() ?? 0,
    outOfStockProducts: (json['outOfStockProducts'] as num?)?.toInt() ?? 0,
  );
}

class SalesDataPoint {
  final DateTime date;
  final double amount;

  const SalesDataPoint({required this.date, required this.amount});

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'amount': amount,
  };

  factory SalesDataPoint.fromJson(Map<String, dynamic> json) => SalesDataPoint(
    date: DateTime.parse(json['date'] as String),
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
  );
}

class PurchaseDataPoint {
  final DateTime date;
  final double amount;

  const PurchaseDataPoint({required this.date, required this.amount});

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'amount': amount,
  };

  factory PurchaseDataPoint.fromJson(Map<String, dynamic> json) => PurchaseDataPoint(
    date: DateTime.parse(json['date'] as String),
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
  );
}

class InventoryDataPoint {
  final DateTime date;
  final double quantity;

  const InventoryDataPoint({required this.date, required this.quantity});

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'quantity': quantity,
  };

  factory InventoryDataPoint.fromJson(Map<String, dynamic> json) => InventoryDataPoint(
    date: DateTime.parse(json['date'] as String),
    quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
  );
}
