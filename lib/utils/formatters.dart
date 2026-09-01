import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  static final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  static String currency(double amount) {
    return _currencyFormat.format(amount);
  }

  static String date(DateTime dateTime) {
    return _dateFormat.format(dateTime);
  }
}
