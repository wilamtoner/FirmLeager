import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import 'transaction_provider.dart';
import 'debt_provider.dart';
import 'category_provider.dart';

class DashboardSummary {
  final double totalIncome;
  final double totalExpenses;
  final double totalDebtsOwed;
  final double totalDebtsOwedToMe;
  final double netWorth;
  final double debtToIncomeRatio;
  final Map<String, double> categoryExpenses;

  DashboardSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalDebtsOwed,
    required this.totalDebtsOwedToMe,
    required this.netWorth,
    required this.debtToIncomeRatio,
    required this.categoryExpenses,
  });
}

final dashboardProvider = Provider<DashboardSummary>((ref) {
  final transactions = ref.watch(transactionProvider);
  final debts = ref.watch(debtProvider);

  double totalIncome = 0.0;
  double totalExpenses = 0.0;
  Map<String, double> categoryExpenses = {};

  for (var t in transactions) {
    if (t.type == TransactionType.income) {
      totalIncome += t.amount;
    } else {
      totalExpenses += t.amount;
      categoryExpenses[t.categoryId] = (categoryExpenses[t.categoryId] ?? 0) + t.amount;
    }
  }

  double totalDebtsOwed = 0.0;
  double totalDebtsOwedToMe = 0.0;

  for (var d in debts) {
    if (d.isOwedByMe) {
      totalDebtsOwed += d.currentBalance;
    } else {
      totalDebtsOwedToMe += d.currentBalance;
    }
  }

  // Net Worth = (Cash/Assets + Money Owed to Me) - Debts Owed
  double netWorth = (totalIncome - totalExpenses + totalDebtsOwedToMe) - totalDebtsOwed;

  // DTI Ratio = (Total Liabilities / Total Monthly Income) * 100
  double dtiRatio = totalIncome > 0 ? (totalDebtsOwed / totalIncome) * 100.0 : 0.0;

  return DashboardSummary(
    totalIncome: totalIncome,
    totalExpenses: totalExpenses,
    totalDebtsOwed: totalDebtsOwed,
    totalDebtsOwedToMe: totalDebtsOwedToMe,
    netWorth: netWorth,
    debtToIncomeRatio: dtiRatio,
    categoryExpenses: categoryExpenses,
  );
});

class CategoryBudgetStatus {
  final CategoryModel category;
  final double spentAmount;
  final double budgetLimit;
  final double percentage;
  final bool isOverBudget;
  final bool isNearBudget;

  CategoryBudgetStatus({
    required this.category,
    required this.spentAmount,
    required this.budgetLimit,
    required this.percentage,
    required this.isOverBudget,
    required this.isNearBudget,
  });
}

final categoryBudgetProvider = Provider<List<CategoryBudgetStatus>>((ref) {
  final transactions = ref.watch(transactionProvider);
  final categories = ref.watch(categoryProvider);

  final now = DateTime.now();
  final currentMonthStart = DateTime(now.year, now.month, 1);
  final currentMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  final monthExpenses = transactions.where((t) =>
      t.type == TransactionType.expense &&
      (t.date.isAfter(currentMonthStart) || t.date.isAtSameMomentAs(currentMonthStart)) &&
      (t.date.isBefore(currentMonthEnd) || t.date.isAtSameMomentAs(currentMonthEnd)));

  Map<String, double> spentByCategory = {};
  for (var t in monthExpenses) {
    spentByCategory[t.categoryId] = (spentByCategory[t.categoryId] ?? 0.0) + t.amount;
  }

  final List<CategoryBudgetStatus> list = [];
  for (var c in categories) {
    if (c.budgetLimit > 0) {
      final spent = spentByCategory[c.id] ?? 0.0;
      final pct = (spent / c.budgetLimit) * 100.0;
      list.add(CategoryBudgetStatus(
        category: c,
        spentAmount: spent,
        budgetLimit: c.budgetLimit,
        percentage: pct,
        isOverBudget: spent > c.budgetLimit,
        isNearBudget: spent >= (c.budgetLimit * 0.8),
      ));
    }
  }

  return list;
});
