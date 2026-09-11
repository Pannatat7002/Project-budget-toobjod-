import '../../domain/entities/detected_transaction.dart';
import 'bank_parser_strategy.dart';
import 'bbl_parser.dart';
import 'dime_parser.dart';
import 'gsb_parser.dart';
import 'kbank_parser.dart';
import 'kma_parser.dart';
import 'ktb_parser.dart';
import 'other_banks_parser.dart';
import 'scb_parser.dart';
import 'shopeepay_parser.dart';
import 'ttb_parser.dart';
import 'truemoney_parser.dart';

class BankParserRegistry {
  static final List<BankParserStrategy> _strategies = [
    KBankParser(),
    ScbParser(),
    KtbParser(),
    BblParser(),
    TtbParser(),
    KmaParser(),
    GsbParser(),
    TrueMoneyParser(),
    ShopeePayParser(),
    DimeParser(),
    OtherBanksParser('cimb'),
    OtherBanksParser('uob'),
  ];

  /// Find the strategy that handles the notification and parse it
  static DetectedTransaction? parse({
    String? id,
    required String packageName,
    required String title,
    required String text,
    String? subText,
    DateTime? timestamp,
  }) {
    final fullText = '$title $text ${subText ?? ''}'.trim();
    if (fullText.isEmpty) return null;

    // 1. First attempt to match by packageName and text
    for (final strategy in _strategies) {
      if (strategy.canHandle(packageName, fullText)) {
        final result = strategy.parse(
          id: id,
          packageName: packageName,
          title: title,
          text: text,
          subText: subText,
          timestamp: timestamp,
        );
        if (result != null) {
          return result;
        }
      }
    }

    return null;
  }

  /// Get strategy by bankId
  static BankParserStrategy? getStrategy(String bankId) {
    try {
      return _strategies.firstWhere((s) => s.bankId == bankId);
    } catch (_) {
      return null;
    }
  }
}
