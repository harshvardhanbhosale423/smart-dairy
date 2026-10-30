import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _inrWithDecimal = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static String format(double amount, {bool showDecimals = false}) {
    if (showDecimals || amount % 1 != 0) {
      return _inrWithDecimal.format(amount);
    }
    return _inrFormat.format(amount);
  }

  static String formatWithoutSymbol(double amount) {
    final formatted = format(amount);
    return formatted.replaceAll('₹', '').trim();
  }
}

