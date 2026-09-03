# FirmLedger System Constitution

**Document**: System Engineering & Architectural Constitution  
**Status**: `Enforced`  
**Version**: `1.0.0`  
**Effective Date**: 2026-09-03  
**Authority**: SpecKit / FirmLedger Technical Steering  

---

## Preamble

This Constitution establishes the non-negotiable engineering principles, quality covenants, testing mandates, user experience standards, and performance budgets governing all contributions, refactors, and automated workflows across the **FirmLedger** codebase. Every line of code committed to this repository must uphold these tenets.

---

## Article I: Code Quality & Architectural Integrity

### 1.1 Language & Framework Modernization
* **SDK Baseline**: The codebase shall strictly target Dart $\ge 3.6.0 < 4.0.0$ and modern Flutter stable channels.
* **Modern Dart 3 Features**:
  * Utilize exhaustive **switch expressions** and **records / pattern matching** in place of imperative switch statements.
  * Employ **wildcard variables** (`_`), **digit separators** (`1_000_000`), and private field promotion where applicable.
* **Zero-Deprecation Policy**:
  * Deprecated widgets and APIs are strictly prohibited in production code.
  * Form and navigation back gestures must use `PopScope(canPop: ..., onPopInvokedWithResult: ...)`, never legacy `WillPopScope`.
  * Color alpha modifications must use `Color.withValues(alpha: ...)`, never `Color.withOpacity(...)`.
  * Form fields must adhere to the latest SDK properties (e.g., `initialValue` on form fields, avoiding deprecated `value`).
* **Static Analysis**:
  * `flutter analyze` must always exit with **zero issues** (0 errors, 0 warnings, 0 infos). No build or pull request may proceed with open analyzer alerts.

### 1.2 Architectural Layering & Separation of Concerns
The repository enforces a clean unidirectional architecture:
```
lib/
├── models/       # Pure, immutable data contracts with serialization (toMap, fromMap, copyWith)
├── services/     # Low-level I/O, SQLite FFI database access, HTTP network clients, backup generators
├── providers/    # Riverpod state managers, business logic, and reactive calculation pipelines
├── utils/        # Stateless formatters, debt algorithms, and export utilities
└── views/        # Pure presentation layer, Material 3 UI widgets, and dialogs
```
* **Immutability**: All model entities must be immutable (`@immutable`) with explicit `copyWith` support.
* **State Decoupling**: Business calculations, financial formulas, and database operations must never reside within widget build methods. All reactive state must flow through **Riverpod** providers.

---

## Article II: Testing Standards & Test-First Discipline

### 2.1 Test-First Thinking (TDD)
* Any new financial formula, date calculation, data serialization schema, or export transformer must begin with **Test-First specifications** before or alongside implementation.
* The test suite must independently verify:
  1. **Happy Path**: Standard business operations with realistic payloads.
  2. **Boundary Conditions**: Zero amounts, maximum limits, negative inputs, empty datasets.
  3. **Calendar Rollovers**: Month-end transitions (e.g., Jan 31 $\to$ Feb 28), leap-year calculations (Feb 29), and daylight boundaries.
  4. **Mathematical Symmetry**: Reciprocal operations (e.g., $A \to B \to A$ currency conversion), balance conservation, and amortization equality.

### 2.2 Invariant Verification Mandate
* Financial calculations are mission-critical. Tests must mathematically prove:
  * **Debt Invariant**: Repayments must clamp at 0 balance (`balance = max(0, balance - payment)`).
  * **Interest Invariant**: Debts with $0\%$ APR must incur strictly $0.00$ total interest paid.
  * **DTI Ratio Invariant**: Division by zero must be protected; zero-income firms must return safely clamped ratios.
  * **Export Invariant**: Date-range filters in CSV and PDF exports must strictly omit transactions outside the boundary timestamps.

### 2.3 Continuous Regression Shield
* The automated test suite (`flutter test`) must maintain **100% pass rates** across all unit and widget tests.
* Any commit that breaks an existing test is rejected automatically.

---

## Article III: User Experience (UX) Consistency

### 3.1 Visual Design Language
* **Design System**: Material 3 (M3) throughout the entire application.
* **Brand Identity**: Cohesive Financial Emerald & Mint palette:
  * Primary: Dark Emerald (`#064E3B`)
  * Accent / Active: Vibrant Mint (`#10B981`)
  * Surface & Cards: Elevated cards with subtle borders (`withValues(alpha: 0.1)`).
* **Button Uniformity**: All primary floating action buttons, confirmation dialog buttons, and submit triggers must match the primary dark emerald theme.

### 3.2 Navigation Safety & Unsaved Input Protection
* **Predictive Navigation**: Screens with user inputs (`NewTransactionScreen`, dialogs) must be wrapped in `PopScope` to confirm discard if fields are dirty, preventing accidental data loss during back swipes or Esc key triggers.
* **Seamless Multi-Tab Switching**: Top-level tabs must be rendered using `IndexedStack` to preserve scroll positions, form inputs, and chart states without flickering or costly re-instantiations.

### 3.3 Dynamic Multi-Currency Harmonization
* The currency symbol configured in **Edit Firm Information** (e.g., `$`, `Rs`, `€`, `£`, `¥`, `₹`) must propagate dynamically across:
  * Dashboard summary cards and metric totals
  * Transaction ledger rows and filter chips
  * Debt balance lists, minimum payment labels, and payoff sequence cards
  * Add Debt and Log Payment dialog inputs
  * PDF Statements and CSV exports

---

## Article IV: Performance Requirements & Resource Budgets

### 4.1 Frame Budget & Render Smoothness
* **Frame Rate**: The user interface must maintain a smooth **60 FPS** (16.6ms frame deadline) on standard commodity hardware.
* **Render Boundary Isolation**:
  * Computationally intensive widgets, specifically `fl_chart` charts (`PieChart`, `BarChart`), must be encapsulated within `RepaintBoundary` widgets.
  * Charts must use static animation durations to prevent continuous GPU wakeups during idle screen time.

### 4.2 Computational Complexity Limits
* **Render-Time Loops**: No $O(N)$ collection traversals are permitted inside widget `ListView.builder` or `Table` item builders.
* **Pre-Computed Lookup Maps**: Category lookups and relational lookups must be pre-indexed into $O(1)$ HashMaps prior to list builds.

### 4.3 Memory & Resource Consumption
* **Desktop Resource Footprint**: Native Linux GTK desktop bundle must maintain an idle RSS memory footprint below **200 MB**.
* **Database I/O**:
  * SQLite database queries must utilize optimized compound indexes (`idx_transactions_date`, `idx_transactions_category`, `idx_debts_owed`).
  * Database connections must utilize SQLite FFI connection pooling without redundant file re-openings.

### 4.4 Offline-First Resilience
* **Network Independence**: The core application—including transaction logging, debt amortization, category budget tracking, and local JSON backups—must function with **100% operational capability offline**.
* **Graceful Degradation**: Network-dependent features (e.g., real-time currency exchange rates) must automatically fallback to cached rates and clearly communicate connection status to the user.

---

## Article V: Amendment & Governance

1. Any modification to this Constitution requires explicit consensus, full architectural evaluation, and documentation in SpecKit.
2. Every feature delivery in `.specify/tasks.md` and `.specify/specs/` must reference and conform to the Articles herein.
