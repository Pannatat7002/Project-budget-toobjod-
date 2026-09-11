import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../domain/entities/detected_transaction.dart';
import 'bank_parser_strategy.dart';

class DimeParser extends BankParserStrategy {
  @override
  String get bankId => 'dime';

  @override
  String get bankName => 'ไดม์ (Dime! by KKP)';

  @override
  String get shortName => 'Dime!';

  @override
  int get brandColor => 0xFF00C781; // Dime Teal Green

  @override
  bool canHandle(String packageName, String text) {
    final pkg = packageName.toLowerCase();
    if (pkg.contains('dime')) {
      return true;
    }
    final lower = text.toLowerCase();
    return lower.contains('dime') || lower.contains('ไดม์');
  }

  static final RegExp _merchantRegex = RegExp(
    r'(?:ให้แก่|ให้กับ|ให้|ไปยัง|ไป|ที่ร้าน|ชำระค่าสินค้าที่|ชำระให้)\s*([A-Za-z0-9\u0E00-\u0E7F\s\.\-]+?)(?:\s+(?:จำนวน|ยอด|ผ่าน|สำเร็จ|เข้า)|$|\s+[0-9])',
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
    TransactionType type = TransactionType.expense;
    if (lower.contains('เงินเข้า') ||
        lower.contains('โอนเข้า') ||
        lower.contains('รับเงิน') ||
        lower.contains('ได้รับเงิน') ||
        lower.contains('ฝากเงิน') ||
        lower.contains('เงินฝาก') ||
        lower.contains('ดอกเบี้ย') ||
        lower.contains('เงินปันผล') ||
        lower.contains('รับโอน')) {
      if (!lower.contains('โอนเงินไป') && !lower.contains('ถอนเงิน') && !lower.contains('ชำระ')) {
        type = TransactionType.income;
      }
    }

    // 2. Amount
    final amount = extractAmountCommon(fullText);
    if (amount == null || amount <= 0) return null;

    // 3. Counterparty
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
    } else if (lower.contains('ฝากเงิน') || lower.contains('dime! save')) {
      txTitle = 'ฝากเงิน (Dime! Save)';
    } else if (type == TransactionType.income) {
      txTitle = 'เงินเข้า (Dime!)';
    } else {
      txTitle = 'โอนเงิน/ลงทุน (Dime!)';
    }

    final category = suggestCategory(fullText, type, merchantOrSender);
    final notifTime = timestamp ?? DateTime.now();
    final timeBucket = notifTime.millisecondsSinceEpoch ~/ 4000;
    final uniqueId = (id != null && id.isNotEmpty)
        ? id
        : 'tx_dime_${timeBucket}_${amount.toStringAsFixed(2)}_${type.name}';

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
