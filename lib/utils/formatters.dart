import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  static final NumberFormat _numberFormat = NumberFormat('#,##0.00');
  static final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  static String currency(double amount, [String? symbol]) {
    if (symbol != null) {
      if (symbol.isEmpty) {
        return _numberFormat.format(amount);
      }
      if (symbol != '\$') {
        return NumberFormat.currency(symbol: symbol, decimalDigits: 2).format(amount);
      }
    }
    return _currencyFormat.format(amount);
  }

  static String number(double amount) {
    return _numberFormat.format(amount);
  }

  static String date(DateTime dateTime) {
    return _dateFormat.format(dateTime);
  }
}
