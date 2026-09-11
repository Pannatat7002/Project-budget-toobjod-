import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../domain/entities/detected_transaction.dart';
import 'bank_parser_strategy.dart';

class TtbParser extends BankParserStrategy {
  @override
  String get bankId => 'ttb';

  @override
  String get bankName => 'ทีทีบี (ttb touch)';

  @override
  String get shortName => 'ttb touch';

  @override
  int get brandColor => 0xFF0056B3; // ttb Blue

  @override
  bool canHandle(String packageName, String text) {
    final pkg = packageName.toLowerCase();
    if (pkg.contains('ttb') || pkg.contains('tmb')) {
      return true;
    }
    final lower = text.toLowerCase();
    return lower.contains('ttb') ||
        lower.contains('tmb') ||
        lower.contains('ทีทีบี') ||
        lower.contains('ทหารไทยธนชาต');
  }

  static final RegExp _accountMaskRegex = RegExp(r'(?:บช\.|บัญชี|จาก|เข้า)\s*([0-9xX\-]+)', caseSensitive: false);
  static final RegExp _merchantRegex = RegExp(
    r'(?:ให้แก่|ให้กับ|ให้|ไปยัง|ไป|ที่ร้าน|ชำระค่าสินค้าที่|ชำระให้)\s*([A-Za-z0-9\u0E00-\u0E7F\s\.\-]+?)(?:\s+(?:ยอดคงเหลือ|จำนวน|ยอด|ผ่าน|สำเร็จ|เข้า)|$|\s+[0-9])',
    caseSensitive: false,
  );
  static final RegExp _senderRegex = RegExp(
    r'(?:จาก|โอนจาก|รับจาก|ผู้โอน)\s*([A-Za-z0-9\u0E00-\u0E7F\s\.\-]+?)(?:\s+(?:ยอดคงเหลือ|จำนวน|ยอด|เข้า)|$|\s+[0-9])',
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
        lower.contains('มีเงินเข้า') ||
        lower.contains('ฝากเงิน') ||
        lower.contains('รับโอน')) {
      if (!lower.contains('โอนเงินออก') && !lower.contains('โอนออก') && !lower.contains('ชำระ')) {
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
    } else if (lower.contains('โอนเงินออก') || lower.contains('โอนเงิน')) {
      txTitle = 'โอนเงิน';
    } else if (type == TransactionType.income) {
      txTitle = 'เงินเข้า (ttb touch)';
    } else {
      txTitle = 'โอนเงิน/ชำระ (ttb touch)';
    }

    final category = suggestCategory(fullText, type, merchantOrSender);
    final notifTime = timestamp ?? DateTime.now();
    final timeBucket = notifTime.millisecondsSinceEpoch ~/ 4000;
    final uniqueId = (id != null && id.isNotEmpty)
        ? id
        : 'tx_ttb_${timeBucket}_${amount.toStringAsFixed(2)}_${type.name}';

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
