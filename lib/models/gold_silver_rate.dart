class GoldSilverRate {
  final int id;
  final String metalType; // 'gold' or 'silver'
  final String nepaliTitle;
  final String englishTitle;
  final String unit; // '1 tola' or '10 gram'
  final double todayRate;
  final double yesterdayRate;
  final DateTime? todayDate;
  final DateTime? yesterdayDate;

  const GoldSilverRate({
    required this.id,
    required this.metalType,
    required this.nepaliTitle,
    required this.englishTitle,
    required this.unit,
    required this.todayRate,
    required this.yesterdayRate,
    this.todayDate,
    this.yesterdayDate,
  });

  double get changeAmount => todayRate - yesterdayRate;

  double get changePercent =>
      yesterdayRate > 0 ? (changeAmount / yesterdayRate) * 100 : 0.0;

  bool get isUp => changeAmount > 0;
  bool get isDown => changeAmount < 0;

  factory GoldSilverRate.fromJson(Map<String, dynamic> json) {
    final rawType = (json['rateType'] ?? '').toString();
    final today = (json['todayBaseRatePerGram'] is num)
        ? (json['todayBaseRatePerGram'] as num).toDouble()
        : double.tryParse(json['todayBaseRatePerGram']?.toString() ?? '0') ?? 0.0;
    final yest = (json['yestardayBaseRatePerGram'] is num)
        ? (json['yestardayBaseRatePerGram'] as num).toDouble()
        : double.tryParse(json['yestardayBaseRatePerGram']?.toString() ?? '0') ?? 0.0;

    String metal = 'gold';
    String eng = 'Fine Gold (9999)';
    String nepali = 'छापावाल सुन';
    String unit = '1 tola';

    if (rawType.contains('चाँदी') || rawType.toLowerCase().contains('silver')) {
      metal = 'silver';
      nepali = 'चाँदी दर';
      eng = 'Pure Silver';
    } else {
      metal = 'gold';
      nepali = 'छापावाल सुन';
      eng = 'Fine Gold (9999)';
    }

    if (rawType.contains('१० ग्राम') || rawType.contains('10') || rawType.toLowerCase().contains('gram')) {
      unit = '10 gram';
    } else {
      unit = '1 tola';
    }

    DateTime? tDate;
    DateTime? yDate;
    if (json['todayDate'] != null) {
      tDate = DateTime.tryParse(json['todayDate'].toString());
    }
    if (json['yestardayDate'] != null) {
      yDate = DateTime.tryParse(json['yestardayDate'].toString());
    }

    return GoldSilverRate(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      metalType: metal,
      nepaliTitle: nepali,
      englishTitle: eng,
      unit: unit,
      todayRate: today,
      yesterdayRate: yest,
      todayDate: tDate,
      yesterdayDate: yDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'metalType': metalType,
      'nepaliTitle': nepaliTitle,
      'englishTitle': englishTitle,
      'unit': unit,
      'todayRate': todayRate,
      'yesterdayRate': yesterdayRate,
      'todayDate': todayDate?.toIso8601String(),
      'yesterdayDate': yesterdayDate?.toIso8601String(),
    };
  }
}
