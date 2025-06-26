# 📦 Phase 5: Sync Engine Development Prompt

## 🚀 Goal
Develop a robust **Sync Engine** that syncs sales data from the local SQLite database (`sales_rep.db`) to the remote Supabase sales table.

## 🎯 Objective
- ✅ Ensure that offline sales records are reliably pushed to the Supabase backend.
- ✅ Update local records to reflect sync status.
- ✅ Handle retries, errors, and conflicts gracefully.

---

## 🏗️ Database Structure

### 🔸 Local SQLite (`sales_rep.db`)


### 🔸 Supabase Table (`sales`)
- Mirrors local table structure with server-side `sale_id` as UUID.

---

## 🔧 Development Steps

### 1. ✅ **Design Sync Model**
- Create a `SyncService` class responsible for:
  - Fetching unsynced records (`synced = 0`) from SQLite.
  - Pushing to Supabase sales table.
  - Updating local record with:
    - `synced = 1`
    - `sale_id` assigned from Supabase.

---

### 2. ✅ **Build the Sync Function**

```dart

## 3. ✅ Update Local Database After Sync
Update synced to 1.
Save the sale_id returned from Supabase.

##4. ✅ UI Integration
Add Sync Button to the Sales page (or auto-sync on app open/close).

Show sync status:
✔️ Successful sync count.
🔄 Pending sync count.
❌ Failed sync alerts.

##5. ✅ Error Handling
Handle scenarios like:

🔌 No internet connection.
🔑 Supabase auth error.
⛔ Data conflicts.
Implement retry logic or mark as "sync failed."

## 6. ✅ Optional Enhancements
Background sync on app startup or every X minutes.
Manual sync trigger with feedback animation (spinner, progress bar).
Sync logs/history page.

## 📡 API Integration Notes
Use Supabase from('sales').insert() for adding data.
Use select().single() to retrieve server sale_id.
Ensure Supabase auth is correctly initialized before syncing.

