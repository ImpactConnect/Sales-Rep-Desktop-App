# 🧾 PHASE 4: SALES ENTRY & RECORD LISTING (Updated with VAT)

This phase enables the sales rep to:
- Add new sales records for each product sold
- View past sales for their outlet
- Store sales locally (SQLite) and remotely (Supabase)
- Include **VAT support**
- Provide **advanced filtering and metrics** on the sales page
- Ensure an **offline-first workflow** with Supabase sync

---

## 🎯 Objectives

- Enable accurate sales data entry including **VAT**
- Allow review of sales history with **filters** and **sales/revenue metrics**
- Store sales per rep and outlet
- Push sales to Supabase when connected
- Maintain local cache using SQLite

---

## 🧱 Folder Structure Additions

lib/
├── models/
│ └── sale_model.dart # Model for a sale entry
├── core/
│ ├── services/
│ │ └── sales_service.dart # Supabase sync logic
│ └── database/
│ └── sales_db_service.dart # Local SQLite sales cache
├── screens/
│ └── sales/
│ ├── sales_form_popup.dart # Popup for adding new sale
│ └── sales_list_screen.dart # List of past sales
├── widgets/
│ └── sales_card.dart # Reusable sale entry display widget


---

## 📁 Updated Sale Model: `sale_model.dart`

```dart
class Sale {
  final String id;
  final String productId;
  final String repId;
  final String outletId;
  final double quantity;
  final double unitCost;
  final double vat; // NEW: VAT for this sale
  final double totalCost;
  final DateTime date;

  Sale({
    required this.id,
    required this.productId,
    required this.repId,
    required this.outletId,
    required this.quantity,
    required this.unitCost,
    required this.vat,
    required this.totalCost,
    required this.date,
  });

  factory Sale.fromMap(Map<String, dynamic> map) => Sale(
    id: map['id'],
    productId: map['product_id'],
    repId: map['rep_id'],
    outletId: map['outlet_id'],
    quantity: (map['quantity'] as num).toDouble(),
    unitCost: (map['unit_cost'] as num).toDouble(),
    vat: (map['vat'] ?? 0.0) as double,
    totalCost: (map['total_cost'] as num).toDouble(),
    date: DateTime.parse(map['date']),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'product_id': productId,
    'rep_id': repId,
    'outlet_id': outletId,
    'quantity': quantity,
    'unit_cost': unitCost,
    'vat': vat,
    'total_cost': totalCost,
    'date': date.toIso8601String(),
  };
}

## Sales Entry UI: sales_form_popup.dart
- 🔽 Dropdown: Product selection
- 💰 Auto-fill: Unit cost from product
- 🔢 Input: Quantity
- 📦 VAT: Auto-fill from product/default
- ➕ Auto-calculate total

## Submit: Store in SQLite with all metadata
- 🎉 Toast: Confirm success, clear form
- 📜 Sales History Screen: sales_list_screen.dart
- Shows:
    - Product name
    - Quantity sold
    - Total cost (with VAT)
    - Time of sale
    - Sales Rep name
    - Date
- 📊 Metrics:
    - Total sales today
    - Total last 7 days
    - Total last 30 days
    - Total revenue (after VAT)

- 🔍 Filters:
    - Date range
    - Product name
    - Last 7 / 30 days
    - Sales rep (same outlet)

- ➕ Floating Action Button: "Add Sale" (opens sales_form_popup.dart)

## 💾 SQLite Local Logic: sales_db_service.dart
- Creates sales table with columns:
- id, product_id, rep_id, outlet_id
- quantity, unit_cost, vat, total_cost
- date
- Insert & fetch entries
- Sync flag for Supabase

## 📡 Supabase Sync Logic: sales_service.dart
- Uploads local unsynced sales
- Updates sync status after upload
- Allows admin to see VAT-inclusive values

## 🛢️ Supabase sales Table Structure (Updated)

CREATE TABLE sales (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID REFERENCES products(id),
  rep_id UUID REFERENCES reps(id),
  outlet_id UUID REFERENCES outlets(id),
  quantity NUMERIC NOT NULL,
  unit_cost NUMERIC NOT NULL,
  vat NUMERIC DEFAULT 0.0,
  total_cost NUMERIC NOT NULL,
  date TIMESTAMP DEFAULT NOW(),
  synced BOOLEAN DEFAULT FALSE
);

## ✅ Deliverables
 - Sale model updated with vat
-  SQLite sales table with vat
-  UI for new sales entry with VAT auto-fill
- Sales history page with filters
- Total and revenue metrics summary
- Supabase sync logic for VAT-inclusive records