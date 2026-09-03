import 'package:flutter_test/flutter_test.dart';
import 'package:expense_debt_manager/utils/formatters.dart';

void main() {
  group('Formatters Tests', () {
    test('currency formats dollar amount with two decimal places', () {
      expect(Formatters.currency(1234.5), '\$1,234.50');
      expect(Formatters.currency(0), '\$0.00');
      expect(Formatters.currency(99.99), '\$99.99');
    });

    test('date formats DateTime in MMM dd, yyyy format', () {
      final date = DateTime(2026, 9, 3);
      expect(Formatters.date(date), 'Sep 03, 2026');
    });
  });
}
