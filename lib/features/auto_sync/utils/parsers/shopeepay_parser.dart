import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../domain/entities/detected_transaction.dart';
import 'bank_parser_strategy.dart';

class ShopeePayParser extends BankParserStrategy {
  @override
  String get bankId => 'shopeepay';

  @override
  String get bankName => 'ช้อปปี้เพย์ (ShopeePay)';

  @override
  String get shortName => 'ShopeePay';

  @override
  int get brandColor => 0xFFEE4D2D; // Shopee Red-Orange

  @override
  List<String> get supportedPackages => const [
    'com.beeasy.airpay', // ShopeePay / AirPay
    'com.shopeepay.th',
    'com.airpay',
  ];

  @override
  bool canHandle(String packageName, String text) {
    final pkg = packageName.toLowerCase().trim();
    if (supportedPackages.any((p) => p.toLowerCase() == pkg)) {
      return true;
    }
    if (pkg.contains('shopeepay') || pkg.contains('airpay')) {
      return true;
    }
    final lower = text.toLowerCase();
    return lower.contains('shopeepay') || lower.contains('airpay') || lower.contains('ช้อปปี้เพย์');
  }

  static final RegExp _merchantRegex = RegExp(
    r'(?:ให้แก่|ให้กับ|ให้|ไปยัง|ไปที่|ที่ร้าน|ที่|ชำระค่าสินค้าที่|ชำระให้)\s*([A-Za-z0-9\u0E00-\u0E7F\s\.\-]+?)(?:\s+(?:จำนวน|ยอด|ผ่าน|สำเร็จ|เข้า)|$|\s+[0-9])',
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
    if (lowerTitle.contains('เติมเงิน') ||
        lowerTitle.contains('คืนเงิน') ||
        lowerTitle.contains('เงินเข้า') ||
        lowerTitle.contains('refund')) {
      type = TransactionType.income;
    } else if (lowerTitle.contains('ชำระเงิน') ||
        lowerTitle.contains('โอนเงิน') ||
        lowerTitle.contains('ใช้จ่าย')) {
      type = TransactionType.expense;
    } else {
      // ด่านที่ 2: ตรวจจับรูปแบบเฉพาะของ ShopeePay จาก Text
      final isShopeeIncome = lowerText.contains('เติมเงิน') ||
          lowerText.contains('คืนเงิน') ||
          lowerText.contains('cashback') ||
          lowerText.contains('refund');
      final isShopeeExpense = lowerText.contains('ชำระเงินสำเร็จ') ||
          lowerText.contains('ชำระค่า') ||
          lowerText.contains('ที่ shopee') ||
          lowerText.contains('โอนเงิน');

      if (isShopeeIncome && !isShopeeExpense) {
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

    // 5. Title
    String txTitle;
    if (merchantOrSender != null && merchantOrSender.isNotEmpty) {
      txTitle = merchantOrSender;
    } else if (type == TransactionType.income) {
      txTitle = 'เงินเข้า/เติมเงิน (ShopeePay)';
    } else {
      txTitle = 'ชำระเงิน (ShopeePay)';
    }

    final category = suggestCategory(fullText, type, merchantOrSender ?? 'shopee');
    final notifTime = timestamp ?? DateTime.now();
    final timeBucket = notifTime.millisecondsSinceEpoch ~/ 4000;
    final uniqueId = (id != null && id.isNotEmpty)
        ? id
        : 'tx_shopeepay_${timeBucket}_${amount.toStringAsFixed(2)}_${type.name}';

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
