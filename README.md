# FirmLedger: Small Business Accounting, Expense & Debt Manager

<p align="center">
  <img src="assets/images/app_logo.jpg" alt="FirmLedger Logo" width="130" style="border-radius: 24px; box-shadow: 0 8px 24px rgba(0,0,0,0.15);"/>
</p>

<p align="center">
  <b>The Ultimate Open-Source Small Business Accounting, Firm Ledger, Cash Flow Tracker & Debt Payoff Management App built with Flutter, Riverpod, SQLite, and FL Chart.</b>
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.47.2-02569B?style=for-the-badge&logo=flutter" alt="Flutter"/></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart" alt="Dart"/></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge" alt="License"/></a>
  <a href="https://android.com"><img src="https://img.shields.io/badge/Platform-Android%20%7C%20Linux-brightgreen?style=for-the-badge" alt="Platforms"/></a>
</p>

---

## 📌 Executive Summary

**FirmLedger** is a high-performance, cross-platform financial accounting and general ledger application designed for small business owners, freelancers, traders, and personal finance management. It combines real-time cash flow analytics, double-entry-style credit transaction logging, customer/supplier balances, and a mathematical **Debt Payoff Strategy Engine (Snowball vs. Avalanche)**.

Whether managing daily sales, tracking customer credit accounts (Receivables), logging vendor payables, or exporting CSV financial statements, **FirmLedger** delivers a seamless offline-first experience with zero subscription fees.

---

## 🔍 Key SEO & Search Topics

`flutter-app` • `accounting-software` • `ledger-book` • `expense-tracker` • `debt-manager` • `cash-flow` • `khatabook-clone` • `vyapar-alternative` • `riverpod` • `sqlite-database` • `snowball-avalanche` • `financial-dashboard`

---

## 📋 Table of Contents

