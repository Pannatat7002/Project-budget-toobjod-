import '../../../core/constants/app_constants.dart';
import '../../transactions/domain/entities/transaction_entity.dart';
import '../domain/entities/bank_profile.dart';
import '../domain/entities/detected_transaction.dart';

import 'parsers/bank_parser_registry.dart';

class ThaiBankParser {
  /// Parse a notification into a DetectedTransaction
  static DetectedTransaction? parse({
    String? id,
    required String packageName,
    required String title,
    required String text,
    String? subText,
    DateTime? timestamp,
  }) {
    // 1. Primary: Use dedicated bank parser strategies
    final strategyResult = BankParserRegistry.parse(
      id: id,
      packageName: packageName,
      title: title,
      text: text,
      subText: subText,
      timestamp: timestamp,
    );
    if (strategyResult != null) {
      return strategyResult;
    }

    // 2. Fallback to generic parsing logic
    var bank = BankProfile.findByPackage(packageName);
    if (bank == null) {
      final lower = '$title $text'.toLowerCase();
      if (lower.contains('k plus') || lower.contains('kbank') || lower.contains('กสิกร') ||
          lower.contains('รายการโอน/ถอน') || lower.contains('ถอนเงินไม่ใช้บัตร')) {
        bank = BankProfile.findById('kbank');
      } else if (lower.contains('scb') || lower.contains('ไทยพาณิชย์') || lower.contains('แม่มณี')) {
        bank = BankProfile.findById('scb');
      } else if (lower.contains('krungthai') || lower.contains('กรุงไทย') || lower.contains('next')) {
        bank = BankProfile.findById('ktb');
      } else if (lower.contains('ttb') || lower.contains('ทีทีบี')) {
        bank = BankProfile.findById('ttb');
      } else if (lower.contains('kma') || lower.contains('กรุงศรี')) {
        bank = BankProfile.findById('kma');
      } else if (lower.contains('truemoney') || lower.contains('ทรูมันนี่')) {
        bank = BankProfile.findById('truemoney');
      } else if (lower.contains('make') || lower.contains('เมค')) {
        bank = BankProfile.findById('make_kbank');
      } else if (lower.contains('เป๋าตัง') || lower.contains('paotang') || lower.contains('g-wallet')) {
        bank = BankProfile.findById('paotang');
      }
    }

    final bankName = bank?.name ?? 'ธนาคาร/E-Wallet';
    final bankShortName = bank?.shortName ?? 'Bank';
    final bankColor = bank?.brandColor ?? 0xFF2563EB;

    final fullText = '$title $text ${subText ?? ''}'.trim();
    if (fullText.isEmpty) return null;

    // 1. Detect Transaction Type
    final type = _detectTransactionType(fullText);
    if (type == null) return null;

    // 2. Extract Amount
    final amount = _extractAmount(fullText);
    if (amount == null || amount <= 0) return null;

    // 3. Extract Merchant or Sender
    final merchant = _extractMerchantOrCounterparty(fullText, type);

    // 4. Suggest Smart Category
    final category = _suggestCategory(fullText, type, merchant);

    // 5. Smart Title (นำชื่อร้านค้า/ผู้รับ/ผู้โอนมาเป็นชื่อรายการเพื่อความเป็นระเบียบ)
    final finalTitle = (merchant != null && merchant.isNotEmpty)
        ? merchant
        : _generateTitle(type, merchant, bankShortName, title.trim(), fullText);

    final notifTime = timestamp ?? DateTime.now();
    final timeBucket = notifTime.millisecondsSinceEpoch ~/ 4000;
    final uniqueId = (id != null && id.isNotEmpty)
        ? id
        : 'tx_${packageName.replaceAll('.', '_')}_${timeBucket}_${amount.toStringAsFixed(2)}_${type.name}';

    return DetectedTransaction(
      id: uniqueId,
      packageName: bank?.packageName ?? packageName,
      bankName: bankName,
      bankShortName: bankShortName,
      bankColorValue: bankColor,
      amount: amount,
      type: type,
      title: finalTitle,
      suggestedCategoryId: category.id,
      suggestedCategoryName: category.name,
      suggestedCategoryIconCode: category.iconCode,
      suggestedCategoryColorValue: category.colorValue,
      merchantOrSender: merchant,
      rawTitle: title,
      rawText: text, // text เป็นรายละเอียด
      timestamp: notifTime,
    );
  }

