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
  List<String> get supportedPackages => const [
    'com.kasikorn.retail.mbanking.wap', // K PLUS
    'com.kasikorn.bank',
    'com.kasikornbank.kplus',
  ];

  @override
  bool canHandle(String packageName, String text) {
    final pkg = packageName.toLowerCase().trim();
    if (supportedPackages.any((p) => p.toLowerCase() == pkg)) {
      return true;
    }
    if (pkg.contains('kasikorn') || pkg.contains('kplus')) {
      return true;
    }
    // If package belongs to another known bank app, do not handle
    if (pkg.contains('ttb') || pkg.contains('tmb') || pkg.contains('scb') ||
        pkg.contains('ktb') || pkg.contains('bbl') || pkg.contains('krungsri') ||
        pkg.contains('truemoney') || pkg.contains('dime') || pkg.contains('makebykbank')) {
      return false;
    }
    final lower = text.toLowerCase();
    // Do not match if "KBANK" is merely the external sender in an incoming transfer
    if (lower.contains('จาก kbank') || lower.contains('จากกสิกร') || lower.contains('จาก ธ.กสิกร')) {
      return false;
    }
    return lower.contains('k plus') ||
        lower.contains('kbank') ||
        lower.contains('กสิกร');
  }

  static final RegExp _accountMaskRegex = RegExp(
    r'(?:บช\.|บัญชี|จาก|เข้า)\s*([0-9xX\-]*[0-9]{3,}[0-9xX\-]*)',
    caseSensitive: false,
  );
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
    TransactionType type;
    final lowerTitle = title.toLowerCase().trim();
    final lowerText = text.toLowerCase().trim();

    // ด่านที่ 1: ตรวจจับจาก Title โดยตรง (จับแปะ)
    if (lowerTitle.contains('รายการเงินเข้า') || lowerTitle.contains('เงินเข้า')) {
      type = TransactionType.income;
    } else if (lowerTitle.contains('รายการโอน/ถอน') ||
        lowerTitle.contains('โอน/ถอน') ||
        lowerTitle.contains('โอนเงิน') ||
        lowerTitle.contains('ถอนเงิน')) {
      type = TransactionType.expense;
    } else {
      // ด่านที่ 2: ตรวจจับรูปแบบเฉพาะของ K PLUS จาก Text
      final isKBankIncome = lowerText.contains('เงินเข้า') ||
          lowerText.contains('รับโอน') ||
          lowerText.contains('โอนเข้า');
      final isKBankExpense = lowerText.contains('โอนเงินไปยัง') ||
          lowerText.contains('ชำระเงินให้') ||
          lowerText.contains('ชำระให้') ||
          lowerText.contains('ถอนเงินไม่ใช้บัตร') ||
          lowerText.contains('โอนออก') ||
          lowerText.contains('ชำระค่า');

      if (isKBankIncome && !isKBankExpense) {
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
      final raw = maskMatch.group(1)?.trim() ?? '';
      final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length >= 4) {
        mask = 'x-${digits.substring(digits.length - 4)}';
      } else if (raw.isNotEmpty) {
        mask = 'x-$raw';
      }
    }

    // 4. Merchant / Sender
    String? merchantOrSender;
    if (type == TransactionType.income) {
      final match = _senderRegex.firstMatch(fullText);
      if (match != null) {
        final raw = match.group(1)?.trim();
        if (raw != null && raw.isNotEmpty && raw.length < 40 && !raw.startsWith('x-') && !raw.startsWith('xxx-')) {
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

    // 5. Title (ด่านจับแปะ: ใช้ Title จาก Notification โดยตรงถ้ามีหัวข้อแจ้งเตือนจริง)
    String txTitle;
    final cleanTitle = title.trim();
    final isGenericTitle = cleanTitle.isEmpty ||
        cleanTitle.toLowerCase() == 'k plus' ||
        cleanTitle.toLowerCase() == 'kbank' ||
        cleanTitle.toLowerCase() == 'kasikorn' ||
        cleanTitle.toLowerCase() == 'com.kasikorn.retail.mbanking.wap' ||
        cleanTitle.toLowerCase() == 'com.android.shell';

    if (!isGenericTitle) {
      if (cleanTitle.contains('รายการเงินเข้า')) {
        txTitle = 'รายการเงินเข้า';
      } else if (cleanTitle.contains('รายการโอน/ถอน')) {
        txTitle = 'รายการโอน/ถอน';
      } else {
        txTitle = cleanTitle;
      }
    } else if (merchantOrSender != null && merchantOrSender.isNotEmpty) {
      txTitle = merchantOrSender;
    } else if (lower.contains('ถอนเงินไม่ใช้บัตร')) {
      txTitle = 'ถอนเงินไม่ใช้บัตร';
    } else if (lower.contains('ถอนเงินสด') || lower.contains('atm')) {
      txTitle = 'ถอนเงินสด';
    } else if (type == TransactionType.income) {
      txTitle = 'รายการเงินเข้า';
    } else {
      txTitle = 'รายการโอน/ถอน';
    }

    final category = suggestCategory(fullText, type, merchantOrSender);
    final parsedTime = extractThaiDateTime(fullText);
    final notifTime = parsedTime ?? timestamp ?? DateTime.now();
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
