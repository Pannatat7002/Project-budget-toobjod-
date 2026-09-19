import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../domain/entities/detected_transaction.dart';
import 'bank_parser_strategy.dart';

class ScbParser extends BankParserStrategy {
  @override
  String get bankId => 'scb';

  @override
  String get bankName => 'ไทยพาณิชย์ (SCB EASY)';

  @override
  String get shortName => 'SCB EASY';

  @override
  int get brandColor => 0xFF4E2A84; // SCB Purple

  @override
  List<String> get supportedPackages => const [
    'com.scb.phone', // SCB EASY
    'com.scb.easy',
  ];

  @override
  bool canHandle(String packageName, String text) {
    final pkg = packageName.toLowerCase().trim();
    return supportedPackages.any((p) => p.toLowerCase() == pkg);
  }

  static final RegExp _accountMaskRegex = RegExp(r'(?:บัญชี|บช\.)\s*([0-9xX\-]+)', caseSensitive: false);
  static final RegExp _merchantRegex = RegExp(
    r'(?:ให้กับ|ให้แก่|ให้|ไปยัง|ไป|ชำระค่าสินค้าที่|ที่ร้าน)\s*([A-Za-z0-9\u0E00-\u0E7F\s\.\-]+?)(?:\s+(?:จำนวน|ยอด|ผ่าน|เมื่อ|สำเร็จ)|$|\s+[0-9])',
    caseSensitive: false,
  );
  static final RegExp _senderRegex = RegExp(
    r'(?:จาก|รับจาก|ผู้โอน)\s*([A-Za-z0-9\u0E00-\u0E7F\s\.\-]+?)(?:\s+(?:จำนวน|ยอด|เข้า)|$|\s+[0-9])',
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
    if (lowerTitle.contains('เงินเข้า') || lowerTitle.contains('รับโอน') || lowerTitle.contains('รับเงิน')) {
      type = TransactionType.income;
    } else if (lowerTitle.contains('โอนเงิน') || lowerTitle.contains('ชำระเงิน') || lowerTitle.contains('หักบัญชี')) {
      type = TransactionType.expense;
    } else {
      // ด่านที่ 2: ตรวจจับรูปแบบเฉพาะของ SCB EASY จาก Text
      final isScbIncome = lowerText.contains('เงินเดือน') ||
          lowerText.contains('เงินเข้า') ||
          lowerText.contains('รับโอน') ||
          lowerText.contains('แม่มณี');
      final isScbExpense = lowerText.contains('โอนเงิน') ||
          lowerText.contains('ชำระค่า') ||
          lowerText.contains('ชำระเงิน') ||
          lowerText.contains('หักบัญชี') ||
          lowerText.contains('จ่ายเงิน');

      if (isScbIncome && !isScbExpense) {
        type = TransactionType.income;
      } else {
        type = TransactionType.expense;
      }
    }

    // 2. Amount
    final amount = extractAmountByBank(bankId: bankId, type: type, text: fullText);
    if (amount == null || amount <= 0) return null;

    // 3. Account Mask
    String? mask;
    final maskMatch = _accountMaskRegex.firstMatch(fullText);
    if (maskMatch != null) {
      final raw = maskMatch.group(1)?.replaceAll('-', '').trim();
      if (raw != null && raw.length >= 4) {
        mask = 'x-${raw.substring(raw.length - 4)}';
      }
    }

    // 4. Counterparty / Merchant
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

    // 5. Title
    String txTitle;
    if (merchantOrSender != null && merchantOrSender.isNotEmpty) {
      txTitle = merchantOrSender;
    } else if (type == TransactionType.income) {
      txTitle = 'เงินเข้า (SCB EASY)';
    } else {
      txTitle = 'โอนเงิน/ชำระ (SCB EASY)';
    }

    final category = suggestCategory(fullText, type, merchantOrSender);
    final notifTime = timestamp ?? DateTime.now();
    final timeBucket = notifTime.millisecondsSinceEpoch ~/ 4000;
    final uniqueId = (id != null && id.isNotEmpty)
        ? id
        : 'tx_scb_${timeBucket}_${amount.toStringAsFixed(2)}_${type.name}';

    return DetectedTransaction(
      id: uniqueId,
      packageName: packageName,
      bankId: bankId,
      bankName: bankName,
      bankShortName: shortName,
      bankColorValue: brandColor,
      accountMask: mask,
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
