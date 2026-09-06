class AuditLogModel {
  final String id;
  final String? userId;
  final String? userName;
  final String action;
  final String entityType;
  final String? entityId;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final String? ipAddress;
  final String? userAgent;
  final String? details;
  final DateTime? performedAt;

  const AuditLogModel({
    required this.id,
    this.userId,
    this.userName,
    required this.action,
    required this.entityType,
    this.entityId,
    this.oldValues,
    this.newValues,
    this.ipAddress,
    this.userAgent,
    this.details,
    this.performedAt,
  });

  bool get isCreate => action == 'create';
  bool get isUpdate => action == 'update';
  bool get isDelete => action == 'delete';
  bool get isLogin => action == 'login';
  bool get isExport => action == 'export';

  AuditLogModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? action,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    String? ipAddress,
    String? userAgent,
    String? details,
    DateTime? performedAt,
  }) {
    return AuditLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      action: action ?? this.action,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      oldValues: oldValues ?? this.oldValues,
      newValues: newValues ?? this.newValues,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      details: details ?? this.details,
      performedAt: performedAt ?? this.performedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'userName': userName,
    'action': action,
    'entityType': entityType,
    'entityId': entityId,
    'oldValues': oldValues,
    'newValues': newValues,
    'ipAddress': ipAddress,
    'userAgent': userAgent,
    'details': details,
    'performedAt': performedAt?.toIso8601String(),
  };

  factory AuditLogModel.fromJson(Map<String, dynamic> json) => AuditLogModel(
    id: json['id'] as String,
    userId: json['userId'] as String?,
    userName: json['userName'] as String?,
    action: json['action'] as String,
    entityType: json['entityType'] as String,
    entityId: json['entityId'] as String?,
    oldValues: json['oldValues'] != null ? Map<String, dynamic>.from(json['oldValues'] as Map) : null,
    newValues: json['newValues'] != null ? Map<String, dynamic>.from(json['newValues'] as Map) : null,
    ipAddress: json['ipAddress'] as String?,
    userAgent: json['userAgent'] as String?,
    details: json['details'] as String?,
    performedAt: json['performedAt'] != null ? DateTime.parse(json['performedAt'] as String) : null,
  );
}
