
# 🧾 SALES HISTORY PAGE – ENHANCED UI/UX DEVELOPMENT PROMPT

## 🎯 Objective
Implement a **modern, responsive and informative** sales history page that displays itemized transaction records, computes sales metrics, and allows quick filtering, printing and review. This page enhances usability, provides visibility into past sales and supports printing customer receipts.

---

## 📐 DESIGN PRINCIPLES

### 🖌️ UI Style Guide

- **Background**: `#FAF9FC` (soft off-white)
- **Primary Color**: `#4A90E2` (sky blue)
- **Accent Color**: `#F5A623` (orange for sync status)
- **Text Color**: `#333333`
- **Card Background**: `#FFFFFF` (pure white)
- **Border Radius**: `8.0`
- **Elevation**: `3.0`

Use **Google Fonts (Inter or Roboto)** for a modern, clean look.

---

## 📊 METRICS DASHBOARD (TOP)

| Metric              | Icon            | Description                      |
|---------------------|------------------|----------------------------------|
| **Total Items Sold**  | 📦 inventory  | Sum of all product quantities     |
| **Sales Count**     | 🧾 receipt_long| Total sale transactions           |
| **Total Customers** | 👥 people      | Unique customers during period    |
| **Total Revenue**   | 💰 money       | Total value of all sales (₦)      |

- **Layout**: Row of `Card` widgets
- **Responsive**: Stacked or scrollable on smaller screens

---

## 📂 SALES RECORD SECTION

### 📌 Fixed Header Row

Display once at the top of scrollable content:

```
Date | Customer | Items | Unit Cost | Quantity | Total
```

### 🧾 List Cards

Each sale is a card (`Card` widget) containing:

- **Date & Time** (top-left)
- **Customer Name** (optional, fallback to blank)
- **List of Products** in that sale, example:
  ```
  Titus Fish – ₦700.00 x 2 = ₦1,400.00
  Garri Lebu – ₦500.00 x 3 = ₦1,500.00
  ```
- **Total (bold)** below items
- **Sync Status** badge (top-right)
- **Print Button** icon (`Icons.print`) at bottom or corner

### 🖱️ Scrollable

All cards are scrollable under the fixed header.

---

## 👆 TAP TO VIEW MODAL

On tapping a card:

- Open a modal popup showing:
  - Sale time and ID
  - Full customer name (optional)
  - Item list
  - Quantity, unit price, total
  - VAT
  - Total sale value
  - Rep name (if available)
- **Print Button** for receipt

---

## 🔍 FILTERING SECTION

Place above metrics or in expandable card:

- **Date Range Selector** (`DropdownButton` and date picker)
- **Product Filter Dropdown**
- **Rep Search (optional)**

Include a **Clear Filters** button.

---

## 💱 NAIRA FORMATTING

Use:

```dart
NumberFormat.currency(locale: 'en_NG', symbol: '₦')
```

For all currency displays.

---
Add option Export file as PDF/CSV file.
---

## 🖼️ SYNC BADGES

| Status        | Label       | Color     |
|---------------|-------------|-----------|
| Not Synced    | `Not Synced`| Orange    |
| Synced        | `Synced`    | Green     |
| Draft         | `Draft`     | Grey      |

Use `Chip` or `Container` with padding, borderRadius.

---

## 🔮 OPTIONAL FEATURES (LATER STAGE)

| Feature                  | Description                             |
|--------------------------|-----------------------------------------|
                        |
| Sales Target Display     | % to goal for rep                       |
| Group by Customer Toggle | View customer-wise sales breakdown      |
| Pagination               | For large record sets                   |
| Customer Profile Page    | If customer name is used frequently     |

---

## 📦 DELIVERABLES

- Modern responsive Sales Page UI
- Fixed headers with scrollable records
- Accurate metrics display
- Itemized card layout per sale
- Print modal popup
- Filters and formatting
- Naira currency and clean typography

---

**Start with UI widget structure and dummy data. Once confirmed, link with SQLite local data and Supabase sync.**
