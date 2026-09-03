# FirmLedger Architectural Blueprint

**System**: FirmLedger (Enterprise Expense & Debt Ledger)  
**Target Runtimes**: Android (Impeller / Vulkan) & Linux Desktop (GTK / FFI)  
**Framework**: Flutter 3.35+ / Dart 3.6+  
**Architecture Pattern**: Layered Reactive Unidirectional Architecture (Riverpod + SQLite)  

---

## 1. System Architecture Overview

```mermaid
flowchart TD
    subgraph Presentation ["Presentation Layer (Material 3)"]
        UI_Home[HomeScreen & AppBar]
        UI_Dash[DashboardTab & Visual Charts]
        UI_Exp[ExpenseTab & Budget Progress]
        UI_Debt[DebtTab & Payoff Screen]
        UI_Conv[CurrencyConverterDialog]
        UI_Tx[NewTransactionScreen (PopScope)]
    end

    subgraph StateManagement ["Reactive State Layer (Riverpod)"]
        P_Tx[transactionProvider]
        P_Debt[debtProvider]
        P_Firm[firmProvider]
        P_Budget[categoryBudgetProvider]
        P_Curr[currencyConverterProvider]
        P_Rec[recurringProvider]
    end

    subgraph Services ["Service & Computation Layer"]
        S_Calc[DebtCalculator (Pure Math)]
        S_Curr[CurrencyService (Live API + Cache)]
        S_PDF[PdfInvoiceGenerator (Unicode/A4)]
        S_CSV[CsvExporter (RFC-4180)]
        S_Bak[BackupService (Offline JSON)]
        S_DB[DatabaseService (SQLite Schema v4)]
    end

    subgraph Storage ["Persistence & External I/O"]
        DB[(Local SQLite DB)]
        API[open.er-api.com API]
        FS[Filesystem / Documents]
    end

    UI_Home --> P_Firm
    UI_Dash --> P_Tx
    UI_Dash --> P_Debt
    UI_Dash --> P_Firm
    UI_Exp --> P_Tx
    UI_Exp --> P_Budget
    UI_Debt --> P_Debt
    UI_Conv --> P_Curr
    UI_Tx --> P_Tx
    UI_Tx --> P_Debt

    P_Tx --> S_DB
    P_Debt --> S_DB
    P_Firm --> S_DB
    P_Budget --> P_Tx
    P_Curr --> S_Curr
    P_Rec --> S_DB

    S_Curr --> API
    S_PDF --> FS
    S_CSV --> FS
    S_Bak --> DB
    S_DB --> DB
```

---

## 2. Database Schema & Migration History

The persistence layer uses a local SQLite database managed by `DatabaseService`.

### Schema Version History
* **Version 1**: Initial creation of `transactions`, `debts`, `categories`, and `firm_profile` tables.
* **Version 2**: Added `budget_limit` to `categories` table and created performance index `idx_transactions_date`.
* **Version 3**: Added compound performance indexes:
  * `idx_transactions_category`: `CREATE INDEX idx_transactions_category ON transactions(category_id)`
  * `idx_debts_owed`: `CREATE INDEX idx_debts_owed ON debts(is_owed_by_me, current_balance)`
* **Version 4**: Added `recurring_transactions` table for automated periodic subscriptions, rent, and recurring revenue.

### Table Definitions

#### `transactions`
```sql
CREATE TABLE transactions (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    amount REAL NOT NULL,
    date TEXT NOT NULL,
    type TEXT NOT NULL,             -- 'income' or 'expense'
    income_type TEXT,               -- 'business_revenue' or 'other'
    category_id TEXT NOT NULL,
    payment_method TEXT NOT NULL,   -- 'cash', 'bank', or 'credit'
    party_name TEXT,
    notes TEXT
);
```

#### `debts`
```sql
CREATE TABLE debts (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    party_name TEXT NOT NULL,
    original_amount REAL NOT NULL,
    current_balance REAL NOT NULL,
    apr REAL NOT NULL,
    min_monthly_payment REAL NOT NULL,
    due_date TEXT NOT NULL,
    is_owed_by_me INTEGER NOT NULL, -- 1 = Liability (I Owe), 0 = Asset (Owed to Me)
    notes TEXT
);
```

#### `recurring_transactions`
```sql
CREATE TABLE recurring_transactions (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    amount REAL NOT NULL,
    type TEXT NOT NULL,
    category_id TEXT NOT NULL,
    payment_method TEXT NOT NULL,
    party_name TEXT,
    frequency TEXT NOT NULL,         -- 'daily', 'weekly', 'monthly', 'yearly'
    start_date TEXT NOT NULL,
    next_due_date TEXT NOT NULL,
    last_executed_date TEXT,
    is_active INTEGER NOT NULL,
    notes TEXT
);
```

---

## 3. Algorithmic Debt Amortization Engine

The `DebtCalculator` executes deterministic simulation loops comparing two repayment methodologies:

### A. Debt Snowball (Balance Ascending)
$$\text{Sort Criteria: } \text{debt}_i.\text{currentBalance} < \text{debt}_j.\text{currentBalance}$$
* Lowest principal balances are attacked first with all available extra monthly budget.
* Eliminates accounts quickly, generating psychological motivation.

### B. Debt Avalanche (APR Descending)
$$\text{Sort Criteria: } \text{debt}_i.\text{apr} > \text{debt}_j.\text{apr}$$
* Highest interest rate debts are prioritized first.
* Mathematically minimizes total interest paid over the payoff lifetime.

### Simulation Loop (Monthly Step):
For each month $m$:
1. Accrue monthly interest on each active balance:
   $$I_k = B_k \times \left(\frac{\text{APR}_k}{100 \times 12}\right)$$
   $$B_k \leftarrow B_k + I_k$$
2. Pay minimum payments across all active accounts:
   $$P_k = \min(B_k, \text{minPayment}_k)$$
   $$B_k \leftarrow B_k - P_k$$
3. Apply remaining extra monthly budget + freed minimum payments to the target debt $T$:
   $$P_{\text{target}} = \min(B_T, \text{AvailableBudget})$$
   $$B_T \leftarrow B_T - P_{\text{target}}$$
4. Terminate when $\sum B_k = 0$ or month cap (600 months) is reached.

---

## 4. Multi-Currency Live Triangulation Formula

The `CurrencyService` uses USD as the pivot base currency. To convert amount $A$ from currency $S$ (source) to $T$ (target):

$$\text{Converted Amount} = A \times \left(\frac{\text{Rate}_T}{\text{Rate}_S}\right)$$

* When $S = T$, returns $A$ in $O(1)$ without floating point error.
* Offline cache provides instant fallback values if network timeout occurs.

---

## 5. Performance Engineering

* **Repaint Boundary Isolation**: FL Chart graphs (`PieChart`, `BarChart`) are isolated inside `RepaintBoundary` widgets to protect the rest of the dashboard from unnecessary canvas re-rasterization.
* **$O(1)$ Pre-Indexed Maps**: Categories are mapped into a hash index before building `ListView` rows, eliminating $O(N \times C)$ search complexity during scrolling.
* **State Preservation**: The top-level application relies on `IndexedStack` to keep all 3 tabs alive in memory, preventing expensive database re-queries upon tab switching.
