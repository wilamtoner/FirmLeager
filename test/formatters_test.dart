import 'package:flutter_test/flutter_test.dart';
import 'package:expense_debt_manager/utils/formatters.dart';

void main() {
  group('Formatters Tests', () {
    test('currency formats dollar amount with two decimal places', () {
      expect(Formatters.currency(1234.5), '\$1,234.50');
      expect(Formatters.currency(0), '\$0.00');
      expect(Formatters.currency(99.99), '\$99.99');
    });

    test('currency formats with custom currency symbols dynamically', () {
      expect(Formatters.currency(5000, 'Rs'), 'Rs5,000.00');
      expect(Formatters.currency(120.5, '€'), '€120.50');
      expect(Formatters.currency(750, '₹'), '₹750.00');
      expect(Formatters.currency(1000, '£'), '£1,000.00');
      expect(Formatters.currency(0, 'Rs'), 'Rs0.00');
      expect(Formatters.currency(15173.08, ''), '15,173.08');
    });

    test('number formats numbers with thousand separators and 2 decimal places', () {
      expect(Formatters.number(15173.08), '15,173.08');
      expect(Formatters.number(0), '0.00');
      expect(Formatters.number(1234567.89), '1,234,567.89');
    });

    test('date formats DateTime in MMM dd, yyyy format', () {
      final date = DateTime(2026, 9, 3);
      expect(Formatters.date(date), 'Sep 03, 2026');
    });
  });
}
