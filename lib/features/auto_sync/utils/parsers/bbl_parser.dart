import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../domain/entities/detected_transaction.dart';
import 'bank_parser_strategy.dart';

class BblParser extends BankParserStrategy {
  @override
  String get bankId => 'bbl';

  @override
  String get bankName => 'กรุงเทพ (Bangkok Bank)';

  @override
  String get shortName => 'Bangkok Bank';

  @override
  int get brandColor => 0xFF1E3A8A; // BBL Deep Blue

  @override
  List<String> get supportedPackages => const [
    'com.bbl.mobilebanking', // Bangkok Bank Mobile Banking
    'com.bbl.mBanking',
    'com.bbl.mobilephone',
  ];

  @override
  bool canHandle(String packageName, String text) {
    final pkg = packageName.toLowerCase().trim();
    if (supportedPackages.any((p) => p.toLowerCase() == pkg)) {
      return true;
    }
    if (pkg.contains('bbl') || pkg.contains('bangkokbank')) {
      return true;
    }
    final lower = text.toLowerCase();
    return lower.contains('bangkok bank') ||
        lower.contains('กรุงเทพ') ||
        lower.contains('bbl') ||
        lower.contains('บัวหลวง') ||
        lower.contains('bualuang');
  }

  static final RegExp _accountMaskRegex = RegExp(r'(?:บช\.|บัญชี|จาก|เข้า)\s*([0-9xX\-]+)', caseSensitive: false);
  static final RegExp _merchantRegex = RegExp(
    r'(?:ให้แก่|ให้กับ|ให้|ไปยัง|ไป|ชำระค่าสินค้าที่|ที่ร้าน|ชำระให้)\s*([A-Za-z0-9\u0E00-\u0E7F\s\.\-]+?)(?:\s+(?:จำนวน|ยอด|ผ่าน|สำเร็จ|เข้า)|$|\s+[0-9])',
    caseSensitive: false,
  );
  static final RegExp _senderRegex = RegExp(
    r'(?:จาก|โอนจาก|รับจาก|ผู้โอน)\s*([A-Za-z0-9\u0E00-\u0E7F\s\.\-]+?)(?:\s+(?:จำนวน|ยอด|เข้า)|$|\s+[0-9])',
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
    if (lowerTitle.contains('เงินเข้า') || lowerTitle.contains('เงินโอนเข้า') || lowerTitle.contains('รับโอน')) {
      type = TransactionType.income;
    } else if (lowerTitle.contains('โอนเงิน') || lowerTitle.contains('ชำระเงิน') || lowerTitle.contains('ถอนเงิน')) {
      type = TransactionType.expense;
    } else {
      // ด่านที่ 2: ตรวจจับรูปแบบเฉพาะของ Bangkok Bank จาก Text
      final isBblIncome = lowerText.contains('เงินโอนเข้า') ||
          lowerText.contains('เงินเข้า') ||
          lowerText.contains('รับโอน');
      final isBblExpense = lowerText.contains('โอนเงิน') ||
          lowerText.contains('ชำระเงิน') ||
          lowerText.contains('ชำระค่า');

      if (isBblIncome && !isBblExpense) {
        type = TransactionType.income;
      } else {
        type = TransactionType.expense;
      }
    }

    // 2. Amount
    final amount = extractAmountCommon(fullText);
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

    // 4. Counterparty
    String? merchantOrSender;
    if (type == TransactionType.income) {
      final match = _senderRegex.firstMatch(fullText);
      if (match != null) {
        final raw = match.group(1)?.trim();
        if (raw != null && raw.isNotEmpty && raw.length < 40 && !raw.startsWith('x-')) {
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
    } else if (lower.contains('ถอนเงิน') || lower.contains('ถอน/โอน')) {
      txTitle = 'ถอน/โอนเงิน';
    } else if (type == TransactionType.income) {
      txTitle = 'เงินเข้า (Bangkok Bank)';
    } else {
      txTitle = 'โอนเงิน/ชำระ (Bangkok Bank)';
    }

    final category = suggestCategory(fullText, type, merchantOrSender);
    final notifTime = timestamp ?? DateTime.now();
    final timeBucket = notifTime.millisecondsSinceEpoch ~/ 4000;
    final uniqueId = (id != null && id.isNotEmpty)
        ? id
        : 'tx_bbl_${timeBucket}_${amount.toStringAsFixed(2)}_${type.name}';

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
