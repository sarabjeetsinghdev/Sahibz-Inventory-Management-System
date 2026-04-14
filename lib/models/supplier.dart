/// A class representing a supplier in the system.
///
/// This class holds the details of a supplier, including their ID, name,
/// contact information, email address, address, and date of addition.
class Supplier {
  /// The unique ID of the supplier.
  final int id;

  /// The name of the supplier.
  final String name;

  /// The contact information of the supplier.
  final String contact;

  /// The email address of the supplier.
  final String email;

  /// The address of the supplier.
  final String address;

  /// [DateTime] - The date when the supplier was added to the system.
  final DateTime date;

  /// Creates a [Supplier] object with the given details.
  ///
  /// All the parameters are required.
  Supplier({
    required this.id,
    required this.name,
    required this.contact,
    required this.email,
    required this.address,
    required this.date,
  });

  /// Converts this [Supplier] object to a JSON-compatible map.
  ///
  /// The returned map contains the same keys expected by [fromMap].
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contact': contact,
      'email': email,
      'address': address,
      'date': date.toIso8601String(),
    };
  }

  /// Creates a [Supplier] object from a JSON-compatible map.
  ///
  /// The keys of the map should match the property names of the [Supplier]
  /// class.
  factory Supplier.fromJson(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'],
      name: map['name'],
      contact: map['contact'],
      email: map['email'],
      address: map['address'],
      date: DateTime.parse(map['date']),
    );
  }
}