  /// Check if the notification text indicates an explicit merchant purchase, bill payment, or QR payment
  /// to prevent false positives when matching internal self-transfers.
  static bool isExplicitMerchantOrBill(String text) {
    if (text.isEmpty) return false;
    final lower = text.toLowerCase();
    const merchantKeywords = [
      'ชำระค่าสินค้า',
      'ชำระค่าบริการ',
      'จ่ายบิล',
      'บิล',
      'bill',
      'payment',
      'merchant',
      'ร้านค้า',
      'ร้าน',
      '7-eleven',
      'เซเว่น',
      'shopee',
      'lazada',
      'grab',
      'lineman',
      'foodpanda',
      'lotus',
      'big c',
      'tops',
      'cpm',
      'ค่าไฟฟ้า',
      'ค่าน้ำ',
      'ค่าโทรศัพท์',
      'บัตรเครดิต',
      'credit card',
      'สแกนจ่ายร้าน',
      'ชำระให้',
      'ซื้อสินค้า',
    ];
    return merchantKeywords.any((kw) => lower.contains(kw));
  }

  /// Detect Income or Expense from Thai text keywords
  static TransactionType? _detectTransactionType(String text) {
    final lower = text.toLowerCase();

    // Specific Income patterns
    final incomeKeywords = [
      'เงินเข้า',
      'โอนเข้า',
      'รับเงิน',
      'ได้รับเงิน',
      'ได้รับเงินโอน',
      'ฝากเงิน',
      'โอนเงินเข้าบัญชี',
      'มีเงินโอนเข้า',
      'รับโอน',
      'รับโอนเงิน',
      'พร้อมเพย์เข้า',
      'เงินเข้าบัญชี',
      'ยอดเงินเข้า',
      'เงินปันผล',
      'คืนเงิน',
      'refund',
      'cashback',
      'received',
      'money received',
      'deposit',
      'เงินเดือน',
      'ค่าจ้าง',
      'ยอดเงินโอนเข้า',
      'รับชำระ',
      'แม่มณี',
      'qr รับเงิน',
      'รายการเงินเข้า',
      'รายการรับเงิน',
    ];

    // Specific Expense patterns
    final expenseKeywords = [
      'เงินออก',
      'รายการโอน/ถอน',
      'รายการโอน',
      'รายการถอน',
      'โอน/ถอน',
      'ถอน/โอน',
      'โอนเงิน',
      'ท่านได้โอนเงิน',
      'คุณได้โอนเงิน',
      'โอนออก',
      'ชำระเงิน',
      'ชำระค่า',
      'จ่ายเงิน',
      'ซื้อสินค้า',
      'หักบัญชี',
      'หักเงิน',
      'ตัดบัญชี',
      'ชำระค่าสินค้า',
      'ถอนเงิน',
      'จ่ายบิล',
      'payment',
      'transfer to',
      'paid',
      'spent',
      'successful transfer',
      'โอนให้',
      'ชำระให้',
      'เติมเงิน',
      'ยอดใช้จ่าย',
      'ใช้จ่าย',
      'สแกนจ่าย',
      'ชำระสำเร็จ',
      'โอนสำเร็จ',
      'ทำรายการโอน',
      'ทำรายการสำเร็จ',
      'หักค่าธรรมเนียม',
      'หักค่าบริการ',
      'ชำระด้วย',
      'จ่ายด้วย',
      'หักจากบัญชี',
      'โอนไปยัง',
      'โอนไป',
    ];

    // Check income first if strong match
    for (final kw in incomeKeywords) {
      if (lower.contains(kw)) {
        // Prevent false positive if it also says "โอนเงินเข้าบัญชี xxx ของท่านสำเร็จ" (outgoing transfer to someone's account)
        if (lower.contains('โอนเงินไป') || lower.contains('ชำระเงินให้') || lower.contains('โอนออก')) {
          return TransactionType.expense;
        }
        return TransactionType.income;
      }
    }

    // Check expense
    for (final kw in expenseKeywords) {
      if (lower.contains(kw)) {
        return TransactionType.expense;
      }
    }

    return null;
  }

  // Precompiled Regexes for zero-allocation parsing performance
  static final List<RegExp> _amountRegexes = [
    RegExp(r'(?:จำนวน|ยอดเงิน|ยอด|เงิน|฿|THB|thb|โอน/ถอน|ถอน/โอน|โอน|รับ|จ่าย|หัก|ฝาก)?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)\s*(?:บาท|บ\.|THB|thb|฿|baht)', caseSensitive: false),
    RegExp(r'(?:โอน/ถอน|ถอน/โอน|โอนเงิน|รับเงิน|ชำระ|จ่าย|หัก|เงินเข้า|เงินออก|โอน|ถอน|ฝาก|ยอด|บช\.)\s*(?:จำนวน|เป็นจำนวน|ยอด)?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)', caseSensitive: false),
    RegExp(r'(?:฿|\$)\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)'),
    RegExp(r'([0-9]{1,3}(?:,[0-9]{3})*\.[0-9]{2})'),
  ];

