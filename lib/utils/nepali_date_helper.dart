import 'package:intl/intl.dart';
import 'package:nepali_utils/nepali_utils.dart';

class NepaliDateDetails {
  final int year;
  final int month;
  final int day;
  final String monthNameEn;
  final String monthNameNp;
  final String dayNameEn;
  final String dayNameNp;
  final String formattedEn;
  final String formattedNp;
  final String isoFormat;
  final DateTime adEquivalent;

  const NepaliDateDetails({
    required this.year,
    required this.month,
    required this.day,
    required this.monthNameEn,
    required this.monthNameNp,
    required this.dayNameEn,
    required this.dayNameNp,
    required this.formattedEn,
    required this.formattedNp,
    required this.isoFormat,
    required this.adEquivalent,
  });
}

class DateDifferenceResult {
  final int years;
  final int months;
  final int days;
  final int totalDays;

  const DateDifferenceResult({
    required this.years,
    required this.months,
    required this.days,
    required this.totalDays,
  });

  String get summary {
    final parts = <String>[];
    if (years > 0) parts.add('$years ${years == 1 ? "year" : "years"}');
    if (months > 0) parts.add('$months ${months == 1 ? "month" : "months"}');
    if (days > 0 || parts.isEmpty) parts.add('$days ${days == 1 ? "day" : "days"}');
    return parts.join(', ');
  }
}

class NepaliDateHelper {
  static const List<String> bsMonthsEn = [
    'Baishakh',
    'Jestha',
    'Ashadh',
    'Shrawan',
    'Bhadra',
    'Ashwin',
    'Kartik',
    'Mangsir',
    'Poush',
    'Magh',
    'Falgun',
    'Chaitra',
  ];

  static const List<String> bsMonthsNp = [
    'वैशाख',
    'जेठ',
    'असार',
    'साउन',
    'भदौ',
    'असोज',
    'कात्तिक',
    'मंसिर',
    'पुस',
    'माघ',
    'फागुन',
    'चैत',
  ];

  static const List<String> weekDaysEn = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  static const List<String> weekDaysNp = [
    'आइतबार',
    'सोमबार',
    'मंगलबार',
    'बुधबार',
    'बिहीबार',
    'शुक्रबार',
    'शनिबार',
  ];

  static const Map<int, String> weekDaysNpMap = {
    DateTime.sunday: 'आइतबार',
    DateTime.monday: 'सोमबार',
    DateTime.tuesday: 'मंगलबार',
    DateTime.wednesday: 'बुधबार',
    DateTime.thursday: 'बिहीबार',
    DateTime.friday: 'शुक्रबार',
    DateTime.saturday: 'शनिबार',
  };

  /// Converts standard English Gregorian date (AD) to Nepali Bikram Sambat date (BS)
  /// Uses UTC calendar arithmetic to prevent client OS Daylight Saving Time (DST) offsets.
  static NepaliDateDetails convertAdToBs(DateTime adDate) {
    var nepaliYear = 1970;
    var nepaliMonth = 1;
    var nepaliDay = 1;

    final targetUtc = DateTime.utc(adDate.year, adDate.month, adDate.day);
    final refUtc = DateTime.utc(1913, 4, 13);
    var difference = targetUtc.difference(refUtc).inDays;

    while (difference >= NepaliDateTime(nepaliYear, 1, 1).totalDaysInYear) {
      difference -= NepaliDateTime(nepaliYear, 1, 1).totalDaysInYear;
      nepaliYear += 1;
    }

    var daysInMonth = NepaliDateTime(nepaliYear, nepaliMonth, 1).totalDays;
    while (difference >= daysInMonth) {
      difference -= daysInMonth;
      nepaliMonth += 1;
      daysInMonth = NepaliDateTime(nepaliYear, nepaliMonth, 1).totalDays;
    }

    nepaliDay += difference;
    final nepaliDate = NepaliDateTime(nepaliYear, nepaliMonth, nepaliDay);
    final cleanAd = DateTime(adDate.year, adDate.month, adDate.day);
    return _buildDetails(nepaliDate, cleanAd);
  }

  /// Converts Nepali Bikram Sambat date (BS) to English Gregorian date (AD)
  static NepaliDateDetails convertBsToAd(int year, int month, int day) {
    final maxDays = getDaysInBsMonth(year, month);
    final clampedDay = day.clamp(1, maxDays);
    final nepaliDate = NepaliDateTime(year, month, clampedDay);
    final rawAd = nepaliDate.toDateTime();
    final cleanAd = DateTime(rawAd.year, rawAd.month, rawAd.day);
    return _buildDetails(nepaliDate, cleanAd);
  }

  static NepaliDateDetails _buildDetails(NepaliDateTime nepaliDate, DateTime adDate) {
    final monthFormatterEn = NepaliDateFormat("MMMM", Language.english);
    final monthFormatterNp = NepaliDateFormat("MMMM", Language.nepali);
    final dayNameEn = DateFormat('EEEE').format(adDate);
    final dayNameNp = weekDaysNpMap[adDate.weekday] ?? 'आइतबार';
    final monthEn = monthFormatterEn.format(nepaliDate);
    final monthNp = monthFormatterNp.format(nepaliDate);
    final npYearStr = NepaliUnicode.convert('${nepaliDate.year}');
    final npDayStr = NepaliUnicode.convert('${nepaliDate.day}');
    final formattedEn = '$monthEn ${nepaliDate.day}, ${nepaliDate.year} ($dayNameEn)';
    final formattedNp = '$npYearStr $monthNp $npDayStr, $dayNameNp';

    return NepaliDateDetails(
      year: nepaliDate.year,
      month: nepaliDate.month,
      day: nepaliDate.day,
      monthNameEn: monthEn,
      monthNameNp: monthNp,
      dayNameEn: dayNameEn,
      dayNameNp: dayNameNp,
      formattedEn: formattedEn,
      formattedNp: formattedNp,
      isoFormat: '${nepaliDate.year}-${nepaliDate.month.toString().padLeft(2, '0')}-${nepaliDate.day.toString().padLeft(2, '0')}',
      adEquivalent: adDate,
    );
  }

  /// Total days in a specific BS year and month
  static int getDaysInBsMonth(int year, int month) {
    try {
      final dt = NepaliDateTime(year, month, 1);
      return dt.totalDays;
    } catch (_) {
      return 30;
    }
  }

  /// Calculate date difference between two AD dates
  static DateDifferenceResult calculateDifference(DateTime from, DateTime to) {
    var start = from.isBefore(to) ? from : to;
    var end = from.isBefore(to) ? to : from;

    final totalDays = end.difference(start).inDays;

    int years = end.year - start.year;
    int months = end.month - start.month;
    int days = end.day - start.day;

    if (days < 0) {
      months -= 1;
      final prevMonthDays = DateTime(end.year, end.month, 0).day;
      days += prevMonthDays;
    }

    if (months < 0) {
      years -= 1;
      months += 12;
    }

    return DateDifferenceResult(
      years: years,
      months: months,
      days: days,
      totalDays: totalDays,
    );
  }
}
