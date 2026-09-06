import 'package:sahibz_inventory/database/database.dart';

class SupplierModel {
  final String id;
  final String companyName;
  final String? contactPerson;
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

  const SupplierModel({
    required this.id,
    required this.companyName,
    this.contactPerson,
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

  SupplierModel copyWith({
    String? id,
    String? companyName,
    String? contactPerson,
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
    return SupplierModel(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      contactPerson: contactPerson ?? this.contactPerson,
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
    'companyName': companyName,
    'contactPerson': contactPerson,
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

  factory SupplierModel.fromJson(Map<String, dynamic> json) => SupplierModel(
    id: json['id'] as String,
    companyName: json['companyName'] as String,
    contactPerson: json['contactPerson'] as String?,
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

  static SupplierModel fromSupplier(Supplier s) {
    return SupplierModel(
      id: s.id,
      companyName: s.companyName,
      contactPerson: s.contactPerson,
      phone: s.phone,
      email: s.email,
      address: s.address,
      city: s.city,
      state: s.state,
      pincode: s.pincode,
      tinNumber: s.gstNumber,
      notes: s.notes,
      status: s.status,
      isDeleted: s.isDeleted,
      createdAt: s.createdAt,
      updatedAt: s.updatedAt,
    );
  }
}
