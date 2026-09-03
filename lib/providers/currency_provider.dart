import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/currency_service.dart';

class CurrencyConverterState {
  final double inputAmount;
  final String fromCurrency;
  final String toCurrency;
  final double convertedAmount;
  final DateTime? lastUpdated;
  final bool isLive;
  final bool isLoading;

  const CurrencyConverterState({
    required this.inputAmount,
    required this.fromCurrency,
    required this.toCurrency,
    required this.convertedAmount,
    this.lastUpdated,
    this.isLive = false,
    this.isLoading = false,
  });

  CurrencyConverterState copyWith({
    double? inputAmount,
    String? fromCurrency,
    String? toCurrency,
    double? convertedAmount,
    DateTime? lastUpdated,
    bool? isLive,
    bool? isLoading,
  }) {
    return CurrencyConverterState(
      inputAmount: inputAmount ?? this.inputAmount,
      fromCurrency: fromCurrency ?? this.fromCurrency,
      toCurrency: toCurrency ?? this.toCurrency,
      convertedAmount: convertedAmount ?? this.convertedAmount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isLive: isLive ?? this.isLive,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final currencyServiceProvider = Provider<CurrencyService>((ref) {
  return CurrencyService();
});

final currencyConverterProvider =
    StateNotifierProvider<CurrencyConverterNotifier, CurrencyConverterState>((ref) {
  final service = ref.watch(currencyServiceProvider);
  return CurrencyConverterNotifier(service);
});

class CurrencyConverterNotifier extends StateNotifier<CurrencyConverterState> {
  final CurrencyService _service;

  CurrencyConverterNotifier(this._service)
      : super(const CurrencyConverterState(
          inputAmount: 100.0,
          fromCurrency: 'USD',
          toCurrency: 'NPR',
          convertedAmount: 0.0,
        )) {
    _initRates();
  }

  Future<void> _initRates() async {
    state = state.copyWith(isLoading: true);
    await _service.fetchLiveRates();
    _recalculate();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _service.fetchLiveRates();
    _recalculate();
  }

  void setAmount(double amount) {
    state = state.copyWith(inputAmount: amount);
    _recalculate();
  }

  void setFromCurrency(String code) {
    state = state.copyWith(fromCurrency: code);
    _recalculate();
  }

  void setToCurrency(String code) {
    state = state.copyWith(toCurrency: code);
    _recalculate();
  }

  void swap() {
    final oldFrom = state.fromCurrency;
    final oldTo = state.toCurrency;
    state = state.copyWith(fromCurrency: oldTo, toCurrency: oldFrom);
    _recalculate();
  }

  void _recalculate() {
    final converted = _service.convert(
      amount: state.inputAmount,
      from: state.fromCurrency,
      to: state.toCurrency,
    );
    state = state.copyWith(
      convertedAmount: converted,
      lastUpdated: _service.lastUpdated,
      isLive: _service.isLive,
      isLoading: false,
    );
  }
}
