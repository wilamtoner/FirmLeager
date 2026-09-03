import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyInfo {
  final String code;
  final String name;
  final String symbol;
  final String flagEmoji;

  const CurrencyInfo({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flagEmoji,
  });
}

class CurrencyService {
  static const String endpoint = 'https://open.er-api.com/v6/latest/USD';

  static const List<CurrencyInfo> supportedCurrencies = [
    CurrencyInfo(code: 'USD', name: 'US Dollar', symbol: '\$', flagEmoji: '🇺🇸'),
    CurrencyInfo(code: 'EUR', name: 'Euro', symbol: '€', flagEmoji: '🇪🇺'),
    CurrencyInfo(code: 'GBP', name: 'British Pound', symbol: '£', flagEmoji: '🇬🇧'),
    CurrencyInfo(code: 'INR', name: 'Indian Rupee', symbol: '₹', flagEmoji: '🇮🇳'),
    CurrencyInfo(code: 'NPR', name: 'Nepalese Rupee', symbol: 'Rs', flagEmoji: '🇳🇵'),
    CurrencyInfo(code: 'JPY', name: 'Japanese Yen', symbol: '¥', flagEmoji: '🇯🇵'),
    CurrencyInfo(code: 'CAD', name: 'Canadian Dollar', symbol: 'CA\$', flagEmoji: '🇨🇦'),
    CurrencyInfo(code: 'AUD', name: 'Australian Dollar', symbol: 'AU\$', flagEmoji: '🇦🇺'),
    CurrencyInfo(code: 'CHF', name: 'Swiss Franc', symbol: 'CHF', flagEmoji: '🇨🇭'),
    CurrencyInfo(code: 'CNY', name: 'Chinese Yuan', symbol: '¥', flagEmoji: '🇨🇳'),
    CurrencyInfo(code: 'AED', name: 'UAE Dirham', symbol: 'AED', flagEmoji: '🇦🇪'),
    CurrencyInfo(code: 'SAR', name: 'Saudi Riyal', symbol: 'SAR', flagEmoji: '🇸🇦'),
    CurrencyInfo(code: 'QAR', name: 'Qatari Riyal', symbol: 'QAR', flagEmoji: '🇶🇦'),
    CurrencyInfo(code: 'SGD', name: 'Singapore Dollar', symbol: 'S\$', flagEmoji: '🇸🇬'),
    CurrencyInfo(code: 'MYR', name: 'Malaysian Ringgit', symbol: 'RM', flagEmoji: '🇲🇾'),
    CurrencyInfo(code: 'THB', name: 'Thai Baht', symbol: '฿', flagEmoji: '🇹🇭'),
    CurrencyInfo(code: 'KRW', name: 'South Korean Won', symbol: '₩', flagEmoji: '🇰🇷'),
  ];

  static const Map<String, double> defaultFallbackRates = {
    'USD': 1.0,
    'EUR': 0.863,
    'GBP': 0.742,
    'INR': 94.89,
    'NPR': 151.84,
    'JPY': 159.09,
    'CAD': 1.386,
    'AUD': 1.397,
    'CHF': 0.813,
    'CNY': 6.736,
    'AED': 3.673,
    'SAR': 3.75,
    'QAR': 3.64,
    'SGD': 1.272,
    'MYR': 4.043,
    'THB': 33.21,
    'KRW': 1361.14,
  };

  Map<String, double> _rates;
  DateTime? _lastUpdated;
  bool _isLive = false;

  CurrencyService({Map<String, double>? initialRates})
      : _rates = initialRates ?? Map.from(defaultFallbackRates);

  Map<String, double> get rates => Map.unmodifiable(_rates);
  DateTime? get lastUpdated => _lastUpdated;
  bool get isLive => _isLive;

  Future<Map<String, double>> fetchLiveRates() async {
    try {
      final response = await http.get(Uri.parse(endpoint)).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] == 'success' && data['rates'] is Map) {
          final rawRates = data['rates'] as Map<String, dynamic>;
          final parsedRates = <String, double>{};
          rawRates.forEach((key, val) {
            if (val is num) {
              parsedRates[key] = val.toDouble();
            }
          });

          if (parsedRates.isNotEmpty) {
            _rates = parsedRates;
            _isLive = true;
            if (data['time_last_update_utc'] != null) {
              try {
                _lastUpdated = DateTime.parse(data['time_last_update_utc']);
              } catch (_) {
                _lastUpdated = DateTime.now();
              }
            } else {
              _lastUpdated = DateTime.now();
            }
          }
        }
      }
    } catch (_) {
      // Offline fallback: continue using current cached/fallback rates
      _isLive = false;
    }
    return _rates;
  }

  double convert({
    required double amount,
    required String from,
    required String to,
  }) {
    if (amount == 0.0) return 0.0;
    if (from == to) return amount;

    final rateFrom = _rates[from] ?? defaultFallbackRates[from] ?? 1.0;
    final rateTo = _rates[to] ?? defaultFallbackRates[to] ?? 1.0;

    if (rateFrom == 0.0) return 0.0;

    // Convert from source to base USD, then base USD to target
    return amount * (rateTo / rateFrom);
  }

  static CurrencyInfo getInfo(String code) {
    return supportedCurrencies.firstWhere(
      (c) => c.code == code,
      orElse: () => CurrencyInfo(code: code, name: code, symbol: code, flagEmoji: '🌐'),
    );
  }
}
