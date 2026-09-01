class FirmProfileModel {
  final String name;
  final String taxId; // PAN / VAT / GST Number
  final String address;
  final String phone;
  final String currencySymbol;

  FirmProfileModel({
    required this.name,
    required this.taxId,
    required this.address,
    required this.phone,
    this.currencySymbol = 'Rs.',
  });

  FirmProfileModel copyWith({
    String? name,
    String? taxId,
    String? address,
    String? phone,
    String? currencySymbol,
  }) {
    return FirmProfileModel(
      name: name ?? this.name,
      taxId: taxId ?? this.taxId,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'taxId': taxId,
      'address': address,
      'phone': phone,
      'currencySymbol': currencySymbol,
    };
  }

  factory FirmProfileModel.fromMap(Map<String, dynamic> map) {
    return FirmProfileModel(
      name: map['name'] as String? ?? 'DEMO FIRM PVT. LTD.',
      taxId: map['taxId'] as String? ?? 'PAN-609123847',
      address: map['address'] as String? ?? 'Kathmandu, Nepal',
      phone: map['phone'] as String? ?? '+977-9800000000',
      currencySymbol: map['currencySymbol'] as String? ?? 'Rs.',
    );
  }
}
