import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../domain/entities/detected_transaction.dart';
import 'bank_parser_strategy.dart';

class PaotangParser extends BankParserStrategy {
  @override
  String get bankId => 'paotang';

  @override
  String get bankName => 'เป๋าตัง (Paotang)';

  @override
  String get shortName => 'เป๋าตัง';

  @override
  int get brandColor => 0xFF00A3E0; // Paotang Cyan Blue

  @override
  List<String> get supportedPackages => const [
    'com.ktb.customer.qr', // เป๋าตัง (Official)
    'com.ktb.paotang',
  ];

  @override
  bool canHandle(String packageName, String text) {
    final pkg = packageName.toLowerCase().trim();

    // ด่านที่ 1: ตรวจชื่อ Package Name ตรงเป๊ะ (Exact Match)
    if (supportedPackages.any((p) => p.toLowerCase() == pkg)) {
      return true;
    }

    return false;
  }

  static final RegExp _merchantRegex = RegExp(
    r'(?:ไปยัง|ให้แก่|ให้กับ|ชำระให้|โอนไป|ชำระค่าสินค้าที่|ที่ร้าน)\s*([A-Za-z0-9\u0E00-\u0E7F\s\.\-]+?)(?:\s+(?:จำนวน|ยอด|สำเร็จ)|$|\s+[0-9])',
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
    if (lowerTitle.contains('เติมเงิน') ||
        lowerTitle.contains('เงินเข้า') ||
        lowerTitle.contains('รับเงิน')) {
      type = TransactionType.income;
    } else if (lowerTitle.contains('ชำระ') ||
        lowerTitle.contains('โอนเงิน') ||
        lowerTitle.contains('จ่ายเงิน')) {
      type = TransactionType.expense;
    } else {
      // ด่านที่ 2: ตรวจจับรูปแบบเฉพาะของ เป๋าตัง จาก Text
      final isPaotangIncome = lowerText.contains('เติมเงิน') ||
          lowerText.contains('เงินเข้า') ||
          lowerText.contains('รับเงิน');
      final isPaotangExpense = lowerText.contains('ชำระให้') ||
          lowerText.contains('ชำระค่า') ||
          lowerText.contains('โอนไป') ||
          lowerText.contains('โอนเงิน');

      if (isPaotangIncome && !isPaotangExpense) {
        type = TransactionType.income;
      } else {
        type = TransactionType.expense;
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
      txTitle = 'เงินเข้า ($shortName)';
    } else {
      txTitle = 'โอนเงิน/ชำระ ($shortName)';
    }

    final category = suggestCategory(fullText, type, merchantOrSender);
    final notifTime = timestamp ?? DateTime.now();
    final timeBucket = notifTime.millisecondsSinceEpoch ~/ 4000;
    final uniqueId = (id != null && id.isNotEmpty)
        ? id
        : 'tx_paotang_${timeBucket}_${amount.toStringAsFixed(2)}_${type.name}';

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
