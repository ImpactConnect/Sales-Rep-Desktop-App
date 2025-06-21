class StockItem {
  final String id;
  final String productName;
  final double quantity;
  final String unit;
  final double costPerUnit;
  final DateTime dateAdded;
  final DateTime? lastUpdated;
  final String? description;
  final String outletId;
  final bool synced;
  final String? syncError;

  StockItem({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.costPerUnit,
    required this.dateAdded,
    this.lastUpdated,
    this.description,
    required this.outletId,
    this.synced = true,
    this.syncError,
  });

  factory StockItem.fromMap(Map<String, dynamic> map) => StockItem(
        id: map['id'] as String,
        productName: map['product_name'] as String,
        quantity: (map['quantity'] as num).toDouble(),
        unit: map['unit'] as String,
        costPerUnit: (map['cost_per_unit'] as num).toDouble(),
        dateAdded: DateTime.parse(map['date_added'] as String),
        lastUpdated: map['last_updated'] != null
            ? DateTime.parse(map['last_updated'] as String)
            : null,
        description: map['description'] as String?,
        outletId: map['outlet_id'] as String,
        synced: map['synced'] as bool? ?? true,
        syncError: map['sync_error'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'product_name': productName,
        'quantity': quantity,
        'unit': unit,
        'cost_per_unit': costPerUnit,
        'date_added': dateAdded.toIso8601String(),
        'last_updated': lastUpdated?.toIso8601String(),
        'description': description,
        'outlet_id': outletId,
        'synced': synced,
        'sync_error': syncError,
      };

  StockItem copyWith({
    String? id,
    String? productName,
    double? quantity,
    String? unit,
    double? costPerUnit,
    DateTime? dateAdded,
    DateTime? lastUpdated,
    String? description,
    String? outletId,
    bool? synced,
    String? syncError,
  }) {
    return StockItem(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      dateAdded: dateAdded ?? this.dateAdded,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      description: description ?? this.description,
      outletId: outletId ?? this.outletId,
      synced: synced ?? this.synced,
      syncError: syncError ?? this.syncError,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StockItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
