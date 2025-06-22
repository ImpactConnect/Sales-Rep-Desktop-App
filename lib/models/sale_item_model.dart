import 'package:uuid/uuid.dart';

class SaleItem {
  final String id;
  final String saleId;
  final String productId;
  final String? productName;
  final double quantity;
  final double unitPrice;
  final double total; // Calculated field (quantity * unitPrice)
  final DateTime createdAt;

  SaleItem({
    String? id,
    required this.saleId,
    required this.productId,
    this.productName,
    required this.quantity,
    required this.unitPrice,
    DateTime? createdAt,
  })  : this.id = id ?? const Uuid().v4(),
        this.total = quantity * unitPrice,
        this.createdAt = createdAt ?? DateTime.now();

  factory SaleItem.fromMap(Map<String, dynamic> map) => SaleItem(
        id: map['id'],
        saleId: map['sale_id'],
        productId: map['product_id'],
        productName: map['product_name'],
        quantity: (map['quantity'] as num).toDouble(),
        unitPrice: (map['unit_price'] as num).toDouble(),
        createdAt: DateTime.parse(map['created_at']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'sale_id': saleId,
        'product_id': productId,
        'product_name': productName,
        'quantity': quantity,
        'unit_price': unitPrice,
        'created_at': createdAt.toIso8601String(),
      };

  SaleItem copyWith({
    String? id,
    String? saleId,
    String? productId,
    String? productName,
    double? quantity,
    double? unitPrice,
    DateTime? createdAt,
  }) =>
      SaleItem(
        id: id ?? this.id,
        saleId: saleId ?? this.saleId,
        productId: productId ?? this.productId,
        productName: productName ?? this.productName,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
        createdAt: createdAt ?? this.createdAt,
      );
}