  static final List<RegExp> _merchantRegexes = [
    RegExp(
      r'(?:ชำระเงิน|ชำระค่าสินค้า|ชำระค่าบริการ|ซื้อสินค้าที่|จ่ายที่|สแกนจ่ายที่|สแกนจ่าย)\s*(?:ให้แก่|ให้กับ|ให้|ไปยัง|ไป)?\s*([A-Za-z0-9\u0E00-\u0E7F\s\.\-]+?)(?:\s+(?:จำนวนเงิน|จำนวน|ยอดเงิน|ยอด|เป็นจำนวน)\s*|\s+[0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?\s*(?:บาท|บ\.|฿|thb)|\s*(?:สำเร็จ|เรียบร้อย|เมื่อ|เวลา|วันที่)|$)',
      caseSensitive: false,
    ),
    RegExp(
      r'(?:จ่ายเงิน|โอนเงิน|ชำระเงิน)\s*(?:ให้แก่|ให้กับ|ให้|ไปยัง|ไป)\s*([A-Za-z0-9\u0E00-\u0E7F\s\.\-]+?)(?:\s+(?:จำนวนเงิน|จำนวน|ยอดเงิน|ยอด|เป็นจำนวน)\s*|\s+[0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?\s*(?:บาท|บ\.|฿|thb)|\s*(?:สำเร็จ|เรียบร้อย|เมื่อ|เวลา|วันที่)|$)',
      caseSensitive: false,
    ),
    RegExp(
      r'(?:ไปยัง|ให้แก่|ให้กับ|โอนไป)\s*([A-Za-z0-9\u0E00-\u0E7F\s\.\-]+?)(?:\s+(?:จำนวนเงิน|จำนวน|ยอดเงิน|ยอด|เป็นจำนวน)\s*|\s+[0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?\s*(?:บาท|บ\.|฿|thb)|\s*(?:สำเร็จ|เรียบร้อย|เมื่อ|เวลา|วันที่)|$)',
      caseSensitive: false,
    ),
    RegExp(
      r'(?:จาก|รับจาก|ผู้โอน|โอนจาก)\s*([A-Za-z0-9\u0E00-\u0E7F\s\.\-]+?)(?:\s+(?:จำนวนเงิน|จำนวน|ยอดเงิน|ยอด|เป็นจำนวน)\s*|\s+[0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?\s*(?:บาท|บ\.|฿|thb)|\s*(?:สำเร็จ|เรียบร้อย|เมื่อ|เวลา|วันที่)|$)',
      caseSensitive: false,
    ),
    RegExp(
      r'(?:ที่ร้าน|ร้านค้า|ร้าน|สาขา)\s*([A-Za-z0-9\u0E00-\u0E7F\s\.\-]+?)(?:\s+(?:จำนวนเงิน|จำนวน|ยอดเงิน|ยอด|เป็นจำนวน)\s*|\s+[0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?\s*(?:บาท|บ\.|฿|thb)|\s*(?:สำเร็จ|เรียบร้อย|เมื่อ|เวลา|วันที่)|$)',
      caseSensitive: false,
    ),
  ];

  static final RegExp _trailingSuffixRegex = RegExp(
    r'\s*(เรียบร้อยแล้ว|เรียบร้อย|สำเร็จ|เสร็จสิ้น|แล้ว|เมื่อ|เวลา|วันที่|ผ่านแอป|ผ่านโมบาย).*$',
    caseSensitive: false,
  );

  static final RegExp _datePrefixRegex = RegExp(
    r'^[0-9]{1,2}\s*(?:ม\.ค\.|ก\.พ\.|มี\.ค\.|เม\.ย\.|พ\.ค\.|มิ\.ย\.|ก\.ค\.|ส\.ค\.|ก\.ย\.|ต\.ค\.|พ\.ย\.|ธ\.ค\.)',
    caseSensitive: false,
  );

  /// Extract monetary amount from text (e.g. 1,500.50 บาท, 250.00 บ., ฿500)
  static double? _extractAmount(String text) {
    for (final reg in _amountRegexes) {
      final match = reg.firstMatch(text);
      if (match != null) {
        final rawStr = match.group(1)?.replaceAll(',', '').trim();
        if (rawStr != null) {
          final val = double.tryParse(rawStr);
          if (val != null && val > 0 && val < 100000000) {
            return val;
          }
        }
      }
    }

    return null;
  }

