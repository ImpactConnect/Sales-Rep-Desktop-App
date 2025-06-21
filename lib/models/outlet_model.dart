class Outlet {
  final String id;
  final String name;
  final String? address;
  final DateTime? createdAt;

  Outlet({
    required this.id,
    required this.name,
    this.address,
    this.createdAt,
  });

  factory Outlet.fromMap(Map<String, dynamic> map) {
    return Outlet(
      id: map['id'] as String,
      name: map['name'] as String,
      address: map['address'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      if (address != null) 'address': address,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
