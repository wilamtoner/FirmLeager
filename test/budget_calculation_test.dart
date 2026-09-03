import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_debt_manager/models/transaction.dart';
import 'package:expense_debt_manager/models/category.dart';
import 'package:expense_debt_manager/providers/transaction_provider.dart';
import 'package:expense_debt_manager/providers/category_provider.dart';
import 'package:expense_debt_manager/providers/dashboard_provider.dart';

void main() {
  group('Category Budget & Over-Budget Alert Tests', () {
    test('categoryBudgetProvider correctly flags over-budget and near-budget status', () {
      final now = DateTime.now();

      final categories = [
        CategoryModel(id: 'cat_rent', name: 'Rent', colorHex: 0xFF00FF00, budgetLimit: 1000.0),
        CategoryModel(id: 'cat_dining', name: 'Dining', colorHex: 0xFFFF0000, budgetLimit: 500.0),
        CategoryModel(id: 'cat_misc', name: 'Misc', colorHex: 0xFF0000FF, budgetLimit: 0.0), // No budget
      ];

      final transactions = [
        // Rent: $850 spent -> 85% (near budget)
        TransactionModel(
          id: 'tx-1',
          title: 'Apartment Rent',
          amount: 850.0,
          type: TransactionType.expense,
          categoryId: 'cat_rent',
          date: now,
        ),
        // Dining: $600 spent -> 120% (over budget)
        TransactionModel(
          id: 'tx-2',
          title: 'Dinner Party',
          amount: 600.0,
          type: TransactionType.expense,
          categoryId: 'cat_dining',
          date: now,
        ),
        // Income transaction should not count towards expense budget
        TransactionModel(
          id: 'tx-3',
          title: 'Client Payment',
          amount: 5000.0,
          type: TransactionType.income,
          categoryId: 'cat_rent',
          date: now,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          transactionProvider.overrideWith((ref) => TransactionNotifierMock(transactions)),
          categoryProvider.overrideWith((ref) => CategoryNotifierMock(categories)),
        ],
      );

      final budgetStatuses = container.read(categoryBudgetProvider);

      // Categories with budgetLimit == 0 should be excluded
      expect(budgetStatuses.length, 2);

      final rentStatus = budgetStatuses.firstWhere((b) => b.category.id == 'cat_rent');
      expect(rentStatus.spentAmount, 850.0);
      expect(rentStatus.budgetLimit, 1000.0);
      expect(rentStatus.percentage, 85.0);
      expect(rentStatus.isNearBudget, isTrue);
      expect(rentStatus.isOverBudget, isFalse);

      final diningStatus = budgetStatuses.firstWhere((b) => b.category.id == 'cat_dining');
      expect(diningStatus.spentAmount, 600.0);
      expect(diningStatus.budgetLimit, 500.0);
      expect(diningStatus.percentage, 120.0);
      expect(diningStatus.isNearBudget, isTrue);
      expect(diningStatus.isOverBudget, isTrue);
    });
  });
}

class TransactionNotifierMock extends StateNotifier<List<TransactionModel>> implements TransactionNotifier {
  TransactionNotifierMock(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class CategoryNotifierMock extends StateNotifier<List<CategoryModel>> implements CategoryNotifier {
  CategoryNotifierMock(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
