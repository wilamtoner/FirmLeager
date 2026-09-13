import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/gold_silver_rate.dart';

class GoldSilverService {
  static const String endpoint = 'https://api.fenegosida.org/api/website/v1/Dashboard/today';

  // Standard Nepali Gold & Silver conversion constants
  static const double gramsPerTola = 11.6638;
  static const double lalPerTola = 100.0;

  // Cached rates in memory
  static List<GoldSilverRate>? _cachedRates;

  // Default fallback rates for offline resilience
  static List<GoldSilverRate> get fallbackRates {
    final now = DateTime.now();
    final yest = now.subtract(const Duration(days: 1));
    return [
      GoldSilverRate(
        id: 250,
        metalType: 'gold',
        nepaliTitle: 'छापावाल सुन (१ तोला)',
        englishTitle: 'Fine Gold (9999) 1 Tola',
        unit: '1 tola',
        todayRate: 302200.0,
        yesterdayRate: 301000.0,
        todayDate: now,
        yesterdayDate: yest,
      ),
      GoldSilverRate(
        id: 251,
        metalType: 'gold',
        nepaliTitle: 'छापावाल सुन (१० ग्राम)',
        englishTitle: 'Fine Gold (9999) 10 Gram',
        unit: '10 gram',
        todayRate: 259090.0,
        yesterdayRate: 258060.0,
        todayDate: now,
        yesterdayDate: yest,
      ),
      GoldSilverRate(
        id: 248,
        metalType: 'silver',
        nepaliTitle: 'असली चाँदी दर (१ तोला)',
        englishTitle: 'Pure Silver 1 Tola',
        unit: '1 tola',
        todayRate: 4660.0,
        yesterdayRate: 4600.0,
        todayDate: now,
        yesterdayDate: yest,
      ),
      GoldSilverRate(
        id: 249,
        metalType: 'silver',
        nepaliTitle: 'असली चाँदी दर (१० ग्राम)',
        englishTitle: 'Pure Silver 10 Gram',
        unit: '10 gram',
        todayRate: 3995.5,
        yesterdayRate: 3944.0,
        todayDate: now,
        yesterdayDate: yest,
      ),
    ];
  }

  /// Fetches live rates from FENEGOSIDA, falling back to cached or default rates on failure
  Future<Map<String, dynamic>> fetchRates() async {
    try {
      final uri = Uri.parse(endpoint);
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          final List<GoldSilverRate> rates = [];
          for (var item in decoded) {
            if (item is Map<String, dynamic>) {
              rates.add(GoldSilverRate.fromJson(item));
            }
          }

          if (rates.isNotEmpty) {
            _cachedRates = rates;
            return {
              'isLive': true,
              'rates': rates,
              'error': null,
            };
          }
        }
      }
    } catch (_) {
      // Ignore network errors and fall back gracefully
    }

    // Return cached or offline fallback rates
    return {
      'isLive': false,
      'rates': _cachedRates ?? fallbackRates,
      'error': 'Operating in offline mode. Showing cached reference rates.',
    };
  }

  /// Calculates total price of gold/silver in NPR
  static double calculateTotal({
    required double ratePerTola,
    required double quantity,
    required String unit, // 'tola', 'gram', 'lal'
    double makingCharges = 0.0,
    double wastagePercent = 0.0,
  }) {
    if (quantity <= 0 || ratePerTola <= 0) return 0.0;

    double tolaWeight = 0.0;
    switch (unit.toLowerCase()) {
      case 'tola':
        tolaWeight = quantity;
        break;
      case 'gram':
      case 'g':
      case 'gms':
        tolaWeight = quantity / gramsPerTola;
        break;
      case 'lal':
        tolaWeight = quantity / lalPerTola;
        break;
      default:
        tolaWeight = quantity;
    }

    final double baseCost = tolaWeight * ratePerTola;
    final double wastageCost = baseCost * (wastagePercent / 100.0);
    return baseCost + wastageCost + makingCharges;
  }
}
