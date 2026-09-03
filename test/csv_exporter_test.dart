import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_debt_manager/models/transaction.dart';
import 'package:expense_debt_manager/models/firm_profile.dart';
import 'package:expense_debt_manager/utils/csv_exporter.dart';

void main() {
  group('CsvExporter Tests', () {
    test('generateTransactionCsv filters transactions according to dateRange', () async {
      final firm = FirmProfileModel(
        name: 'Test Firm',
        taxId: 'PAN-999',
        address: 'Test City',
        phone: '12345',
      );

      final t1 = TransactionModel(
        id: 'tx-1',
        title: 'Old Transaction',
        amount: 100,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        date: DateTime(2026, 1, 1),
      );

      final t2 = TransactionModel(
        id: 'tx-2',
        title: 'Recent Transaction',
        amount: 250,
        type: TransactionType.income,
        categoryId: 'cat_income',
        date: DateTime(2026, 8, 15),
      );

      final file = await CsvExporter.generateTransactionCsv(
        transactions: [t1, t2],
        firm: firm,
        dateRange: DateTimeRange(
          start: DateTime(2026, 8, 1),
          end: DateTime(2026, 8, 31),
        ),
      );

      final content = await file.readAsString();
      expect(content.contains('Recent Transaction'), isTrue);
      expect(content.contains('Old Transaction'), isFalse);
    });
  });
}
