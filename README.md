# FirmLedger: Small Business Accounting, Expense & Debt Manager

<p align="center">
  <img src="assets/images/app_logo.png" alt="FirmLedger Logo" width="130" style="border-radius: 28px; box-shadow: 0 8px 24px rgba(0,0,0,0.18);"/>
</p>

<p align="center">
  <b>High-Performance Small Business Financial Accounting, General Ledger, Cash Flow Analytics, Live Nepal Gold & Silver Rates, Nepali Date Converter, Real-Time Currency Converter & Debt Manager built with Flutter, Riverpod, SQLite, and FL Chart.</b>
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.24+-02569B?style=for-the-badge&logo=flutter" alt="Flutter"/></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.6+-0175C2?style=for-the-badge&logo=dart" alt="Dart"/></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge" alt="License"/></a>
  <a href="test"><img src="https://img.shields.io/badge/Tests-48%2F48%20Passing-brightgreen?style=for-the-badge" alt="Tests"/></a>
  <a href="https://fonts.google.com/specimen/Plus+Jakarta+Sans"><img src="https://img.shields.io/badge/Typography-Plus%20Jakarta%20Sans-0D6EFD?style=for-the-badge" alt="Typography"/></a>
</p>

---

## 📌 Executive Summary

**FirmLedger** is a high-performance, cross-platform financial accounting and general ledger application designed for small business owners, freelancers, traders, and personal finance management. It combines real-time cash flow analytics, double-entry-style credit transaction logging, customer/supplier balances, live foreign exchange rate conversion, and an algorithmic **Debt Payoff Engine (Snowball vs. Avalanche)**.

Whether managing daily sales, tracking customer credit accounts (Receivables), logging vendor payables, monitoring monthly category budgets, generating official PDF statements, or converting international currencies, **FirmLedger** delivers a seamless offline-first experience with zero subscription fees.

---

## 📚 Complete Documentation Index

* 📜 [**System Constitution**](.specify/constitution.md): Architectural laws, code quality gates, testing mandates, and performance budgets.
* 🏛️ [**Architecture Blueprint**](docs/ARCHITECTURE.md): Database schema v4 migrations, Riverpod provider graph, and mathematical formulas.
* 📖 [**User & Operator Guide**](docs/USER_GUIDE.md): Step-by-step walkthrough for all daily accounting and debt workflows.
* 📋 [**System Specification**](.specify/specs/comprehensive_system_spec.md): Comprehensive SpecKit requirements, data models, and Gherkin acceptance criteria.
* ✅ [**Task Roadmap & Matrix**](.specify/tasks.md): Complete Phase 1–6 task execution status and Gantt chart.

---

## 🌟 Key Features

### 📊 1. Financial Dashboard & Gradient Line Analytics
- **Firm Profile Banner**: Displays business name, PAN/VAT/GST tax registration ID, address, and dynamic currency symbol (`Rs`, `$`, `€`, `£`, `₹`, `¥`).
- **2x2 General Ledger Matrix**:
  - 🟢 **Income (Revenue)**: Tracks total revenue with breakdown drilldown modals.
  - 🔴 **Expense (Outflows)**: Monitors operational expenditures, stock purchases, and utilities.
  - 🟦 **Receivables (Money to Collect)**: Tracks customer credit sales and debtor balances.
  - 🔴 **Payables (Money Due)**: Manages supplier credit purchases and vendor liabilities.
- **Dynamic Date Range Filter**: Interactive date range selector strictly bounding all dashboard calculations.
- **Gradient Line Chart Analytics**: Smooth spline curve visualization comparing inflow vs. outflow trends over time with interactive touch indicators.

### 🥇 2. Live Nepal Gold & Silver Rates with Jewelry Calculator
- **Live FENEGOSIDA Rates**: Real-time official rates for Fine Gold (*छापावाल सुन*), Tejabi Gold, and Pure Silver from the Federation of Nepal Gold and Silver Dealers' Association.
- **Interactive Jewelry Calculator**: Computes exact jewelry costs across **Tola**, **Gram**, and **Lal** units with customizable making charges and wastage percentages.
- **Offline Resilience**: Automatically serves pre-cached baseline market rates when operating without an internet connection.

### 📅 3. Nepali Bikram Sambat (BS) & English (AD) Date Converter
- **Bidirectional Conversion**: Convert Gregorian (AD) dates to Bikram Sambat (BS) dates and vice versa.
- **Cultural Calendar Metadata**: Displays dates in both Devanagari script and English transliteration with weekday and festival month names.
- **Date Difference & Age Calculator**: Calculates exact duration between any two dates in years, months, and days.
- **UTC Leap-Safe Math**: Eliminates client daylight saving time (DST) shifts.

