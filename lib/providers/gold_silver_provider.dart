import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gold_silver_rate.dart';
import '../services/gold_silver_service.dart';

class GoldSilverState {
  final List<GoldSilverRate> rates;
  final bool isLoading;
  final bool isLive;
  final DateTime lastUpdated;
  final String? errorMessage;
  final String selectedUnit; // '1 tola' or '10 gram'

  const GoldSilverState({
    required this.rates,
    required this.isLoading,
    required this.isLive,
    required this.lastUpdated,
    this.errorMessage,
    this.selectedUnit = '1 tola',
  });

  GoldSilverState copyWith({
    List<GoldSilverRate>? rates,
    bool? isLoading,
    bool? isLive,
    DateTime? lastUpdated,
    String? errorMessage,
    String? selectedUnit,
  }) {
    return GoldSilverState(
      rates: rates ?? this.rates,
      isLoading: isLoading ?? this.isLoading,
      isLive: isLive ?? this.isLive,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      errorMessage: errorMessage,
      selectedUnit: selectedUnit ?? this.selectedUnit,
    );
  }

  GoldSilverRate? getRate(String metal, String unit) {
    try {
      return rates.firstWhere(
        (r) => r.metalType == metal && r.unit == unit,
      );
    } catch (_) {
      return null;
    }
  }
}

class GoldSilverNotifier extends StateNotifier<GoldSilverState> {
  final GoldSilverService _service;

  GoldSilverNotifier(this._service)
      : super(GoldSilverState(
          rates: GoldSilverService.fallbackRates,
          isLoading: false,
          isLive: false,
          lastUpdated: DateTime.now(),
        )) {
    loadRates();
  }

  Future<void> loadRates() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _service.fetchRates();
    state = state.copyWith(
      rates: result['rates'] as List<GoldSilverRate>,
      isLive: result['isLive'] as bool,
      errorMessage: result['error'] as String?,
      lastUpdated: DateTime.now(),
      isLoading: false,
    );
  }

  Future<void> refresh() async {
    await loadRates();
  }

  void setSelectedUnit(String unit) {
    state = state.copyWith(selectedUnit: unit);
  }
}

final goldSilverServiceProvider = Provider<GoldSilverService>((ref) {
  return GoldSilverService();
});

final goldSilverProvider =
    StateNotifierProvider<GoldSilverNotifier, GoldSilverState>((ref) {
  final service = ref.watch(goldSilverServiceProvider);
  return GoldSilverNotifier(service);
});
