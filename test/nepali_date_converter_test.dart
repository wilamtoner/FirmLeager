import 'package:flutter_test/flutter_test.dart';
import 'package:expense_debt_manager/utils/nepali_date_helper.dart';

void main() {
  group('NepaliDateHelper Tests', () {
    test('convertAdToBs converts anchor date accurately', () {
      final nowAd = DateTime.now();
      final nowBs = NepaliDateHelper.convertAdToBs(nowAd);
      final backAd = NepaliDateHelper.convertBsToAd(nowBs.year, nowBs.month, nowBs.day);
      expect(backAd.adEquivalent.year, nowAd.year);
      expect(backAd.adEquivalent.month, nowAd.month);
      expect(backAd.adEquivalent.day, nowAd.day);
    });

    test('convertBsToAd converts 2083-05-27 BS back to 2026-09-12 AD', () {
      final details = NepaliDateHelper.convertBsToAd(2083, 5, 27);

      expect(details.adEquivalent.year, 2026);
      expect(details.adEquivalent.month, 9);
      expect(details.adEquivalent.day, 12);
      expect(details.year, 2083);
      expect(details.month, 5);
      expect(details.day, 27);
    });

    test('getDaysInBsMonth returns valid calendar month day counts', () {
      // In BS calendar, months typically have 29 to 32 days
      final daysBhadra2083 = NepaliDateHelper.getDaysInBsMonth(2083, 5);
      expect(daysBhadra2083, inInclusiveRange(29, 32));

      final daysBaishakh2083 = NepaliDateHelper.getDaysInBsMonth(2083, 1);
      expect(daysBaishakh2083, inInclusiveRange(30, 32));
    });

    test('calculateDifference accurately computes years, months, and days', () {
      final date1 = DateTime(2024, 1, 15);
      final date2 = DateTime(2026, 3, 20);

      final diff = NepaliDateHelper.calculateDifference(date1, date2);

      expect(diff.years, 2);
      expect(diff.months, 2);
      expect(diff.days, 5);
      expect(diff.totalDays, greaterThan(700));
      expect(diff.summary, contains('2 years, 2 months, 5 days'));
    });

    test('calculateDifference handles reversed date ordering gracefully', () {
      final date1 = DateTime(2026, 9, 13);
      final date2 = DateTime(2025, 9, 13);

      final diff = NepaliDateHelper.calculateDifference(date1, date2);

      expect(diff.years, 1);
      expect(diff.months, 0);
      expect(diff.days, 0);
      expect(diff.totalDays, 365);
    });
  });
}
