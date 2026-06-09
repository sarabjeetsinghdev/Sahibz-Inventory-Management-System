
/// Enum representing different types of recent activities.
enum RecentActivityType {
  /// Activity type for when an inventory item is added.
  inventoryAdded('Inventory added'),
  
  /// Activity type for when an inventory item is removed.
  inventoryRemoved('Inventory removed'),
  
  /// Activity type for when an inventory item is updated.
  inventoryUpdated('Inventory updated'),
  
  /// Activity type for when an expense is added.
  expenseAdded('Expense added'),
  
  /// Activity type for when an expense is removed.
  expenseRemoved('Expense removed'),
  
  /// Activity type for when an expense is updated.
  expenseUpdated('Expense updated'),
  
  /// Activity type for when a supplier is added.
  supplierAdded('Supplier added'),

  /// Activity type for when a supplier is updated.
  supplierUpdated('Supplier updated'),

  /// Activity type for when a supplier is removed.
  supplierRemoved('Supplier removed'),

  /// Activity type for when a purchase is added.
  purchaseAdded('Purchase added'),

  /// Activity type for when a purchase is updated.
  purchaseUpdated('Purchase updated'),

  /// Activity type for when a purchase is removed.
  purchaseRemoved('Purchase removed'),

  /// Activity type for when a purchase item is added.
  purchaseItemAdded('Purchase item added'),

  /// Activity type for when a purchase item is updated.
  purchaseItemUpdated('Purchase item updated'),

  /// Activity type for when a purchase item is removed.
  purchaseItemRemoved('Purchase item removed'),
  
  /// Activity type for when a sale is added.
  saleAdded('Sale added'),
  
  /// Activity type for when a sale is updated.
  saleUpdated('Sale updated'),
  
  /// Activity type for when a sale is removed.
  saleRemoved('Sale removed'),

  /// Activity type for when a sale item is added.
  saleItemAdded('Sale item added'),
  
  /// Activity type for when a sale item is updated.
  saleItemUpdated('Sale item updated'),
  
  /// Activity type for when a sale item is removed.
  saleItemRemoved('Sale item removed');

  const RecentActivityType(this.value);

  final String value;
}


/// Class representing a recent activity in the system.
class RecentActivity {
  /// Unique identifier for the activity.
  final int id;
  
  /// [RecentActivityType] Type of the activity.
  final RecentActivityType type;
  
  /// [DateTime] Date and time when the activity occurred.
  final DateTime date;

  const RecentActivity({
    required this.id,
    required this.type,
    required this.date,
  });

  /// Creates a [RecentActivity] instance from a JSON map.
  ///
  /// The JSON map must contain the following keys:
  /// - "id" : [int]
  /// - "type" : [String]
  /// - "date" : [String] (ISO 8601 format)
  /// Throws [FormatException] if the date strings are not in valid ISO 8601 format.
  factory RecentActivity.fromJson(Map<String, Object?> json) => RecentActivity(
        id: json['id'] as int,
        type: RecentActivityType.values.firstWhere((element) => element.value == json['type'] as String),
        date: DateTime.parse(json['date'] as String),
      );

  /// Converts this [RecentActivity] to a JSON map.
  ///
  /// The returned map will contain the following keys:
  /// - "id" : [int]
  /// - "type" : [String]
  /// - "date" : [String] (ISO 8601 format)
  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.value,
        'date': date.toIso8601String(),
      };
}
