# FirmLedger: Small Business Accounting, Expense & Debt Manager

<p align="center">
  <img src="assets/images/app_logo.jpg" alt="FirmLedger Logo" width="130" style="border-radius: 24px; box-shadow: 0 8px 24px rgba(0,0,0,0.15);"/>
</p>

<p align="center">
  <b>The Ultimate Open-Source Small Business Accounting, Firm Ledger, Cash Flow Tracker, Real-Time Currency Converter & Debt Payoff Management App built with Flutter, Riverpod, SQLite, and FL Chart.</b>
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.35+-02569B?style=for-the-badge&logo=flutter" alt="Flutter"/></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.6+-0175C2?style=for-the-badge&logo=dart" alt="Dart"/></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge" alt="License"/></a>
  <a href="test"><img src="https://img.shields.io/badge/Tests-28%2F28%20Passing-brightgreen?style=for-the-badge" alt="Tests"/></a>
  <a href=".specify/constitution.md"><img src="https://img.shields.io/badge/SpecKit-Governed-purple?style=for-the-badge" alt="SpecKit"/></a>
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

### 📊 1. Financial Dashboard & 2x2 Grid
- **Firm Profile Banner**: Displays business name, PAN/VAT/GST tax registration ID, address, and dynamic currency symbol (`Rs`, `$`, `€`, `£`, `₹`, `¥`).
- **2x2 General Ledger Grid**:
  - 🟢 **Income (Revenue)**: Tracks total revenue with breakdown drilldown modals.
  - 🔴 **Expense (Outflows)**: Monitors operational expenditures, stock purchases, and utilities.
  - 🟦 **Receivables (Money to Collect)**: Tracks customer credit sales and debtor balances.
  - 🔴 **Payables (Money Due)**: Manages supplier credit purchases and vendor liabilities.
- **Dynamic Date Range Filter**: Interactive date range selector (`YYYY-MM-DD` to `YYYY-MM-DD`) strictly bounding all dashboard calculations.

### 💱 2. Real-Time Multi-Currency Converter
- **Live Exchange Rates**: Fetches live foreign exchange rates directly from `open.er-api.com` for 160+ world currencies without requiring any API key.
- **Cross-Currency Triangulation**: Convert between any two currencies seamlessly (e.g. EUR $\to$ NPR, INR $\to$ GBP).
- **Offline Fallback**: Pre-cached currency dictionary ensures instant conversion calculations even without internet access.
- **One-Tap Currency Swap (`⇄`)**: Invert source and target currencies with live reciprocal math.

### 📝 3. Income & Expense Entry Form
- **Income $\leftrightarrow$ Expense Segment Switcher**: Fast single-screen form toggling.
- **Form Navigation Protection (`PopScope`)**: Warns before leaving unsaved input, preventing accidental data loss during back gestures or Esc triggers.
- **Categorized Inputs**: Goods/Product Sales, Service Revenue, Stock Purchases, Utilities, and Operating Expenses.
- **Automatic Credit Sync**: Selecting `Payment Method: Credit / On Account` automatically creates a **Receivable (Owed to Me)** or **Payable (Owed by Me)** debt entry in the ledger.

### 🎯 4. Category Budget Limits & Alert Thresholds
- **Monthly Budget Bars**: Visual progress bars in the ledger tab tracking spending against category budget limits.
- **Color-Coded Status**:
  - 🟢 Under 80%: Normal spending
  - 🟡 80% – 99%: Nearing budget limit
  - 🔴 100%+: Visual alert badge signaling over-budget status

### 🧮 5. Debt Payoff Engine (Snowball vs. Avalanche)
- **Snowball Method ❄️**: Prioritizes lowest balance first to build psychological momentum.
- **Avalanche Method 🏔️**: Prioritizes highest interest rate (APR %) first to mathematically minimize total interest paid.
- **Extra Budget Slider**: Interactive slider ($0–$1,000/mo) calculating real-time payoff time reductions.
- **Synchronized Currency**: Respects the firm's configured currency symbol dynamically across all interest, balance, and repayment views.

### 📄 6. Statements, Export & Backup
- **PDF Invoice & Statement Generator**: Multi-page formal business statement featuring firm letterhead, PAN/VAT ID, financial KPI summary cards, transaction table, and signatory authorization block.
- **CSV Statement Exporter**: Generates formatted CSV files (`firm_statement.csv`) ready for Tally, QuickBooks, or Microsoft Excel import.
- **Structured JSON Backup & Restore**: Export and import full-database snapshots offline for reliable disaster recovery.

---

## 📁 Project Architecture

```
expense_debt_manager/
├── android/                         # Android App Wrapper (Kotlin 2.4, Impeller Vulkan)
├── linux/                           # Linux Native C++ GTK Wrapper (SQLite FFI)
├── assets/images/app_logo.jpg       # App Logo Asset
├── docs/
│   ├── ARCHITECTURE.md              # System Architecture & Schema Specification
│   └── USER_GUIDE.md                # Operator & User Manual
├── .specify/
│   ├── constitution.md              # Engineering Constitution & Quality Gates
│   ├── tasks.md                     # Roadmap, Tasks & Gantt Timeline
│   └── specs/                       # Comprehensive System Specifications
├── lib/
│   ├── main.dart                   # Root ProviderScope & Material 3 Theme
│   ├── models/
│   │   ├── transaction.dart        # Transaction Entity & Serialization
│   │   ├── category.dart           # Category & Budget Limit Entity
│   │   ├── debt.dart               # Bilateral Debt & Loan Entity
│   │   ├── recurring_transaction.dart # Periodic Recurring Schedule Entity
│   │   └── firm_profile.dart       # Firm Profile & Currency Configuration
│   ├── providers/
│   │   ├── transaction_provider.dart # Transactions State Notifier
│   │   ├── debt_provider.dart        # Debt Ledger State Notifier
│   │   ├── dashboard_provider.dart   # KPI & Category Budget Status Providers
│   │   ├── currency_provider.dart    # Live Currency Conversion State Notifier
│   │   ├── recurring_provider.dart   # Recurring Auto-Processing Provider
│   │   └── firm_provider.dart        # Firm Settings State Notifier
│   ├── services/
│   │   ├── database_service.dart     # SQLite Database Service (Schema Version 4)
│   │   └── currency_service.dart     # Real-Time Rate Service (open.er-api.com)
│   ├── utils/
│   │   ├── debt_calculator.dart      # Snowball vs. Avalanche Payoff Engine
│   │   ├── pdf_invoice_generator.dart# Multi-page Business PDF Generator
│   │   ├── csv_exporter.dart         # RFC-4180 CSV Statement Exporter
│   │   ├── backup_service.dart       # JSON Database Snapshot Backup & Restore
│   │   └── formatters.dart           # Dynamic Currency & Date Formatters
│   └── views/
│       ├── home_screen.dart          # Responsive Navigation & Material 3 AppBar
│       ├── dashboard_tab.dart        # 2x2 KPI Grid, Horizontal Quick Actions & Charts
│       ├── expense_tab.dart          # Transaction Search, Filter Chips & Budget Cards
│       ├── debt_tab.dart             # Debts I Owe & Owed to Me Lists
│       ├── debt_payoff_screen.dart   # Debt Payoff Simulator with Extra Budget Slider
│       ├── currency_converter_dialog.dart # Live Currency Converter Modal Dialog
│       ├── new_transaction_screen.dart # Transaction Form with PopScope Guard
│       └── edit_firm_dialog.dart     # Firm Profile Bottom Sheet Modal
├── test/                            # 28 Automated Unit & Invariant Tests (100% Passing)
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
