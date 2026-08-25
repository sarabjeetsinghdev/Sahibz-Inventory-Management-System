import 'package:sahibz_inventory/database/database.dart';

class CustomerModel {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? tinNumber;
  final String? notes;
  final String status;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CustomerModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.tinNumber,
    this.notes,
    this.status = 'active',
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  CustomerModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? tinNumber,
    String? notes,
    String? status,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      tinNumber: tinNumber ?? this.tinNumber,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'address': address,
    'city': city,
    'state': state,
    'pincode': pincode,
    'tinNumber': tinNumber,
    'notes': notes,
    'status': status,
    'isDeleted': isDeleted,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory CustomerModel.fromJson(Map<String, dynamic> json) => CustomerModel(
    id: json['id'] as String,
    name: json['name'] as String,
    phone: json['phone'] as String?,
    email: json['email'] as String?,
    address: json['address'] as String?,
    city: json['city'] as String?,
    state: json['state'] as String?,
    pincode: json['pincode'] as String?,
    tinNumber: json['tinNumber'] as String?,
    notes: json['notes'] as String?,
    status: json['status'] as String? ?? 'active',
    isDeleted: json['isDeleted'] as bool? ?? false,
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
  );

  static CustomerModel fromCustomer(Customer c) {
    return CustomerModel(
      id: c.id,
      name: c.name,
      phone: c.phone,
      email: c.email,
      address: c.address,
      city: c.city,
      state: c.state,
      pincode: c.pincode,
      tinNumber: c.gstNumber,
      notes: c.notes,
      status: c.status,
      isDeleted: c.isDeleted,
      createdAt: c.createdAt,
      updatedAt: c.updatedAt,
    );
  }
}
