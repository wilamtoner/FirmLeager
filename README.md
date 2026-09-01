# Expense & Debt Manager (Flutter + Riverpod)

A production-ready, cross-platform **Expense and Debt Manager** built with **Flutter**, **Riverpod**, **SQFlite**, and **FL Chart**.

---

## 🌟 Features

### 1. Expense & Income Tracking
- Log Income and Expenses with Categories, Dates, Amount, and Notes.
- Filter transactions by category or search query.
- Track category budget limits with visual progress indicators and 80%/100% threshold warnings.

### 2. Debt Management & Payoff Engine
- Track **Debts Owed (Liabilities)** and **Debts Owed to You (Assets)**.
- Store original amount, current balance, interest rate (APR %), and minimum monthly payments.
- Log payments against active debts with instant balance updates.
- **Payoff Strategy Simulator**:
  - **Snowball Method**: Prioritizes lowest balance first for psychological momentum.
  - **Avalanche Method**: Prioritizes highest interest rate (APR) first to minimize total interest paid.
  - Interactive slider to test extra monthly payment allocations.

### 3. Financial Analytics & Dashboard
- **Net Worth**: Real-time Net Worth calculation ($Assets - Liabilities$).
- **Cash Flow Chart**: Visual breakdown of Income, Expenses, and Debt burdens using `FL Chart`.
- **Debt-to-Income (DTI) Ratio**: Financial health metric.

---

## 📁 Architecture & Tech Stack

```
expense_debt_manager/
├── lib/
│   ├── main.dart                      # Root App & ProviderScope
│   ├── models/                        # Transaction, Category, Debt, DebtPayment
│   ├── providers/                     # Riverpod Notifiers (Transaction, Debt, Category, Dashboard)
│   ├── services/                      # SQLite Database Service
│   ├── utils/                         # Debt Payoff Calculator & Formatters
│   └── views/                         # Dashboard, Expense, Debt, Payoff Screens & Dialogs
└── pubspec.yaml
```

- **Framework**: Flutter (Dart)
- **State Management**: `flutter_riverpod` (v2.x)
- **Database**: `sqflite` & `sqflite_common_ffi`
- **Charts**: `fl_chart`
- **Formatting**: `intl`

---

## 🚀 How to Run

1. Clone or navigate to directory:
   ```bash
   cd /run/media/nepal/Backup/VS Code projects/expense_debt_manager
   ```
2. Get dependencies:
   ```bash
   flutter pub get
   ```
3. Run on your connected device or emulator:
   ```bash
   flutter run
   ```
