import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _currencyFormat = NumberFormat('#,##0.00', 'th_TH');
  static final NumberFormat _compactFormat = NumberFormat.compact(locale: 'th_TH');
  static final NumberFormat _noDecimalFormat = NumberFormat('#,##0', 'th_TH');

  /// Format as ฿1,234.56
  static String format(double amount, {String symbol = '', bool showDecimals = true}) {
    final formatted = showDecimals ? _currencyFormat.format(amount) : _noDecimalFormat.format(amount);
    return '$symbol$formatted';
  }

  /// Format without currency symbol (e.g. 1,234.56)
  static String formatNumber(double amount, {bool showDecimals = true}) {
    return showDecimals ? _currencyFormat.format(amount) : _noDecimalFormat.format(amount);
  }

  /// Compact format for charts or badges (e.g. 1.2k)
  static String formatCompact(double amount, {String symbol = ''}) {
    return '$symbol${_compactFormat.format(amount)}';
  }
}
