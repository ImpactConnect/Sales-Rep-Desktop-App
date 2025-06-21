# 📦 Stock Page — Development Prompt (Sales Rep App)

## 🎯 Objective
Develop the **Stock Page** for the Sales Representative App to display a list of available products in a visually intuitive, responsive, and informative layout. The page should allow **read-only access** to stock data (Sales reps cannot edit or delete stock). The page will pull stock from the local SQLite DB (synced from Supabase by the Admin app).

---

## 🔐 User Role
**Sales Representative**

- ✅ View list of available stock at their outlet
- ❌ Cannot edit, delete, or add stock
- ✅ Can view product detail
- ✅ Can filter/search stock
- ✅ Can see sync status and last update info

---

## 🖼️ UI Layout

### Top Section:
- **AppBar Title:** `Available Stock`
- **AppBar Right Icon:** Optional settings or sync icon
- **Search Bar:** Positioned below AppBar with placeholder “Search products…”

### Stock List Section:
- Display each stock item in a **Card layout** with:
  - **Product Name** (Bold)
  - **Quantity** with unit (e.g. `320.0 Paint`, `400 Kg`)
  - **Cost per Unit** (Formatted with currency)
  - **Date Added**
  - **Optional Thumbnail** if available
  - **Info Icon** → opens stock details modal/pop-up
  - **Sync Status Badge** (if not synced to server)

> Example:

Garri Lebu
Quantity: 320.0 Paint
Cost per Unit: ₦1,500.00
Added: June 20, 2025
Last Updated: June 22, 2025


---

## 🔍 Search & Filter Feature

- **Search:** Realtime text-based search by product name
- **Filter Drawer/Modal:**
  - Filter by Unit (Kg, Paint, Piece, etc.)
  - Filter by Quantity range
  - Filter by Date Added (Today, Last 7 Days, Last 30 Days)
  - Filter by Sync Status (Synced / Not Synced)

---

## 📊 Optional Top Metrics Bar

Display metrics at the top in small cards or tiles:
- Total Product Count
- Total Stock Quantity
- Total Stock Value
- Low Stock Count (quantity < threshold)
- Out of Stock Items (quantity = 0)

---

## 🛠 Functionality Requirements

### ✅ Stock Data Handling
- Fetch stock records from local SQLite database
- Each stock item should include:
  - `id`
  - `product_name`
  - `quantity`
  - `unit`
  - `cost_per_unit`
  - `description`
  - `date_added`
  - `last_updated`
  - `sync_status`
  - `outlet_id`

### 📦 Info Modal (on ℹ️ click)
- Show full stock details in modal or bottom sheet
- Display:
  - Product Name
  - Unit
  - Description
  - Quantity
  - Cost per Unit
  - Date Added
  - Sync Status
  - Outlet name (if available)

---

## 🧠 Logic Rules

- Stock is **read-only** for sales reps
- If quantity = 0, mark card with red badge or dimmed
- If not yet synced to server, display “⏳ Not Synced” badge
- Sort default: latest added products at the top

---

## 🎨 Design Considerations

- Follow **modern Material Design 3**
- Use **cards** with elevation and rounded corners
- Color cues for statuses:
  - 🔴 Red: Out of Stock
  - 🟠 Orange: Low Stock
  - 🟢 Green: Well Stocked
  - 🔵 Blue: Recently Synced
- Responsive layout that scales well for all screen sizes

---

## 🧾 Deliverables

- [ ] Flutter Stock Page UI implemented
- [ ] List view of available stocks rendered from local SQLite
- [ ] Info button with modal popup for stock details
- [ ] Search functionality
- [ ] Filter system implemented
- [ ] Sync status indicator per item
- [ ] Error-handling for empty state and DB errors
- [ ] Basic top-level stock metrics (if enabled)

---

## Other featurs 

- Integrate low stock alert notification system
- Add export stock report option (CSV, PDF)