  /// Extract merchant, counterparty, or recipient
  static String? _extractMerchantOrCounterparty(String text, TransactionType type) {
    const invalidMerchants = {'ให้แก่', 'ให้กับ', 'ไปยัง', 'ให้', 'ไป', 'สำเร็จ', 'เรียบร้อย', 'วันที่'};

    for (final reg in _merchantRegexes) {
      final match = reg.firstMatch(text);
      if (match != null) {
        var result = match.group(1)?.trim();
        if (result != null && result.isNotEmpty) {
          // Clean common trailing status words
          result = result.replaceAll(_trailingSuffixRegex, '').trim();
          if (result.isNotEmpty &&
              result.length < 50 &&
              !invalidMerchants.contains(result) &&
              !_datePrefixRegex.hasMatch(result)) {
            return result;
          }
        }
      }
    }

    return null;
  }

  /// Suggest Smart Category based on Thai keywords & merchant name
  static CategoryItem _suggestCategory(String fullText, TransactionType type, String? merchant) {
    final text = '${fullText.toLowerCase()} ${merchant?.toLowerCase() ?? ''}';

    if (type == TransactionType.income) {
      if (text.contains('เงินเดือน') || text.contains('salary') || text.contains('payroll') || text.contains('ค่าจ้าง') || text.contains('บจก') || text.contains('บริษัท')) {
        return _findIncomeCategory('salary');
      } else if (text.contains('โบนัส') || text.contains('bonus') || text.contains('คอมมิชชัน') || text.contains('commission')) {
        return _findIncomeCategory('bonus');
      } else if (text.contains('ปันผล') || text.contains('dividend') || text.contains('ดอกเบี้ย') || text.contains('interest') || text.contains('กำไร')) {
        return _findIncomeCategory('investment');
      } else if (text.contains('ฟรีแลนซ์') || text.contains('freelance') || text.contains('งานเสริม') || text.contains('ค่าบริการ')) {
        return _findIncomeCategory('freelance');
      }
      return _findIncomeCategory('other_income');
    } else {
      // Expense matching
      // 1. Food & Drinks
      if (text.contains('7-eleven') || text.contains('เซเว่น') || text.contains('grabfood') || text.contains('lineman') ||
          text.contains('foodpanda') || text.contains('robinhood') || text.contains('shopeefood') || text.contains('cafe') ||
          text.contains('amazon') || text.contains('starbucks') || text.contains('kfc') || text.contains('mcdonald') ||
          text.contains('shabu') || text.contains('mk') || text.contains('ร้านอาหาร') || text.contains('ก๋วยเตี๋ยว') ||
          text.contains('ชาไข่มุก') || text.contains('หมูกระทะ') || text.contains('coffee') || text.contains('อาหาร') ||
          text.contains('ข้าว') || text.contains('ขนม') || text.contains('ชาบู')) {
        return _findExpenseCategory('food');
      }

      // 2. Transport & Fuel
      if (text.contains('ptt') || text.contains('or ') || text.contains('bangchak') || text.contains('shell') ||
          text.contains('caltex') || text.contains('ปั๊ม') || text.contains('น้ำมัน') || text.contains('bts') ||
          text.contains('mrt') || text.contains('tollway') || text.contains('ทางด่วน') || text.contains('easy pass') ||
          text.contains('m-flow') || text.contains('grab') || text.contains('bolt') || text.contains('taxi') ||
          text.contains('วินมอเตอร์ไซค์') || text.contains('ค่าน้ำมัน')) {
        return _findExpenseCategory('transport');
      }

      // 3. Bills & Utilities
      if (text.contains('pea') || text.contains('mea') || text.contains('mwa') || text.contains('pwa') ||
          text.contains('กฟภ') || text.contains('กฟน') || text.contains('กปภ') || text.contains('กปน') ||
          text.contains('ค่าไฟ') || text.contains('ค่าน้ำ') || text.contains('ais') || text.contains('truemove') ||
          text.contains('truevisions') || text.contains('ทรูมูฟ') || text.contains('true online') ||
          text.contains('dtac') || text.contains('3bb') || text.contains('nt') || text.contains('เน็ต') ||
          text.contains('wifi') || text.contains('ค่าเช่า') || text.contains('ค่าส่วนกลาง')) {
        return _findExpenseCategory('bills');
      }

      // 4. Debts & Credit Cards
      if (text.contains('บัตรเครดิต') || text.contains('credit card') || text.contains('ktc') || text.contains('aeon') ||
          text.contains('first choice') || text.contains('citi') || text.contains('สินเชื่อ') || text.contains('ผ่อน') ||
          text.contains('ชำระหนี้') || text.contains('ค่างวด') || text.contains('loan')) {
        return _findExpenseCategory('debts');
      }

      // 5. Shopping
      if (text.contains('shopee') || text.contains('lazada') || text.contains('tiktok') || text.contains('central') ||
          text.contains('lotus') || text.contains('big c') || text.contains('cj express') || text.contains('tops') ||
          text.contains('makro') || text.contains('watson') || text.contains('boots') || text.contains('uniqlo') ||
          text.contains('ikea') || text.contains('homepro') || text.contains('ของใช้') || text.contains('ซื้อของ')) {
        return _findExpenseCategory('shopping');
      }

      // 6. Entertainment
      if (text.contains('netflix') || text.contains('spotify') || text.contains('youtube') || text.contains('disney') ||
          text.contains('steam') || text.contains('major') || text.contains('sf cinema') || text.contains('ตั๋วหนัง') ||
          text.contains('ท่องเที่ยว') || text.contains('โรงแรม') || text.contains('agoda') || text.contains('booking')) {
        return _findExpenseCategory('entertainment');
      }

      // 7. Health
      if (text.contains('โรงพยาบาล') || text.contains('คลินิก') || text.contains('ร้านยา') || text.contains('ฟาสิโน') ||
          text.contains('doctor') || text.contains('hospital') || text.contains('clinic') || text.contains('pharmacy') ||
          text.contains('ยา') || text.contains('ทันตกรรม')) {
        return _findExpenseCategory('health');
      }

      // 8. Savings & Investments
      if (text.contains('กองทุน') || text.contains('ออมหุ้น') || text.contains('dime') || text.contains('innovestx') ||
          text.contains('bitkub') || text.contains('binance') || text.contains('ซื้อทอง') || text.contains('ออมทอง') ||
          text.contains('ฝากประจำ')) {
        return _findExpenseCategory('savings');
      }

      // 9. ATM / Cash Withdrawals
      if (text.contains('ถอนเงิน') || text.contains('ถอนเงินสด') || text.contains('ถอนเงินไม่ใช้บัตร') ||
          text.contains('กดเงิน') || text.contains('atm')) {
        return _findExpenseCategory('other');
      }

      // 10. Transfers to person / P2P Transfers
      if (text.contains('โอนเงินไป') || text.contains('โอนไปยัง') || text.contains('โอนให้') ||
          text.contains('พร้อมเพย์') || text.contains('รายการโอน') || text.contains('promptpay')) {
        return _findExpenseCategory('other');
      }

      return _findExpenseCategory('other'); // Default expense fallback to อื่นๆ
    }
  }

