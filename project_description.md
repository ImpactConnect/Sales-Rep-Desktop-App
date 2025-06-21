# 🧾 SALES REP APP — PROJECT SPECIFICATION (Updated)

## 📌 Objective

Build a **Sales Representative Desktop App** for managing outlet-level sales, tracking inventory, and syncing with a central admin system.

Built using **Flutter** with **Supabase** as the backend and cloud sync layer.

---

## 🔐 AUTHENTICATION & USER MANAGEMENT

* Reps log in using **email/password** via Supabase Auth
* Each user is linked to an **outlet** through the `profiles` table
* Roles: only **rep** role supported in this app

### 🔁 Updated User Access Logic:

* 🔁 An **outlet can have multiple sales reps** (e.g., morning/evening shifts)
* 🔁 Each **sales rep logs in with their own credentials**
* 🔁 All sales records belong to the same **linked outlet**
* 🔁 Each **sales record includes both**:

  * `rep_id` (who made the sale)
  * `outlet_id` (which outlet the sale was made from)

---

## 🏬 OUTLET-LEVEL MANAGEMENT

Each rep is linked to one outlet, and all activities are scoped to that outlet.

* View stock levels (received from admin)
* Confirm stock receipt
* Create sales entries
* Track daily sales made
* Offline-first support with local database (SQLite)
* Cloud sync support to Supabase when online
* Notifies rep when there are unsynced data

---

## 📦 STOCK VIEWING

* Shows all stock items available in the outlet
* Each stock item includes:

  * Name
  * Unit type (kg, pack, piece, etc.)
  * Cost price
  * Selling price
  * Quantity available
* Cannot edit stock — only view (admin-controlled)
* Can view low stock alert based on Quota set by the admin

---

## 💸 SALES MANAGEMENT

* Add new sales record
* Auto-fill product details on selection
* Select quantity sold, auto-calculate total price
* All sales tagged with:

  * `rep_id` (logged in user)
  * `outlet_id` (rep's outlet)
  * `created_at` timestamp

### Sales Table Fields:

* `id` (UUID)
* `product_id`
* `outlet_id`
* `rep_id`
* `quantity`
* `total_price`
* `created_at`

---

## 📊 REPORTS & DASHBOARD

* Daily/weekly/monthly sales summary
* Top sold products
* Revenue by product
* Total quantity sold

---

## 📥 OFFLINE-FIRST SYNC

* Uses local SQLite for offline access
* Supabase sync engine checks for connectivity
* Prompts user to sync pending sales when online

---

## 🧪 TEST DATA SETUP

* Seeded outlets, products, reps, and sales
* Supabase tables:

  * `auth.users`
  * `profiles`
  * `outlets`
  * `products`
  * `sales`

---

## 🧠 FUTURE EXTENSIONS

* Add daily sales closure/summary report
* Sales cancellation with reason tracking
* Rep shift reporting (start/end)

---

## 🛠️ STACK & TOOLS

* **Flutter (Desktop)**
* **Supabase** (Auth + Postgres + Storage)
* **SQLite** (Offline-first local storage)

---

## 📂 PROJECT STRUCTURE (SUGGESTED)

```
lib/
├── main.dart
├── core/
│   └── services/, database/, constants/
├── models/
├── screens/
│   └── login/, dashboard/, sales/, stock/
├── widgets/
└── utils/
```

---

## 🔄 CURRENT FLOW

1. Rep logs in (email/password)
2. App fetches profile + outlet info
3. Displays dashboard (daily stats, sync state)
4. Can view stock, make sales
5. Works offline
6. Prompts sync when online

---