### 💱 4. Real-Time Multi-Currency Converter
- **Live FX Rates**: Triangulates exchange rates across 160+ world currencies via `open.er-api.com`.
- **One-Tap Inversion (`⇄`)**: Invert source and target currencies with live reciprocal math.
- **Offline Fallback**: Pre-cached currency dictionary ensures instant conversion calculations even without internet access.

### 📋 5. Dedicated Debt & Loan Management
- **Full-Page Entry Screen**: Clean form design with *Plus Jakarta Sans* typography.
- **Flexible Terms**: Supports **0% Interest** (friend & family loans, supplier credit) and **Flexible Payment Terms** (zero mandatory monthly minimum).
- **Payment Logging**: Record partial or full repayments with automatic balance updating and audit history.
- **Navigation Guard (`PopScope`)**: Prevents accidental data loss if navigating away with unsaved details.

### 🎯 6. Category Budget Limits & Alert Thresholds
- **Monthly Budget Bars**: Visual progress bars in the ledger tab tracking spending against category budget limits.
- **Color-Coded Status**:
  - 🟢 Under 80%: Normal spending
  - 🟡 80% – 99%: Nearing budget limit
  - 🔴 100%+: Visual alert badge signaling over-budget status

### 📄 7. Statements, Export & Backup
- **PDF Invoice & Statement Generator**: Multi-page formal business statement featuring firm letterhead, PAN/VAT ID, financial KPI summary cards, transaction table, and signatory authorization block.
- **CSV Statement Exporter**: Generates formatted CSV files (`firm_statement.csv`) ready for Tally, QuickBooks, or Microsoft Excel import.
- **Structured JSON Backup & Restore**: Export and import full-database snapshots offline for reliable disaster recovery.

---

## ⚡ App Size & Performance Optimization

Through aggressive code minification, asset pruning, and architecture-targeted packaging, the production application footprint has been reduced by **~65%**:

| Metric | Before Optimization | After Optimization | Reduction |
| :--- | :--- | :--- | :--- |
| **`app-armeabi-v7a-release.apk`** | 57.0 MB (fat APK) | **18.1 MB** | **-68.2%** |
| **`app-arm64-v8a-release.apk`** | 57.0 MB (fat APK) | **20.5 MB** | **-64.0%** |
| **`app-x86_64-release.apk`** | 57.0 MB (fat APK) | **22.0 MB** | **-61.4%** |
| **Bundled Assets (`assets/`)** | ~1.3 MB | **376 KB** | **-71.1%** |
| **Material Icons Font** | 1.64 MB | **6.8 KB** (Tree-shaken) | **-99.6%** |

- **R8 / ProGuard Code & Resource Shrinking**: Unused Kotlin/Java bytecode and resources are stripped during release compilation.
- **100% Offline Plus Jakarta Sans Typography**: Direct font bundling eliminates runtime HTTP font downloads and pruned **15 transitive packages**.
- **Quantized App Graphics**: App logo optimized with 256-color palette compression (from 468 KB to 18 KB).

---

## 📁 Project Architecture

