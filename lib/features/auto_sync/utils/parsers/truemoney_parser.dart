import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../domain/entities/detected_transaction.dart';
import 'bank_parser_strategy.dart';

class TrueMoneyParser extends BankParserStrategy {
  @override
  String get bankId => 'truemoney';

  @override
  String get bankName => 'ทรูมันนี่ (TrueMoney)';

  @override
  String get shortName => 'TrueMoney';

  @override
  int get brandColor => 0xFFFF5B00; // TrueMoney Orange

  @override
  List<String> get supportedPackages => const [
    'th.co.truemoney.wallet', // TrueMoney Wallet
    'com.truemoney',
    'th.co.cenergy.tmn.wallet',
  ];

  @override
  bool canHandle(String packageName, String text) {
    final pkg = packageName.toLowerCase().trim();
    if (supportedPackages.any((p) => p.toLowerCase() == pkg)) {
      return true;
    }
    if (pkg.contains('truemoney')) return true;
    final lower = text.toLowerCase();
    return lower.contains('truemoney') || lower.contains('ทรูมันนี่');
  }

  static final RegExp _merchantRegex = RegExp(
    r'(?:ให้แก่|ให้กับ|ให้|ไปยัง|ที่ร้าน|ชำระค่าสินค้าที่)\s*([A-Za-z0-9\u0E00-\u0E7F\s\.\-]+?)(?:\s+(?:จำนวน|ยอด|ผ่าน|สำเร็จ)|$|\s+[0-9])',
    caseSensitive: false,
  );
  static final RegExp _senderRegex = RegExp(
    r'(?:จาก|รับจาก|โอนจาก)\s*([A-Za-z0-9\u0E00-\u0E7F\s\.\-]+?)(?:\s+(?:จำนวน|ยอด|เข้า)|$|\s+[0-9])',
    caseSensitive: false,
  );

  @override
  DetectedTransaction? parse({
    String? id,
    required String packageName,
    required String title,
    required String text,
    String? subText,
    DateTime? timestamp,
  }) {
    final fullText = '$title $text ${subText ?? ''}'.trim();
    if (fullText.isEmpty) return null;

    final lower = fullText.toLowerCase();

    // 1. Transaction Type
    TransactionType type;
    final lowerTitle = title.toLowerCase().trim();
    final lowerText = text.toLowerCase().trim();

    // ด่านที่ 1: ตรวจจับจาก Title โดยตรง (จับแปะ)
    if (lowerTitle.contains('เติมเงินสำเร็จ') ||
        lowerTitle.contains('ได้รับเงิน') ||
        lowerTitle.contains('เงินเข้า')) {
      type = TransactionType.income;
    } else if (lowerTitle.contains('ชำระเงินสำเร็จ') ||
        lowerTitle.contains('โอนเงินสำเร็จ') ||
        lowerTitle.contains('ชำระเงิน') ||
        lowerTitle.contains('โอนเงิน')) {
      type = TransactionType.expense;
    } else {
      // ด่านที่ 2: ตรวจจับรูปแบบเฉพาะของ TrueMoney จาก Text
      final isTmnIncome = lowerText.contains('ได้รับเงิน') ||
          lowerText.contains('เติมเงินสำเร็จ') ||
          lowerText.contains('เงินเข้า') ||
          lowerText.contains('cashback');
      final isTmnExpense = lowerText.contains('ชำระค่าสินค้า') ||
          lowerText.contains('ชำระเงินสำเร็จ') ||
          lowerText.contains('ชำระเงินให้') ||
          lowerText.contains('โอนเงินไป') ||
          lowerText.contains('โอนเงินให้');

      if (isTmnIncome && !isTmnExpense) {
        type = TransactionType.income;
      } else {
        type = TransactionType.expense;
      }
    }

    // 2. Amount
    final amount = extractAmountCommon(fullText);
    if (amount == null || amount <= 0) return null;

    // 3. Counterparty / Merchant
    String? merchantOrSender;
    if (type == TransactionType.income) {
      final match = _senderRegex.firstMatch(fullText);
      if (match != null) {
        final raw = match.group(1)?.trim();
        if (raw != null && raw.isNotEmpty && raw.length < 40) {
          merchantOrSender = raw;
        }
      }
    } else {
      final match = _merchantRegex.firstMatch(fullText);
      if (match != null) {
        final raw = match.group(1)?.trim();
        if (raw != null && raw.isNotEmpty && raw.length < 40) {
          merchantOrSender = raw;
        }
      }
    }

    // 4. Title
    String txTitle;
    if (merchantOrSender != null && merchantOrSender.isNotEmpty) {
      txTitle = merchantOrSender;
    } else if (type == TransactionType.income) {
      txTitle = 'เงินเข้า (TrueMoney)';
    } else {
      txTitle = 'ชำระเงิน/โอน (TrueMoney)';
    }

    final category = suggestCategory(fullText, type, merchantOrSender);
    final notifTime = timestamp ?? DateTime.now();
    final timeBucket = notifTime.millisecondsSinceEpoch ~/ 4000;
    final uniqueId = (id != null && id.isNotEmpty)
        ? id
        : 'tx_truemoney_${timeBucket}_${amount.toStringAsFixed(2)}_${type.name}';

    return DetectedTransaction(
      id: uniqueId,
      packageName: packageName,
      bankId: bankId,
      bankName: bankName,
      bankShortName: shortName,
      bankColorValue: brandColor,
      amount: amount,
      type: type,
      title: txTitle,
      suggestedCategoryId: category.id,
      suggestedCategoryName: category.name,
      suggestedCategoryIconCode: category.iconCode,
      suggestedCategoryColorValue: category.colorValue,
      merchantOrSender: merchantOrSender,
      rawTitle: title,
      rawText: text,
      timestamp: notifTime,
    );
  }
}
