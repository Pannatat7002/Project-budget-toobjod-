import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../domain/entities/detected_transaction.dart';
import 'bank_parser_strategy.dart';

class KBankParser extends BankParserStrategy {
  @override
  String get bankId => 'kbank';

  @override
  String get bankName => 'กสิกรไทย (K PLUS)';

  @override
  String get shortName => 'K PLUS';

  @override
  int get brandColor => 0xFF138F2D; // Kasikorn Green

  @override
  bool canHandle(String packageName, String text) {
    final pkg = packageName.toLowerCase();
    if (pkg.contains('kasikorn') || pkg.contains('kplus') || pkg.contains('makebykbank')) {
      return true;
    }
    final lower = text.toLowerCase();
    return lower.contains('k plus') ||
        lower.contains('kbank') ||
        lower.contains('กสิกร') ||
        lower.contains('make by kbank');
  }

  static final RegExp _accountMaskRegex = RegExp(r'(?:บช\.|บัญชี|จาก|เข้า)\s*x-?([0-9]{4})', caseSensitive: false);
  static final RegExp _merchantRegex = RegExp(
    r'(?:ให้แก่|ให้กับ|ให้|ไปยัง|ไป|ร้าน|ที่ร้าน)\s*([A-Za-z0-9\u0E00-\u0E7F\s\.\-]+?)(?:\s+(?:จำนวน|ยอด|เป็นจำนวน)|$|\s+[0-9])',
    caseSensitive: false,
  );
  static final RegExp _senderRegex = RegExp(
    r'(?:จาก|โอนจาก|รับจาก)\s*([A-Za-z0-9\u0E00-\u0E7F\s\.\-]+?)(?:\s+(?:จำนวน|ยอด|เข้า)|$|\s+[0-9])',
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
    TransactionType type = TransactionType.expense;
    if (lower.contains('เงินเข้า') ||
        lower.contains('โอนเข้า') ||
        lower.contains('รับเงิน') ||
        lower.contains('ได้รับเงิน') ||
        lower.contains('ฝากเงิน') ||
        lower.contains('รับโอน')) {
      if (!lower.contains('โอนเงินไป') && !lower.contains('โอนออก') && !lower.contains('ชำระ')) {
        type = TransactionType.income;
      }
    }

    // 2. Amount
    final amount = extractAmountCommon(fullText);
    if (amount == null || amount <= 0) return null;

    // 3. Account Mask
    String? mask;
    final maskMatch = _accountMaskRegex.firstMatch(fullText);
    if (maskMatch != null) {
      mask = 'x-${maskMatch.group(1)}';
    }

    // 4. Merchant / Sender
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
    } else if (title.trim() == 'รายการโอน/ถอน' || lower.contains('รายการโอน/ถอน')) {
      txTitle = 'รายการโอน/ถอน';
    } else if (lower.contains('ถอนเงินไม่ใช้บัตร')) {
      txTitle = 'ถอนเงินไม่ใช้บัตร';
    } else if (lower.contains('ถอนเงินสด') || lower.contains('atm')) {
      txTitle = 'ถอนเงินสด';
    } else if (type == TransactionType.income) {
      txTitle = 'เงินเข้า (K PLUS)';
    } else {
      txTitle = 'โอนเงิน/ชำระ (K PLUS)';
    }

    final category = suggestCategory(fullText, type, merchantOrSender);
    final notifTime = timestamp ?? DateTime.now();
    final timeBucket = notifTime.millisecondsSinceEpoch ~/ 4000;
    final uniqueId = (id != null && id.isNotEmpty)
        ? id
        : 'tx_kbank_${timeBucket}_${amount.toStringAsFixed(2)}_${type.name}';

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
