import 'package:uuid/uuid.dart';
import 'sale_item_model.dart';

class Sale {
  final String id;
  final String outletId;
  final String repId;
  final String? customerId;
  final String? customerName;
  final double vat;
  final double totalAmount;
  final DateTime createdAt;
  DateTime get date => createdAt;
  final bool synced;
  final List<SaleItem> items;

  int get totalQuantity =>
      items.fold<int>(0, (sum, item) => sum + item.quantity.round());

  double get vatAmount => totalAmount * (vat / 100);

  Sale({
    String? id,
    required this.outletId,
    required this.repId,
    this.customerId,
    this.customerName,
    required this.vat,
    required this.totalAmount,
    DateTime? createdAt,
    this.synced = false,
    List<SaleItem>? items,
  })  : this.id = id ?? const Uuid().v4(),
        this.createdAt = createdAt ?? DateTime.now(),
        this.items = items ?? [];

  factory Sale.fromMap(Map<String, dynamic> map) => Sale(
        id: map['id'],
        outletId: map['outlet_id'],
        repId: map['rep_id'],
        customerId: map['customer_id'],
        customerName: map['customer_name'],
        vat: (map['vat'] as num).toDouble(),
        totalAmount: (map['total_amount'] as num).toDouble(),
        createdAt: DateTime.parse(map['created_at']),
        synced: map['synced'] == 1,
        items: (map['items'] as List?)
                ?.map((item) => item is SaleItem
                    ? item
                    : SaleItem.fromMap(item as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'outlet_id': outletId,
        'rep_id': repId,
        'customer_id': customerId,
        'customer_name': customerName,
        'vat': vat,
        'total_amount': totalAmount,
        'created_at': createdAt.toIso8601String(),
        'synced': synced ? 1 : 0,
        'items': items.map((item) => item.toMap()).toList(),
      };

  Sale copyWith({
    String? id,
    String? outletId,
    String? repId,
    String? customerId,
    String? customerName,
    double? vat,
    double? totalAmount,
    DateTime? createdAt,
    bool? synced,
    List<SaleItem>? items,
  }) =>
      Sale(
        id: id ?? this.id,
        outletId: outletId ?? this.outletId,
        repId: repId ?? this.repId,
        customerId: customerId ?? this.customerId,
        customerName: customerName ?? this.customerName,
        vat: vat ?? this.vat,
        totalAmount: totalAmount ?? this.totalAmount,
        createdAt: createdAt ?? this.createdAt,
        synced: synced ?? this.synced,
        items: items ?? this.items,
      );
}
