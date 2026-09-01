import '../models/debt.dart';

enum PayoffStrategy { snowball, avalanche }

class DebtPayoffResult {
  final PayoffStrategy strategy;
  final int totalMonths;
  final double totalInterestPaid;
  final double totalAmountPaid;
  final List<String> payoffOrder;

  DebtPayoffResult({
    required this.strategy,
    required this.totalMonths,
    required this.totalInterestPaid,
    required this.totalAmountPaid,
    required this.payoffOrder,
  });
}

class DebtCalculator {
  static DebtPayoffResult calculatePayoff({
    required List<DebtModel> debts,
    required double extraMonthlyBudget,
    required PayoffStrategy strategy,
  }) {
    // Filter to debts owed by user with balance > 0
    List<DebtModel> activeDebts = debts
        .where((d) => d.isOwedByMe && d.currentBalance > 0)
        .map((d) => d.copyWith())
        .toList();

    if (activeDebts.isEmpty) {
      return DebtPayoffResult(
        strategy: strategy,
        totalMonths: 0,
        totalInterestPaid: 0.0,
        totalAmountPaid: 0.0,
        payoffOrder: [],
      );
    }

    // Sort based on strategy
    if (strategy == PayoffStrategy.snowball) {
      // Lowest balance first
      activeDebts.sort((a, b) => a.currentBalance.compareTo(b.currentBalance));
    } else {
      // Highest APR first
      activeDebts.sort((a, b) => b.apr.compareTo(a.apr));
    }

    List<String> payoffOrder = [];
    double totalInterestPaid = 0.0;
    double totalAmountPaid = 0.0;
    int monthCount = 0;

    // Deep copy working balances
    List<_WorkingDebt> working = activeDebts.map((d) => _WorkingDebt(d)).toList();

    // Max 30 years safety loop (360 months)
    while (working.any((w) => w.balance > 0) && monthCount < 360) {
      monthCount++;
      double availableExtra = extraMonthlyBudget;

      // 1. Pay minimums and accrue interest on all active debts
      for (var w in working) {
        if (w.balance <= 0) continue;

        double monthlyInterestRate = (w.apr / 100.0) / 12.0;
        double monthlyInterest = w.balance * monthlyInterestRate;
        totalInterestPaid += monthlyInterest;
        w.balance += monthlyInterest;

        double minPayment = w.minPayment;
        // Safety guard: if minPayment is 0, set default minimum payment as 2% of balance
        if (minPayment <= 0) {
          minPayment = w.balance * 0.02;
          if (minPayment < 10) minPayment = 10;
        }

        if (minPayment > w.balance) minPayment = w.balance;

        w.balance -= minPayment;
        totalAmountPaid += minPayment;

        if (w.balance <= 0 && !payoffOrder.contains(w.title)) {
          payoffOrder.add(w.title);
        }
      }

      // 2. Apply extra budget to target debt (first active in sorted list)
      for (var w in working) {
        if (w.balance <= 0) continue;

        if (availableExtra > 0) {
          double extraPayment = availableExtra;
          if (extraPayment > w.balance) extraPayment = w.balance;

          w.balance -= extraPayment;
          availableExtra -= extraPayment;
          totalAmountPaid += extraPayment;

          if (w.balance <= 0 && !payoffOrder.contains(w.title)) {
            payoffOrder.add(w.title);
          }
        }
        break; // Only apply extra to highest priority target debt
      }
    }

    return DebtPayoffResult(
      strategy: strategy,
      totalMonths: monthCount,
      totalInterestPaid: totalInterestPaid,
      totalAmountPaid: totalAmountPaid,
      payoffOrder: payoffOrder,
    );
  }
}

class _WorkingDebt {
  final String title;
  double balance;
  final double apr;
  final double minPayment;

  _WorkingDebt(DebtModel debt)
      : title = debt.title,
        balance = debt.currentBalance,
        apr = debt.apr,
        minPayment = debt.minMonthlyPayment;
}
