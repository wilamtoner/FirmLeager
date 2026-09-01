# FirmLedger: Expense & Debt Manager

<p align="center">
  <img src="assets/images/app_logo.jpg" alt="FirmLedger Logo" width="120" style="border-radius: 20px;"/>
</p>

<p align="center">
  <b>A modern, cross-platform Firm Accounting, Expense Ledger, and Debt Payoff Management application built with Flutter, Riverpod, SQLite, and FL Chart.</b>
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.47.2-02569B?style=for-the-badge&logo=flutter" alt="Flutter"/></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart" alt="Dart"/></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge" alt="License"/></a>
  <a href="https://android.com"><img src="https://img.shields.io/badge/Platform-Android%20%7C%20Linux-brightgreen?style=for-the-badge" alt="Platforms"/></a>
</p>

---

## 🌟 Key Features

### 📊 1. Firm Financial Dashboard & 2x2 Ledger Grid
- **Firm Header Banner**: Custom Firm Name, PAN/Tax Registration ID, Address, and Currency Symbol (`Rs.`, `$`, `€`, `£`).
- **2x2 Financial Summary Grid**:
  - 🟢 **Income (Revenue)**: Tracks total revenue with detailed drilldown.
  - 🔴 **Expense (Outflows)**: Tracks operating expenditures and purchases.
  - 🟦 **Receivables (Money to Collect)**: Tracks customer credit sales and debtor balances.
  - 🔴 **Payables (Money Due)**: Tracks supplier credit purchases and lender debts.
- **Date Range Picker**: Interactive date range selector (`YYYY-MM-DD` to `YYYY-MM-DD`) filtering all ledger metrics and analytics.

### 📝 2. Modern Entry Form & Auto-Credit Sync
- **Income $\leftrightarrow$ Expense Switcher**: Dynamic form toggling between Income and Expense modes.
- **Categorized Inputs**: Goods/Product Sales, Service Revenue, Inventory Purchases, Utilities, and Operating Expenses.
- **Automatic Credit Sync**: Selecting `Payment Method: Credit / On Account` automatically generates a **Receivable** or **Payable** debt entry in the ledger.

### 🧮 3. Debt Payoff Strategy Simulator
- **Snowball Method ❄️**: Prioritizes lowest balance first to build momentum.
- **Avalanche Method 🏔️**: Prioritizes highest interest rate (APR %) first to minimize total interest paid.
- **Extra Payment Slider**: Simulates extra monthly allocations ($0–$1,000/mo) with real-time payoff time reductions.

### 📥 4. Statement CSV Exporter & Analytics
- **CSV Exporter**: Generates formatted CSV financial statements (`firm_statement.csv`) for accounting software import (Tally, QuickBooks, Excel).
- **Interactive Charts**: Income vs. Expense Pie Chart and Receivables vs. Payables Bar Chart via `FL Chart`.
- **Adaptive Dark & Light Theme**: Seamless switching between **Modern Light** (`#F8FAFC`) and **Financial Dark Mode** (`#0F172A`).

---

## 📁 Architecture & Tech Stack

```
expense_debt_manager/
├── assets/images/app_logo.jpg       # App Branding & Icons
├── android/                         # Android Platform & Mipmap Launcher Icons
├── linux/                           # Linux Native C++ Wrapper
├── lib/
│   ├── main.dart                   # Root ProviderScope & Theme Configurations
│   ├── models/                      # Transaction, Category, Debt, FirmProfile Models
│   ├── providers/                   # Riverpod State Notifiers (Transaction, Debt, Category, Firm, Theme)
│   ├── services/                    # SQLite Database Service (sqflite & sqflite_common_ffi v2)
│   ├── utils/                       # Debt Calculator, CSV Exporter, Formatters
│   └── views/                       # DashboardTab, ExpenseTab, DebtTab, NewTransactionScreen, Modals
├── pubspec.yaml
└── LICENSE                          # MIT License
```

- **Framework**: Flutter (Material 3)
- **State Management**: `flutter_riverpod` (v2.x)
- **Database**: `sqflite` & `sqflite_common_ffi`
- **Charts**: `fl_chart`
- **Formatting**: `intl`

---

## 🚀 How to Build & Run

### Prerequisites
- Flutter SDK 3.x+
- Android SDK / Linux GTK build tools (`clang`, `cmake`, `ninja-build`)

### Run on Connected Android Device
```bash
flutter run
```

### Run on Linux Desktop
```bash
flutter run -d linux
```

### Build Standalone Release APK for Android (Google Play Store)
```bash
flutter build apk --release
```
📁 APK Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

Copyright (c) 2026 **Wilam Toner**.