```
expense_debt_manager/
├── android/                         # Android App Wrapper (Kotlin 2.4, R8 / ProGuard Enabled)
│   ├── app/
│   │   ├── build.gradle.kts         # Minification, Resource Shrinking & ABI Split Config
│   │   └── proguard-rules.pro       # Flutter & SQLite Reflection Preservation Rules
├── assets/
│   ├── fonts/                       # Plus Jakarta Sans (Regular & Italic)
│   └── images/                      # App Logo (512x512 Quantized PNG)
├── docs/
│   ├── ARCHITECTURE.md              # System Architecture & Schema Specification
│   └── USER_GUIDE.md                # Operator & User Manual
├── lib/
│   ├── main.dart                    # App Entry Point & Plus Jakarta Sans Theme
│   ├── models/                      # Domain Entities & Serialization
│   │   ├── category.dart            # Category & Budget Limit Model
│   │   ├── debt.dart                # Bilateral Debt & Loan Model
│   │   ├── debt_payment.dart        # Debt Payment Record Model
│   │   ├── firm_profile.dart        # Business Profile & Currency Model
│   │   ├── gold_silver_rate.dart    # FENEGOSIDA Commodity Rate Model
│   │   ├── recurring_transaction.dart # Periodic Recurring Schedule Model
│   │   └── transaction.dart         # Income/Expense Transaction Model
│   ├── providers/                   # State Management (Riverpod)
│   │   ├── category_provider.dart   # Categories State
│   │   ├── currency_provider.dart   # Live FX Rate State
│   │   ├── dashboard_provider.dart  # KPI & Category Budget Status
│   │   ├── debt_provider.dart       # Debt Ledger & Payment State
│   │   ├── firm_provider.dart       # Firm Settings State
│   │   ├── gold_silver_provider.dart# Live Gold/Silver Price State
│   │   ├── recurring_provider.dart  # Recurring Auto-Processing State
│   │   ├── theme_provider.dart      # Dark/Light Theme State
│   │   └── transaction_provider.dart# Transaction Ledger State
│   ├── services/                    # Background & Database Services
│   │   ├── currency_service.dart    # FX Exchange Rate Engine
│   │   ├── database_service.dart    # SQLite Engine (Schema v4 with Indexes)
│   │   └── gold_silver_service.dart # FENEGOSIDA Commodity Engine & Math
│   ├── theme/                       # Design System
│   │   └── app_colors.dart          # Executive Palette (Navy #0A2540, Azure #0D6EFD, Cyan #38BDF8)
│   ├── utils/                       # Utility Helpers
│   │   ├── backup_service.dart      # JSON Snapshot Backup & Restore
│   │   ├── csv_exporter.dart        # RFC-4180 CSV Statement Generator
│   │   ├── debt_calculator.dart     # Snowball vs. Avalanche Payoff Engine
│   │   ├── formatters.dart          # Dynamic Currency, Date & Number Formatters
│   │   ├── nepali_date_helper.dart  # Bikram Sambat (BS) & English (AD) Calendar Math
│   │   └── pdf_invoice_generator.dart # Multi-Page Business Statement PDF Generator
│   └── views/                       # User Interface Views & Screens
│       ├── add_debt_dialog.dart     # Quick-Add Debt Modal
│       ├── add_transaction_dialog.dart # Quick-Add Transaction Modal
│       ├── card_detail_dialog.dart  # Financial KPI Breakdown Modal
│       ├── currency_converter_dialog.dart # Currency Converter Dialog
│       ├── currency_converter_screen.dart # Full-Page Currency Converter
│       ├── dashboard_tab.dart       # KPI Matrix, Line Charts & Gold Ticker
│       ├── date_converter_screen.dart # Nepali BS & AD Date Converter Screen
│       ├── debt_tab.dart            # Debt Ledger, Receivables & Payables
│       ├── edit_firm_dialog.dart    # Firm Profile Editor
│       ├── expense_tab.dart         # Transaction List, Filter Chips & Search
│       ├── gold_silver_screen.dart  # Live Commodities & Calculator Screen
│       ├── home_screen.dart         # Scaffold, NavigationBar & Action Menus
│       ├── new_debt_screen.dart     # Dedicated Add Debt/Loan Screen
│       ├── new_transaction_screen.dart # Dedicated Add Transaction Screen
│       └── splash_screen.dart       # Animated Splash Screen
├── test/                            # 48 Automated Unit, Model & Widget Tests (100% Passing)
├── pubspec.yaml
├── LICENSE                          # MIT License
└── README.md
```

---

## ⚡ Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/wilamtoner/FirmLeager.git
cd expense_debt_manager
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run on Connected Android Device
```bash
flutter run
```

### 4. Run on Linux Desktop
```bash
flutter run -d linux
```

### 5. Execute Test Suite
```bash
flutter test
```

### 6. Build Production Release Bundles
```bash
# Android App Bundle (Play Store)
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols

# Linux Desktop Bundle
flutter build linux --release
```

---

## ❓ Frequently Asked Questions (FAQ)

<details>
<summary><b>1. Is FirmLedger completely free and offline?</b></summary>
Yes. FirmLedger uses local SQLite database storage. All your transaction records, customer balances, and business settings remain 100% private on your device without needing cloud subscriptions or internet connectivity.
</details>

<details>
<summary><b>2. How does automatic credit ledger sync work?</b></summary>
When creating an entry, selecting <code>Payment Method: Credit / On Account</code> and typing the customer's or supplier's name automatically logs the transaction AND creates a linked Receivable or Payable entry in the Debt Ledger.
</details>

<details>
<summary><b>3. Does the currency converter work offline?</b></summary>
Yes. While it fetches live exchange rates from <code>open.er-api.com</code> whenever connected, it maintains an embedded local cache and fallback dictionary so currency conversions continue functioning without internet.
</details>

<details>
<summary><b>4. How do I backup my database?</b></summary>
Open the top AppBar menu (<code>⋮</code> on mobile or the backup icon on desktop) and tap <b>Backup Database (JSON)</b>. You can transfer this JSON snapshot to another device and tap <b>Restore Database</b> anytime.
</details>

---

## 📄 License & Author

Distributed under the **MIT License**. See [LICENSE](LICENSE) for details.

Developed & Maintained by **[Wilam Toner](https://github.com/wilamtoner)**.