  static CategoryItem _findExpenseCategory(String id) {
    return AppConstants.defaultExpenseCategories.firstWhere(
      (c) => c.id == id,
      orElse: () => AppConstants.defaultExpenseCategories.firstWhere(
        (c) => c.id == 'other',
        orElse: () => AppConstants.defaultExpenseCategories.first,
      ),
    );
  }

  static CategoryItem _findIncomeCategory(String id) {
    return AppConstants.defaultIncomeCategories.firstWhere(
      (c) => c.id == id,
      orElse: () => AppConstants.defaultIncomeCategories.first,
    );
  }

  static String _generateTitle(TransactionType type, String? merchant, String bankShortName, [String? rawTitle, String? fullText]) {
    if (merchant != null && merchant.isNotEmpty) {
      return merchant;
    }
    final textToCheck = '${rawTitle ?? ''} ${fullText ?? ''}'.toLowerCase();
    if (textToCheck.contains('ถอนเงินไม่ใช้บัตร')) {
      return 'ถอนเงินไม่ใช้บัตร';
    }
    if (textToCheck.contains('ถอนเงินสด') || textToCheck.contains('กดเงินสด')) {
      return 'ถอนเงินสด';
    }
    if (rawTitle != null && rawTitle.isNotEmpty) {
      final lower = rawTitle.toLowerCase();
      final isGenericBank = BankProfile.supportedBanks.any(
        (b) => b.shortName.toLowerCase() == lower ||
               b.name.toLowerCase() == lower ||
               lower.contains('k plus') ||
               lower.contains('scb easy') ||
               lower.contains('krungthai') ||
               lower.contains('truemoney') ||
               lower.contains('ttb touch') ||
               lower.contains('kma')
      );
      if (!isGenericBank) {
        return rawTitle;
      }
    }
    if (type == TransactionType.income) {
      return 'เงินเข้า ($bankShortName)';
    } else {
      return 'โอนเงิน/ชำระ ($bankShortName)';
    }
  }
}
