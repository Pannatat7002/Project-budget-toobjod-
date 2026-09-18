import 'package:flutter_test/flutter_test.dart';
import 'package:budget_planner/core/utils/currency_formatter.dart';
import 'package:budget_planner/core/utils/date_formatter.dart';

void main() {
  group('Core Utilities Test', () {
    test('CurrencyFormatter formats Thai Baht correctly', () {
      expect(CurrencyFormatter.format(1500.5, symbol: '฿'), equals('฿1,500.50'));
      expect(CurrencyFormatter.format(0, symbol: '฿'), equals('฿0.00'));
      expect(CurrencyFormatter.formatNumber(12500), equals('12,500.00'));
    });

    test('DateFormatter formats relative dates correctly', () {
      final now = DateTime.now();
      expect(DateFormatter.formatRelative(now), equals('วันนี้'));
    });
  });
}
