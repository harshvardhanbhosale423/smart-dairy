import 'package:intl/intl.dart';

class DateFormatter {
  static const List<String> marathiMonths = [
    'जानेवारी', 'फेब्रुवारी', 'मार्च', 'एप्रिल', 'मे', 'जून',
    'जुलै', 'ऑगस्ट', 'सप्टेंबर', 'ऑक्टोबर', 'नोव्हेंबर', 'डिसेंबर'
  ];

  static String formatDate(DateTime date, {bool isMarathi = false}) {
    if (isMarathi) {
      final day = date.day.toString();
      final month = marathiMonths[date.month - 1];
      final year = date.year.toString();
      return '$day $month $year';
    }
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatMonthYear(DateTime date, {bool isMarathi = false}) {
    if (isMarathi) {
      return '${marathiMonths[date.month - 1]} ${date.year}';
    }
    return DateFormat('MMMM yyyy').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  static String toYearMonthKey(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }
}

