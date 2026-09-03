import 'package:flutter_test/flutter_test.dart';
import 'package:expense_debt_manager/models/debt.dart';
import 'package:expense_debt_manager/utils/debt_calculator.dart';

void main() {
  group('DebtCalculator Tests', () {
    test('calculatePayoff returns 0 months when active debts list is empty', () {
      final result = DebtCalculator.calculatePayoff(
        debts: [],
        extraMonthlyBudget: 100,
        strategy: PayoffStrategy.snowball,
      );

      expect(result.totalMonths, 0);
      expect(result.totalInterestPaid, 0.0);
      expect(result.totalAmountPaid, 0.0);
      expect(result.payoffOrder, isEmpty);
    });

    test('calculatePayoff ignores debts owed to me (assets)', () {
      final debts = [
        DebtModel(
          id: '1',
          title: 'Customer Loan',
          partyName: 'Customer A',
          isOwedByMe: false, // Owed to me
          originalAmount: 5000,
          currentBalance: 5000,
          apr: 0,
          minMonthlyPayment: 500,
          dueDate: DateTime.now().add(const Duration(days: 30)),
        ),
      ];

      final result = DebtCalculator.calculatePayoff(
        debts: debts,
        extraMonthlyBudget: 100,
        strategy: PayoffStrategy.snowball,
      );

      expect(result.totalMonths, 0);
      expect(result.payoffOrder, isEmpty);
    });

    test('Snowball strategy targets lowest balance debt first', () {
      final debts = [
        DebtModel(
          id: '1',
          title: 'Large Balance Low APR',
          partyName: 'Bank A',
          isOwedByMe: true,
          originalAmount: 10000,
          currentBalance: 8000,
          apr: 5.0,
          minMonthlyPayment: 200,
          dueDate: DateTime.now(),
        ),
        DebtModel(
          id: '2',
          title: 'Small Balance High APR',
          partyName: 'Card B',
          isOwedByMe: true,
          originalAmount: 1500,
          currentBalance: 1000,
          apr: 18.0,
          minMonthlyPayment: 50,
          dueDate: DateTime.now(),
        ),
      ];

      final result = DebtCalculator.calculatePayoff(
        debts: debts,
        extraMonthlyBudget: 200,
        strategy: PayoffStrategy.snowball,
      );

      expect(result.payoffOrder.isNotEmpty, isTrue);
      // Small Balance should be paid off first in snowball
      expect(result.payoffOrder.first, 'Small Balance High APR');
      expect(result.totalMonths, greaterThan(0));
      expect(result.totalAmountPaid, greaterThan(9000));
    });

    test('Avalanche strategy targets highest APR debt first', () {
      final debts = [
        DebtModel(
          id: '1',
          title: 'Low APR Debt',
          partyName: 'Creditor A',
          isOwedByMe: true,
          originalAmount: 3000,
          currentBalance: 2000,
          apr: 4.0,
          minMonthlyPayment: 100,
          dueDate: DateTime.now(),
        ),
        DebtModel(
          id: '2',
          title: 'High APR Debt',
          partyName: 'Creditor B',
          isOwedByMe: true,
          originalAmount: 5000,
          currentBalance: 4000,
          apr: 24.0,
          minMonthlyPayment: 100,
          dueDate: DateTime.now(),
        ),
      ];

      final result = DebtCalculator.calculatePayoff(
        debts: debts,
        extraMonthlyBudget: 150,
        strategy: PayoffStrategy.avalanche,
      );

      expect(result.payoffOrder.isNotEmpty, isTrue);
      // High APR should be prioritized in avalanche
      expect(result.payoffOrder.first, 'High APR Debt');
    });

    test('calculatePayoff with 0% APR incurs zero interest paid', () {
      final debts = [
        DebtModel(
          id: '1',
          title: 'Family Loan',
          partyName: 'Relative',
          isOwedByMe: true,
          originalAmount: 1000,
          currentBalance: 600,
          apr: 0.0,
          minMonthlyPayment: 200,
          dueDate: DateTime.now(),
        ),
      ];

      final result = DebtCalculator.calculatePayoff(
        debts: debts,
        extraMonthlyBudget: 0,
        strategy: PayoffStrategy.snowball,
      );

      expect(result.totalInterestPaid, 0.0);
      expect(result.totalAmountPaid, 600.0);
      expect(result.totalMonths, 3); // 600 / 200 = 3 months
    });
  });
}
