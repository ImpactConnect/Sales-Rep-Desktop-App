
# 📦 PHASE 3: STOCK VIEWING IMPLEMENTATION

In this phase, we implement functionality for Sales Reps to view all stocks added to their assigned outlet by the admin. This includes syncing data from Supabase, caching locally using SQLite, and rendering the UI in a structured, informative layout.

---

## 🎯 Objectives

- Fetch stock data from Supabase based on the sales rep’s outlet.
- Store data locally using SQLite for offline access.
- Display all stock entries including:
  - Product name
  - Quantity
  - Measurement unit (e.g., kg, pieces)
  - Date added
  - Cost per unit
- Include manual and auto sync buttons.
- Add export feature (CSV/PDF - optional for Phase 4).

---

## 🧱 Folder Structure Additions

```
lib/
├── core/
│   ├── database/
│   │   └── local_db_service.dart      # Handles SQLite setup and queries
│   └── services/
│       └── stock_service.dart         # Supabase fetching logic
├── models/
│   └── stock_model.dart               # Model for stock item
├── screens/
│   └── stock/
│       ├── stock_list_screen.dart     # Main UI
│       └── stock_item_card.dart       # Widget for displaying a single stock item
```

---

## 📁 Data Model: stock_model.dart

```dart
class StockItem {
  final String id;
  final String productName;
  final double quantity;
  final String unit;
  final double costPerUnit;
  final DateTime dateAdded;

  StockItem({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.costPerUnit,
    required this.dateAdded,
  });

  factory StockItem.fromMap(Map<String, dynamic> map) => StockItem(
    id: map['id'],
    productName: map['product_name'],
    quantity: map['quantity'],
    unit: map['unit'],
    costPerUnit: map['cost_per_unit'],
    dateAdded: DateTime.parse(map['date_added']),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'product_name': productName,
    'quantity': quantity,
    'unit': unit,
    'cost_per_unit': costPerUnit,
    'date_added': dateAdded.toIso8601String(),
  };
}
```

---

## 🔌 Supabase Logic: stock_service.dart

```dart
Future<List<StockItem>> fetchStockForOutlet(String outletId) async {
  final response = await Supabase.instance.client
    .from('stock')
    .select()
    .eq('outlet_id', outletId);

  return (response as List)
    .map((item) => StockItem.fromMap(item))
    .toList();
}
```

---

## 💾 Local Cache: local_db_service.dart

- Create SQLite database with `stock` table.
- Store and retrieve stock items.
- Sync from Supabase when online and update the local DB.

---

## 🖼️ UI: stock_list_screen.dart

- List all stocks using `ListView.builder`.
- Each item uses a `StockItemCard` to show:
  - Product name
  - Quantity + Unit
  - Cost per unit
  - Date added

---

## ✅ Deliverables

- [x] SQLite setup to cache stock data
- [x] Supabase fetch logic for `stock` table
- [x] Integration with sales rep outlet ID
- [x] Local and cloud sync logic
- [x] Stock list UI and display layout
- [x] Manual sync trigger from UI
- [x] Fallback to offline data when not connected

---

Next up: **Phase 4 - Sales Entry and Record Listing**
