import 'package:flutter_test/flutter_test.dart';
import 'package:expense_debt_manager/services/currency_service.dart';

void main() {
  group('CurrencyService & Conversion Tests', () {
    final mockRates = {
      'USD': 1.0,
      'EUR': 0.86,
      'GBP': 0.74,
      'INR': 94.89,
      'NPR': 151.83,
      'JPY': 159.0,
      'CAD': 1.38,
      'AUD': 1.40,
    };

    test('convert returns identical amount when source and target currencies match', () {
      final service = CurrencyService(initialRates: mockRates);
      final result = service.convert(amount: 150.0, from: 'USD', to: 'USD');
      expect(result, 150.0);
    });

    test('convert calculates base USD to target currency accurately', () {
      final service = CurrencyService(initialRates: mockRates);
      // 100 USD -> 86 EUR
      final result = service.convert(amount: 100.0, from: 'USD', to: 'EUR');
      expect(result, closeTo(86.0, 0.001));
    });

    test('convert performs cross-currency conversion triangulating through base', () {
      final service = CurrencyService(initialRates: mockRates);
      // 100 EUR -> GBP = 100 * (0.74 / 0.86) = 86.0465...
      final result = service.convert(amount: 100.0, from: 'EUR', to: 'GBP');
      const expected = 100.0 * (0.74 / 0.86);
      expect(result, closeTo(expected, 0.001));
    });

    test('convert calculates South Asian INR to NPR conversion accurately', () {
      final service = CurrencyService(initialRates: mockRates);
      // 1000 INR -> NPR = 1000 * (151.83 / 94.89) = ~1600.06
      final result = service.convert(amount: 1000.0, from: 'INR', to: 'NPR');
      const expected = 1000.0 * (151.83 / 94.89);
      expect(result, closeTo(expected, 0.01));
    });

    test('convert returns 0.0 when input amount is 0', () {
      final service = CurrencyService(initialRates: mockRates);
      final result = service.convert(amount: 0.0, from: 'USD', to: 'JPY');
      expect(result, 0.0);
    });

    test('inverse conversion satisfies mathematical reciprocity', () {
      final service = CurrencyService(initialRates: mockRates);
      final aToB = service.convert(amount: 1.0, from: 'USD', to: 'CAD');
      final bToA = service.convert(amount: aToB, from: 'CAD', to: 'USD');
      expect(bToA, closeTo(1.0, 0.0001));
    });

    test('CurrencyService provides robust offline fallback rates for common currencies', () {
      final service = CurrencyService();
      expect(service.rates.containsKey('USD'), isTrue);
      expect(service.rates.containsKey('EUR'), isTrue);
      expect(service.rates.containsKey('GBP'), isTrue);
      expect(service.rates.containsKey('INR'), isTrue);
      expect(service.rates.containsKey('NPR'), isTrue);
      expect(service.rates.containsKey('JPY'), isTrue);
    });
  });
}
