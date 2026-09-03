import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_debt_manager/models/recurring_transaction.dart';
import 'package:expense_debt_manager/models/transaction.dart';
import 'package:expense_debt_manager/models/category.dart';
import 'package:expense_debt_manager/models/debt.dart';

void main() {
  group('RecurringTransactionModel Tests', () {
    test('serialization roundtrip and nextDate calculation', () {
      final startDate = DateTime(2026, 1, 15);
      final r = RecurringTransactionModel(
        id: 'rec-1',
        title: 'Office Internet',
        amount: 2500.0,
        type: TransactionType.expense,
        categoryId: 'cat_utilities',
        frequency: RecurringFrequency.monthly,
        startDate: startDate,
        nextDueDate: startDate,
        notes: 'ISP Fibernet',
      );

      final map = r.toMap();
      expect(map['id'], 'rec-1');
      expect(map['frequency'], 'monthly');
      expect(map['isActive'], 1);

      final fromMap = RecurringTransactionModel.fromMap(map);
      expect(fromMap.id, r.id);
      expect(fromMap.frequency, RecurringFrequency.monthly);

      // Monthly nextDate should advance to Feb 15
      final next = r.calculateNextDate(startDate);
      expect(next.year, 2026);
      expect(next.month, 2);
      expect(next.day, 15);

      // Weekly nextDate should advance 7 days
      final weeklyR = r.copyWith(frequency: RecurringFrequency.weekly);
      final weeklyNext = weeklyR.calculateNextDate(startDate);
      expect(weeklyNext.day, 22);
    });
  });

  group('Backup Data Structure Tests', () {
    test('JSON backup structure encoding and validation', () {
      final sampleBackup = {
        'appName': 'FirmLedger',
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'categories': [
          CategoryModel(id: 'c1', name: 'Rent', colorHex: 0xFF123456, budgetLimit: 1000).toMap(),
        ],
        'transactions': [
          TransactionModel(
            id: 't1',
            title: 'Office Chair',
            amount: 120,
            type: TransactionType.expense,
            categoryId: 'c1',
            date: DateTime(2026, 8, 1),
          ).toMap(),
        ],
        'debts': [
          DebtModel(
            id: 'd1',
            title: 'Vendor Credit',
            partyName: 'Supplier X',
            isOwedByMe: true,
            originalAmount: 500,
            currentBalance: 500,
            apr: 0,
            minMonthlyPayment: 100,
            dueDate: DateTime(2026, 10, 1),
          ).toMap(),
        ],
        'recurring': [],
      };

      final encoded = jsonEncode(sampleBackup);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;

      expect(decoded['appName'], 'FirmLedger');
      expect((decoded['categories'] as List).length, 1);
      expect((decoded['transactions'] as List).length, 1);
      expect((decoded['debts'] as List).length, 1);
    });
  });
}
