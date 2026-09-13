import 'package:flutter_test/flutter_test.dart';
import 'package:expense_debt_manager/models/gold_silver_rate.dart';
import 'package:expense_debt_manager/services/gold_silver_service.dart';

void main() {
  group('GoldSilverRate & Service Tests', () {
    test('GoldSilverRate.fromJson parses FENEGOSIDA fine gold correctly', () {
      final json = {
        'id': 250,
        'rateType': 'छापावाल सुन (१ तोला)',
        'todayBaseRatePerGram': 302200.0,
        'yestardayBaseRatePerGram': 301000.0,
        'todayDate': '2026-09-13T04:42:30.537+00:00',
        'yestardayDate': '2026-09-11T04:48:30.051+00:00',
      };

      final rate = GoldSilverRate.fromJson(json);

      expect(rate.id, 250);
      expect(rate.metalType, 'gold');
      expect(rate.unit, '1 tola');
      expect(rate.todayRate, 302200.0);
      expect(rate.yesterdayRate, 301000.0);
      expect(rate.changeAmount, 1200.0);
      expect(rate.isUp, isTrue);
      expect(rate.isDown, isFalse);
      expect(rate.changePercent, closeTo(0.398, 0.01));
    });

    test('GoldSilverRate.fromJson parses silver 10 gram correctly', () {
      final json = {
        'id': 249,
        'rateType': 'असली चाँदी दर (१० ग्राम)',
        'todayBaseRatePerGram': 3995.5,
        'yestardayBaseRatePerGram': 3944.0,
      };

      final rate = GoldSilverRate.fromJson(json);

      expect(rate.id, 249);
      expect(rate.metalType, 'silver');
      expect(rate.unit, '10 gram');
      expect(rate.todayRate, 3995.5);
      expect(rate.yesterdayRate, 3944.0);
      expect(rate.changeAmount, closeTo(51.5, 0.01));
      expect(rate.isUp, isTrue);
    });

    test('GoldSilverService.calculateTotal computes accurate tola pricing with wastage and making', () {
      // 2 Tolas of Gold at 300,000/tola with Rs 5,000 making and 5% wastage
      // Base: 2 * 300,000 = 600,000
      // Wastage: 600,000 * 5% = 30,000
      // Making: 5,000
      // Total: 635,000
      final total = GoldSilverService.calculateTotal(
        ratePerTola: 300000.0,
        quantity: 2.0,
        unit: 'tola',
        makingCharges: 5000.0,
        wastagePercent: 5.0,
      );

      expect(total, 635000.0);
    });

    test('GoldSilverService.calculateTotal handles Gram conversion properly', () {
      // 11.6638 grams is exactly 1 tola
      final total = GoldSilverService.calculateTotal(
        ratePerTola: 300000.0,
        quantity: 11.6638,
        unit: 'gram',
        makingCharges: 0.0,
        wastagePercent: 0.0,
      );

      expect(total, closeTo(300000.0, 1.0));
    });

    test('GoldSilverService.calculateTotal handles Lal conversion properly', () {
      // 100 Lal is exactly 1 tola
      final total = GoldSilverService.calculateTotal(
        ratePerTola: 300000.0,
        quantity: 100.0,
        unit: 'lal',
        makingCharges: 0.0,
        wastagePercent: 0.0,
      );

      expect(total, 300000.0);
    });

    test('GoldSilverService provides robust offline fallback rates', () {
      final fallbacks = GoldSilverService.fallbackRates;
      expect(fallbacks.length, 4);

      final goldTola = fallbacks.firstWhere((r) => r.metalType == 'gold' && r.unit == '1 tola');
      expect(goldTola.todayRate, greaterThan(200000));

      final silverTola = fallbacks.firstWhere((r) => r.metalType == 'silver' && r.unit == '1 tola');
      expect(silverTola.todayRate, greaterThan(3000));
    });
  });
}
