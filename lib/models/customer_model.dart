import 'package:uuid/uuid.dart';

class Customer {
  final String id;
  final String? fullName;
  final String? phone;
  final DateTime createdAt;

  Customer({
    String? id,
    this.fullName,
    this.phone,
    DateTime? createdAt,
  })  : this.id = id ?? const Uuid().v4(),
        this.createdAt = createdAt ?? DateTime.now();

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
        id: map['id'],
        fullName: map['full_name'],
        phone: map['phone'],
        createdAt: DateTime.parse(map['created_at']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'full_name': fullName,
        'phone': phone,
        'created_at': createdAt.toIso8601String(),
      };

  Customer copyWith({
    String? id,
    String? fullName,
    String? phone,
    DateTime? createdAt,
  }) =>
      Customer(
        id: id ?? this.id,
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        createdAt: createdAt ?? this.createdAt,
      );
}
