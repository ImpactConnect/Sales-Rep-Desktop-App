# 🔄 SALES REP APP — PHASE 4 UPDATE: MULTI-ITEM SALES & CUSTOMER SUPPORT

## 🎯 Objective

Enhance the sales recording system to support:
- Multiple items per transaction (i.e., grouped sale)
- Optional customer details per sale
- Sale breakdown per item
- VAT per sale
- Enhanced UI and database structure

---

## 📦 Database Updates (Supabase SQL Compatible)

### 1. `customers` Table

```sql
create table customers (
  id uuid primary key default gen_random_uuid(),
  full_name text,
  phone text,
  created_at timestamp default now()
);

- Enables tracking of customer data for each sale
- Fields are optional but useful for future CRM/receipt features

2. sales Table (Updated)
sql
create table sales (
  id uuid primary key default gen_random_uuid(),
  outlet_id uuid references outlets(id) on delete cascade,
  rep_id uuid references profiles(id) on delete set null,
  customer_id uuid references customers(id) on delete set null,
  vat numeric default 0.0,
  total_amount numeric not null,
  created_at timestamp default now()
);

- Group-level transaction
- Holds VAT and overall total for a sale

3. sale_items Table (NEW)
sql

create table sale_items (
  id uuid primary key default gen_random_uuid(),
  sale_id uuid references sales(id) on delete cascade,
  product_id uuid references products(id) on delete restrict,
  quantity numeric not null,
  unit_price numeric not null,
  total numeric generated always as (quantity * unit_price) stored,
  created_at timestamp default now()
);

- Line items linked to each sale
- Automatically calculates line item total


## 🖥️ UI/UX Flow: Add New Sale Page
🧾 Features
- Input: Customer name (optional) → checks if customer exists or adds new
- Auto-filled VAT (admin-defined default)
- Add multiple sale item entries:
    - Select product from dropdown
    - Autofill unit price
    - Input quantity
    - “Add Another Item” repeats the item row
    - Total auto-calculated from items + VAT

On submit:
    - Create customer if needed
    - Create sale header in sales
    - Create each item in sale_items
    - Save to local DB for offline support

## 📄 UI/UX: Sales History Page
✅ Updated View
- Sale grouped by transaction ID
- Each entry displays:
    - Date
    - Customer name (if available)
    - Total amount
    - Number of items
    - VAT

“View Details” expands or shows popup:
    - Lists all sale_items with:
    - Product name
    - Quantity
    - Unit Price
    - Line total

Add filter options:
- By date range
- By customer name
- By product (within nested items)
- By outlet rep

## 🧱 Local Database Adjustments (SQLite)
Update local SQLite DB with the new structure:
    - customers
    - sales
    - sale_items

Adjust sync logic to:
- Upload a sale + all items in one batch
- Mark as synced locally

## 🔧 New or Modified Flutter Models
- CustomerModel
- SaleModel (transaction level)
- SaleItemModel (item level)

Update services:
- SalesService to handle:
- Group sale logic
- Local+remote creation
- Sale + Items sync strategy

## 📤 Receipt Support
- With grouped transactions, we can now:
- Print/download a receipt per sale
- Include customer, date, item list, VAT, total


## ✅ Deliverables for This Phase
 - Updated Supabase SQL schema applied
-  Local DB schema updated
-  New Add New Sale UI with multiple item inputs
-  Enhanced Sales History with grouped view and breakdown
-  Updated sync logic for sale and related items
-  Optional: Print-friendly or PDF receipt preview

