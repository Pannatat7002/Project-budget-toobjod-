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
    // If package belongs to another known bank app, do not handle
    if (pkg.contains('kasikorn') || pkg.contains('kplus') || pkg.contains('scb') ||
        pkg.contains('ktb') || pkg.contains('bbl') || pkg.contains('krungsri') ||
        pkg.contains('truemoney') || pkg.contains('dime')) {
      return false;
    }
    final lower = text.toLowerCase();
    if (lower.contains('จาก ttb') || lower.contains('จาก tmb') || lower.contains('จาก ทีทีบี')) {
      return false;
    }
    return lower.contains('ttb') ||
        lower.contains('tmb') ||
        lower.contains('ทีทีบี') ||
        lower.contains('ทหารไทยธนชาต');
  }

  static final RegExp _accountMaskRegex = RegExp(
    r'(?:บ\/ช|บช\.|บัญชี|เข้า\/ช|เข้าบ\/ช|โอนเข้า\/ช|เข้า|จาก|ไปยังบ\/ช|ไปยัง)\s*([0-9xX\-]*[0-9]{3,}[0-9xX\-]*)',
    caseSensitive: false,
  );
  static final RegExp _merchantRegex = RegExp(
    r'(?:ให้แก่|ให้กับ|ให้|ไปยังบ\/ช|ไปยังบช\.|ไปยัง|ไป|ที่ร้าน|ชำระค่าสินค้าที่|ชำระให้)\s*([A-Za-z0-9\u0E00-\u0E7F\s\.\-]+?)(?=\s*(?:ยอดคงเหลือ|คงเหลือ|เหลือ|เห\.\.\.|\.\.\.|จำนวน|ยอด|ผ่าน|สำเร็จ|เข้า)|$)',
    caseSensitive: false,
  );
  static final RegExp _senderRegex = RegExp(
    r'(?:จาก|โอนจาก|รับจาก|ผู้โอน)\s*([A-Za-z0-9\u0E00-\u0E7F\s\.\-]+?)(?=\s*(?:ยอดคงเหลือ|คงเหลือ|เหลือ|เห\.\.\.|\.\.\.|จำนวน|ยอด|เข้า)|$)',
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
    final amount = extractAmountByBank(bankId: bankId, type: type, text: fullText);
    if (amount == null || amount <= 0) return null;

    // 3. Account Mask
    String? mask;
    final maskMatch = _accountMaskRegex.firstMatch(fullText);
    if (maskMatch != null) {
      final raw = maskMatch.group(1)?.replaceAll('-', '').trim() ?? '';
      final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length >= 4) {
        mask = 'x-${digits.substring(digits.length - 4)}';
      } else if (raw.isNotEmpty) {
        mask = 'x-$raw';
      }
    }

    // 4. Counterparty (Merchant or Sender)
    String? merchantOrSender;
    if (type == TransactionType.income) {
      final match = _senderRegex.firstMatch(fullText);
      if (match != null) {
        var raw = match.group(1)?.trim();
        if (raw != null && raw.isNotEmpty) {
          raw = raw.replaceAll(RegExp(r'\s*(?:เห\.\.\.|\.\.\.|เห).*$'), '').trim();
          raw = raw.replaceAll(RegExp(r'^(?:บ\/ช|บช\.)\s*'), '').trim();
          if (raw.isNotEmpty && raw.length < 60 && !raw.startsWith('x-') && !raw.startsWith('xx')) {
            merchantOrSender = raw;
          }
        }
      }
    } else {
      final match = _merchantRegex.firstMatch(fullText);
      if (match != null) {
        var raw = match.group(1)?.trim();
        if (raw != null && raw.isNotEmpty) {
          raw = raw.replaceAll(RegExp(r'\s*(?:เห\.\.\.|\.\.\.|เห).*$'), '').trim();
          raw = raw.replaceAll(RegExp(r'^(?:บ\/ช|บช\.)\s*'), '').trim();
          if (raw.isNotEmpty && raw.length < 60) {
            merchantOrSender = raw;
          }
        }
      }
    }

    // Extract clean display title if bank prefix exists (e.g. "KBANK X2875 นาย ปัณณทัต สมา" -> "นาย ปัณณทัต สมา")
    String? cleanName;
    if (merchantOrSender != null) {
      final nameMatch = RegExp(r'^(?:[A-Za-z0-9]+\s+[A-Za-z0-9\-]+\s+)(.*)$').firstMatch(merchantOrSender);
      if (nameMatch != null && nameMatch.group(1)!.trim().isNotEmpty) {
        cleanName = nameMatch.group(1)!.trim();
      } else {
        cleanName = merchantOrSender;
      }
    }

    // 5. Title
    String txTitle;
    if (cleanName != null && cleanName.isNotEmpty) {
      txTitle = cleanName;
    } else if (lower.contains('โอนเงินออก') || lower.contains('โอนเงิน') || lower.contains('แจ้งรายการโอนเงิน')) {
      txTitle = 'โอนเงิน';
    } else if (type == TransactionType.income) {
      txTitle = 'เงินเข้า (ttb touch)';
    } else {
      txTitle = 'โอนเงิน/ชำระ (ttb touch)';
    }

    final category = suggestCategory(fullText, type, merchantOrSender);
    final parsedTime = extractThaiDateTime(fullText);
    final notifTime = parsedTime ?? timestamp ?? DateTime.now();
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
