
/// Inventory model class
/// 
/// This class represents an inventory item with its details.
class Inventory {
  /// Unique identifier for this inventory item.
  final int id;
  
  /// Optional label for the inventory item.
  final String? label;
  
  /// Name of the inventory item.
  final String name;
  
  /// Company associated with the inventory item.
  final String company;
  
  /// Unit of measurement for the inventory item.
  final String unit;
  
  /// [DateTime] Date when the inventory item was created.
  final DateTime date;
  
  /// Optional [DateTime] update date for the inventory item.
  final DateTime? updateDate;

  const Inventory({
    required this.id,
    this.label,
    required this.name,
    required this.company,
    required this.unit,
    required this.date,
    this.updateDate,
  });


  /// Creates an [Inventory] from a JSON map.
  ///
  /// The JSON map must contain the following keys:
  /// - "id" : [int]
  /// - "label" : [String] (optional)
  /// - "name" : [String]
  /// - "company" : [String]
  /// - "unit" : [String]
  /// - "date" : [String] (ISO 8601 format)
  /// - "update_date" : [String] (ISO 8601 format, optional)
  /// Throws [FormatException] if the date strings are not in valid ISO 8601 format.
  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      id: json['id'] as int,
      label: json['label'] as String?,
      name: json['name'] as String,
      company: json['company'] as String,
      unit: json['unit'] as String,
      date: DateTime.parse(json['date'] as String),
      updateDate: json['update_date'] != null ? DateTime.parse(json['update_date'] as String) : null,
    );
  }

  /// Converts this [Inventory] to a JSON map.
  ///
  /// The returned map will contain the following keys:
  /// - "id" : [int]
  /// - "label" : [String] (optional)
  /// - "name" : [String]
  /// - "company" : [String]
  /// - "unit" : [String]
  /// - "date" : [String] (ISO 8601 format)
  /// - "update_date" : [String] (ISO 8601 format, optional)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'name': name,
      'company': company,
      'unit': unit,
      'date': date.toIso8601String(),
      'update_date': updateDate?.toIso8601String(),
    };
  }
}