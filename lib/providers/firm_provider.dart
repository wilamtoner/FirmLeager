import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/firm_profile.dart';

final firmProvider = StateNotifierProvider<FirmNotifier, FirmProfileModel>((ref) {
  return FirmNotifier();
});

class FirmNotifier extends StateNotifier<FirmProfileModel> {
  FirmNotifier()
      : super(
          FirmProfileModel(
            name: 'DEMO FIRM TRADERS PVT. LTD.',
            taxId: 'PAN-609123847',
            address: 'New Road, Kathmandu',
            phone: '+977-9800000000',
            currencySymbol: 'Rs.',
          ),
        );

  void updateFirm({
    String? name,
    String? taxId,
    String? address,
    String? phone,
    String? currencySymbol,
  }) {
    state = state.copyWith(
      name: name,
      taxId: taxId,
      address: address,
      phone: phone,
      currencySymbol: currencySymbol,
    );
  }
}
