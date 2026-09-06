import 'package:sahibz_inventory/database/database.dart';

class CategoryModel {
  final String id;
  final String name;
  final String? description;
  final String? image;
  final String? parentId;
  final String? parentName;
  final String status;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.image,
    this.parentId,
    this.parentName,
    this.status = 'active',
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  CategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    String? image,
    String? parentId,
    String? parentName,
    String? status,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      image: image ?? this.image,
      parentId: parentId ?? this.parentId,
      parentName: parentName ?? this.parentName,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'image': image,
    'parentId': parentId,
    'parentName': parentName,
    'status': status,
    'isDeleted': isDeleted,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    image: json['image'] as String?,
    parentId: json['parentId'] as String?,
    parentName: json['parentName'] as String?,
    status: json['status'] as String? ?? 'active',
    isDeleted: json['isDeleted'] as bool? ?? false,
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
  );

  bool get isRoot => parentId == null || parentId!.isEmpty;

  static CategoryModel fromCategory(Category c, {String? parentName}) {
    return CategoryModel(
      id: c.id,
      name: c.name,
      description: c.description,
      image: c.image,
      parentId: c.parentId,
      parentName: parentName,
      status: c.status,
      isDeleted: c.isDeleted,
      createdAt: c.createdAt,
      updatedAt: c.updatedAt,
    );
  }
}
