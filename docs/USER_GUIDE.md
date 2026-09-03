# FirmLedger User & Operator Guide

A complete guide to managing business accounting, customer credit accounts, supplier liabilities, and debt reduction strategies with **FirmLedger**.

---

## 1. Setting Up Your Business Profile

1. Tap the **Edit** button in the top AppBar or tap the top **Firm Banner Card** on the Dashboard.
2. Configure:
   * **Firm Name**: Displayed on all statement headers and invoices.
   * **Tax Registration ID (PAN / VAT / GST)**: Appears on official PDF statements.
   * **Business Address**: Location printed on invoices.
   * **Currency Symbol**: Enter your preferred symbol (e.g., `Rs`, `$`, `€`, `£`, `₹`, `¥`). All amounts across all screens will immediately synchronize.
3. Tap **Save Changes**.

---

## 2. Logging Daily Transactions

Tap **+ Income** or **- Expense** on the Dashboard action bar or the bottom navigation button:

### A. Cash or Bank Transactions
* Enter the **Amount** and **Title** (e.g., "Consulting Fee", "Office Electricity Bill").
* Select the **Category** (Sales, Rent, Utilities, Stock, etc.).
* Select `Payment Method: Cash` or `Payment Method: Bank`.
* Tap **Submit**.

### B. Credit Transactions (Accounts Receivable & Payable)
* When you sell goods/services on credit or purchase inventory without immediate payment:
  1. Set **Payment Method** to `Credit / On Account`.
  2. Enter the **Customer or Vendor / Party Name** (Mandatory).
  3. Tap **Submit**.
* **Automatic Double-Entry Sync**:
  * An Income Credit transaction automatically creates a **Receivable (Owed to Me)** record under the Debt tab.
  * An Expense Credit transaction automatically creates a **Payable (Owed by Me)** liability under the Debt tab.

---

## 3. Financial Dashboard & Analytics

The Dashboard aggregates financial performance over your chosen date range:

* **Top Summary Cards**:
  * 🟢 **Total Income**: Gross revenue earned.
  * 🔴 **Total Expenses**: Operating costs incurred.
  * 🟦 **Receivables (Assets)**: Money customers owe your firm.
  * 🔴 **Payables (Liabilities)**: Money your firm owes to suppliers.
  * 💎 **Net Position**: Calculated as $(\text{Income} + \text{Receivables}) - (\text{Expenses} + \text{Payables})$.
* **Date Range Selector**: Tap the calendar bar to restrict all totals and charts to `Today`, `This Month`, `Quarter`, or a custom date window.
* **Interactive Visualizations**:
  * **Income vs. Expense Donut Chart**: Visual distribution of revenue against burn rate.
  * **Receivables vs. Payables Bar Chart**: Comparison of credit liquidity.

---

## 4. Category Budget Limits & Over-Budget Alerts

Keep business expenditures within safe boundaries:
1. Under the **Ledger** tab, expand the **Category Budgets** card.
2. View real-time progress bars showing monthly spending vs. your budget limit.
3. Color-coded alerts:
   * 🟢 **Green**: Under 80% of limit.
   * 🟡 **Amber**: Approaching limit (80% to 99%).
   * 🔴 **Red & "Over Budget" Badge**: Spending has reached or exceeded 100% of the limit.

---

## 5. Debt Payoff Strategy Simulator

To simulate debt elimination:
1. Navigate to the **Debt** tab and tap the **Debt Payoff Strategy Calculator** banner.
2. Adjust the **Extra Monthly Payment Budget** slider ($0 to $1,000+).
3. Compare the outcomes:
   * **Snowball ❄️ (Lowest Balance First)**: Eliminates individual debts faster.
   * **Avalanche 🏔️ (Highest APR First)**: Saves the maximum amount of money in interest fees.
4. Review the **Payoff Order Sequence** and estimated payoff duration in years/months.

---

## 6. Real-Time Multi-Currency Converter

For international sales, foreign client invoicing, or cross-border trade:
1. Tap the **💱 Convert** button on the Dashboard.
2. Select your **Source Currency** (From) and **Target Currency** (To).
3. Tap the **⇄** button to swap currencies instantly.
4. View real-time exchange rates (fetched from `open.er-api.com`) with last-updated timestamps.
5. Tap **Copy Value** to copy the exact converted figure to your clipboard.

---

## 7. Reports & Data Backup

### PDF Statement Export
* Tap the **📄 PDF** button to generate a clean, multi-page business statement with letterhead, KPI summary blocks, transaction breakdown table, and signatory authorization block.
* Ready to print directly via Android Print Manager / CUPS or share as a PDF.

### CSV Statement Export
* Tap the **📥 CSV** button to download a standardized spreadsheet file compatible with Microsoft Excel, Google Sheets, Tally, and QuickBooks.

### Local JSON Database Backup & Restore
* Tap **Backup Database (JSON)** in the AppBar menu (`⋮` on mobile) to export a complete offline snapshot of all transactions, debts, categories, and firm profiles.
* To restore, choose **Restore Database** and select your previously saved JSON file.
