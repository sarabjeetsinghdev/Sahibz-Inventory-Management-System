class Inventory {
  final int id;
  final String? label;
  final String name;
  final String company;
  final String unit;
  final DateTime date;
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