- [📌 Executive Summary](#-executive-summary)
- [🌟 Key Features](#-key-features)
- [📊 Financial Dashboard & 2x2 Grid](#-1-financial-dashboard--2x2-grid)
- [📝 Income & Expense Entry Form](#-2-income--expense-entry-form)
- [🧮 Debt Payoff Engine](#-3-debt-payoff-engine-snowball-vs-avalanche)
- [📥 CSV Exporter & Analytics](#-4-csv-exporter--analytics)
- [📁 Project Architecture](#-project-architecture)
- [⚡ Getting Started](#-getting-started)
- [❓ Frequently Asked Questions (FAQ)](#-frequently-asked-questions-faq)
- [📄 License & Author](#-license--author)

---

## 🌟 Key Features

### 📊 1. Financial Dashboard & 2x2 Grid
- **Firm Profile Banner**: Displays business name, PAN/VAT/GST tax registration ID, address, and currency symbol (`Rs.`, `$`, `€`, `£`).
- **2x2 General Ledger Grid**:
  - 🟢 **Income (Revenue)**: Tracks total revenue with breakdown drilldown modals.
  - 🔴 **Expense (Outflows)**: Monitors operational expenditures, stock purchases, and utilities.
  - 🟦 **Receivables (Money to Collect)**: Tracks customer credit sales and debtor balances.
  - 🔴 **Payables (Money Due)**: Manages supplier credit purchases and vendor liabilities.
- **Dynamic Date Range Filter**: Interactive date range selector (`YYYY-MM-DD` to `YYYY-MM-DD`) filtering all dashboard analytics.

### 📝 2. Income & Expense Entry Form
- **Income $\leftrightarrow$ Expense Segment Switcher**: Fast single-screen form toggling.
- **Categorized Inputs**: Goods/Product Sales, Service Revenue, Stock Purchases, Utilities, and Operating Expenses.
- **Automatic Credit Sync**: Selecting `Payment Method: Credit / On Account` automatically generates a **Receivable (Owed to Me)** or **Payable (Owed by Me)** debt entry in the ledger.

### 🧮 3. Debt Payoff Engine (Snowball vs. Avalanche)
- **Snowball Method ❄️**: Prioritizes lowest balance first to build psychological momentum.
- **Avalanche Method 🏔️**: Prioritizes highest interest rate (APR %) first to minimize total interest paid.
- **Extra Budget Slider**: Interactive slider ($0–$1,000/mo) calculating real-time payoff time reductions.

### 📥 4. CSV Exporter & Analytics
- **CSV Statement Exporter**: Generates formatted CSV files (`firm_statement.csv`) ready for Tally, QuickBooks, or Microsoft Excel import.
- **FL Chart Visualizations**: Color-coded Income vs. Expense Pie Chart and Receivables vs. Payables Bar Chart.
- **Adaptive Dark & Light Theme**: Switch between **Modern Light** (`#F8FAFC`) and **Financial Dark Mode** (`#0F172A`).

---

## 📁 Project Architecture

```
firm_ledger/
├── assets/images/app_logo.jpg       # 3D Emerald & Gold App Logo Asset
├── android/                         # Android App Wrapper & Mipmap Launcher Icons
├── linux/                           # Linux Native C++ GTK Wrapper
├── lib/
│   ├── main.dart                   # Root ProviderScope, App Title & Material 3 Themes
│   ├── models/
│   │   ├── transaction.dart        # Income & Expense Data Model
│   │   ├── category.dart           # Expense Category & Monthly Budget Model
│   │   ├── debt.dart               # Owed & Lent Debt Model
│   │   ├── debt_payment.dart       # Payment Log Model
│   │   └── firm_profile.dart       # Firm Name, Tax ID & Currency Preference Model
│   ├── providers/
│   │   ├── transaction_provider.dart # Riverpod State Notifier for Transactions
│   │   ├── debt_provider.dart        # Riverpod State Notifier for Debts
│   │   ├── category_provider.dart    # Riverpod State Notifier for Budgets
│   │   ├── firm_provider.dart        # Riverpod State Notifier for Firm Settings
│   │   ├── theme_provider.dart       # Riverpod Theme Mode Switcher
│   │   └── dashboard_provider.dart   # Computed Net Worth & Cash Flow Provider
│   ├── services/
│   │   └── database_service.dart     # SQLite Database Service (sqflite & sqflite_common_ffi v2)
│   ├── utils/
│   │   ├── debt_calculator.dart      # Snowball vs. Avalanche Payoff Engine
│   │   ├── csv_exporter.dart         # Financial Statement CSV Report Exporter
│   │   └── formatters.dart           # Currency & Date Formatters
│   └── views/
│       ├── home_screen.dart          # Navigation Bar Host & Top App Bar
│       ├── dashboard_tab.dart        # 2x2 Summary Grid, Quick Actions & FL Charts
│       ├── expense_tab.dart          # Transaction Search, Filter Chips & Swipe-Delete
│       ├── debt_tab.dart             # Receivables vs Payables Lists & Payment Logger
│       ├── debt_payoff_screen.dart   # Interactive Payoff Strategy Simulator
│       ├── new_transaction_screen.dart # Income/Expense Form with Credit Auto-Sync
│       ├── edit_firm_dialog.dart     # Modal Bottom Sheet for Firm Profile Settings
│       └── card_detail_dialog.dart   # Filtered Drilldown Modal for Grid Cards
├── pubspec.yaml
├── LICENSE                          # MIT License
└── README.md
```

---

## ⚡ Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/wilamtoner/FirmLeager.git
cd FirmLeager
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run Natively on Connected Android Phone
```bash
flutter run
```

### 4. Run Natively on Linux Desktop
```bash
flutter run -d linux
```

### 5. Build Standalone Release APK
```bash
flutter build apk --release
```
📁 Release APK saved at: `build/app/outputs/flutter-apk/app-release.apk`

---

## ❓ Frequently Asked Questions (FAQ)

<details>
<summary><b>1. Is FirmLedger completely free and offline?</b></summary>
Yes. FirmLedger uses local SQLite database storage. All your transaction records, customer balances, and business settings remain 100% private on your device without needing cloud subscriptions or internet connection.
</details>

<details>
<summary><b>2. How does automatic credit ledger sync work?</b></summary>
When creating an entry, if you select <code>Payment Method: Credit / On Account</code> and type the customer's or supplier's name, FirmLedger automatically records the transaction AND creates a corresponding Receivable or Payable entry in the Debt Ledger.
</details>

<details>
<summary><b>3. Can I export my business data to Excel or Tally?</b></summary>
Yes. Tap the download icon (📥) in the top navigation bar to instantly generate a formatted CSV statement containing transaction IDs, dates, types, party names, payment methods, and amounts.
</details>

---

## 📄 License & Author

Distributed under the **MIT License**. See [LICENSE](LICENSE) for details.

Developed & Maintained by **[Wilam Toner](https://github.com/wilamtoner)**.

---

<p align="center">
  ⭐ <b>If you find FirmLedger helpful, please consider giving this repository a star on GitHub!</b> ⭐
</p>
