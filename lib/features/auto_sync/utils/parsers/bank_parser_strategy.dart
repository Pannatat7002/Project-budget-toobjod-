import '../../../../core/constants/app_constants.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../domain/entities/detected_transaction.dart';
import '../rules/bank_pattern_rules.dart';

abstract class BankParserStrategy {
  String get bankId;
  String get bankName;
  String get shortName;
  int get brandColor;

  /// Exact package names associated with this bank
  List<String> get supportedPackages => const [];

  /// Whether this strategy can parse notifications for the given package or content
  bool canHandle(String packageName, String text);

  /// Parse the notification into a DetectedTransaction
  DetectedTransaction? parse({
    String? id,
    required String packageName,
    required String title,
    required String text,
    String? subText,
    DateTime? timestamp,
  });

  /// Common helper: Suggest Smart Category
  CategoryItem suggestCategory(String fullText, TransactionType type, String? merchant) {
    final text = '${fullText.toLowerCase()} ${merchant?.toLowerCase() ?? ''}';

    if (type == TransactionType.income) {
      if (text.contains('เงินเดือน') || text.contains('salary') || text.contains('payroll') || text.contains('ค่าจ้าง') || text.contains('บจก') || text.contains('บริษัท')) {
        return findIncomeCategory('salary');
      } else if (text.contains('โบนัส') || text.contains('bonus') || text.contains('คอมมิชชัน') || text.contains('commission')) {
        return findIncomeCategory('bonus');
      } else if (text.contains('ปันผล') || text.contains('dividend') || text.contains('ดอกเบี้ย') || text.contains('interest') || text.contains('กำไร')) {
        return findIncomeCategory('investment');
      } else if (text.contains('ฟรีแลนซ์') || text.contains('freelance') || text.contains('งานเสริม') || text.contains('ค่าบริการ')) {
        return findIncomeCategory('freelance');
      }
      return findIncomeCategory('other_income');
    } else {
      if (text.contains('7-eleven') || text.contains('เซเว่น') || text.contains('grabfood') || text.contains('lineman') ||
          text.contains('foodpanda') || text.contains('robinhood') || text.contains('shopeefood') || text.contains('cafe') ||
          text.contains('amazon') || text.contains('starbucks') || text.contains('kfc') || text.contains('mcdonald') ||
          text.contains('shabu') || text.contains('mk') || text.contains('ร้านอาหาร') || text.contains('ก๋วยเตี๋ยว') ||
          text.contains('ชาไข่มุก') || text.contains('หมูกระทะ') || text.contains('coffee') || text.contains('อาหาร') ||
          text.contains('ข้าว') || text.contains('ขนม') || text.contains('ชาบู')) {
        return findExpenseCategory('food');
      }
      if (text.contains('ptt') || text.contains('or ') || text.contains('bangchak') || text.contains('shell') ||
          text.contains('caltex') || text.contains('ปั๊ม') || text.contains('น้ำมัน') || text.contains('bts') ||
          text.contains('mrt') || text.contains('tollway') || text.contains('ทางด่วน') || text.contains('easy pass') ||
          text.contains('m-flow') || text.contains('grab') || text.contains('bolt') || text.contains('taxi') ||
          text.contains('วินมอเตอร์ไซค์') || text.contains('ค่าน้ำมัน')) {
        return findExpenseCategory('transport');
      }
      if (text.contains('pea') || text.contains('mea') || text.contains('mwa') || text.contains('pwa') ||
          text.contains('กฟภ') || text.contains('กฟน') || text.contains('กปภ') || text.contains('กปน') ||
          text.contains('ค่าไฟ') || text.contains('ค่าน้ำ') || text.contains('ais') || text.contains('truemove') ||
          text.contains('truevisions') || text.contains('ทรูมูฟ') || text.contains('true online') ||
          text.contains('dtac') || text.contains('3bb') || text.contains('nt') || text.contains('เน็ต') ||
          text.contains('wifi') || text.contains('ค่าเช่า') || text.contains('ค่าส่วนกลาง')) {
        return findExpenseCategory('bills');
      }
      if (text.contains('บัตรเครดิต') || text.contains('credit card') || text.contains('ktc') || text.contains('aeon') ||
          text.contains('first choice') || text.contains('citi') || text.contains('สินเชื่อ') || text.contains('ผ่อน') ||
          text.contains('ชำระหนี้') || text.contains('ค่างวด') || text.contains('loan')) {
        return findExpenseCategory('debts');
      }
      if (text.contains('shopee') || text.contains('lazada') || text.contains('tiktok') || text.contains('central') ||
          text.contains('lotus') || text.contains('big c') || text.contains('cj express') || text.contains('tops') ||
          text.contains('makro') || text.contains('watson') || text.contains('boots') || text.contains('uniqlo') ||
          text.contains('ikea') || text.contains('homepro') || text.contains('ของใช้') || text.contains('ซื้อของ')) {
        return findExpenseCategory('shopping');
      }
      if (text.contains('netflix') || text.contains('spotify') || text.contains('youtube') || text.contains('disney') ||
          text.contains('steam') || text.contains('major') || text.contains('sf cinema') || text.contains('ตั๋วหนัง') ||
          text.contains('ท่องเที่ยว') || text.contains('โรงแรม') || text.contains('agoda') || text.contains('booking')) {
        return findExpenseCategory('entertainment');
      }
      if (text.contains('โรงพยาบาล') || text.contains('คลินิก') || text.contains('ร้านยา') || text.contains('ฟาสิโน') ||
          text.contains('doctor') || text.contains('hospital') || text.contains('clinic') || text.contains('pharmacy') ||
          text.contains('ยา') || text.contains('ทันตกรรม')) {
        return findExpenseCategory('health');
      }
      if (text.contains('กองทุน') || text.contains('ออมหุ้น') || text.contains('dime') || text.contains('innovestx') ||
          text.contains('bitkub') || text.contains('binance') || text.contains('ซื้อทอง') || text.contains('ออมทอง') ||
          text.contains('ฝากประจำ')) {
        return findExpenseCategory('savings');
      }
      return findExpenseCategory('other');
    }
  }

  static CategoryItem findExpenseCategory(String id) {
    return AppConstants.defaultExpenseCategories.firstWhere(
      (c) => c.id == id,
      orElse: () => AppConstants.defaultExpenseCategories.firstWhere(
        (c) => c.id == 'other',
        orElse: () => AppConstants.defaultExpenseCategories.first,
      ),
    );
  }

  static CategoryItem findIncomeCategory(String id) {
    return AppConstants.defaultIncomeCategories.firstWhere(
      (c) => c.id == id,
      orElse: () => AppConstants.defaultIncomeCategories.first,
    );
  }

  static final RegExp _balanceRegex = RegExp(
    r'(?:ยอดคงเหลือ|คงเหลือ|เหลือ)\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)\s*(?:บาท|บ\.|฿|THB)?',
    caseSensitive: false,
  );

  static final List<RegExp> commonAmountRegexes = [
    RegExp(r'(?:จำนวนเงิน|จำนวน|ยอดเงิน|ยอด|เงิน|฿|THB|thb|โอน/ถอน|ถอน/โอน|โอน|รับ|จ่าย|หัก|ฝาก)\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)\s*(?:บาท|บ\.|THB|thb|฿|baht)?', caseSensitive: false),
    RegExp(r'(?:โอนเงิน|มีเงิน|เงินเข้า|เงินออก)\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)\s*(?:บาท|บ\.|THB|thb|฿|baht)', caseSensitive: false),
    RegExp(r'([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)\s*(?:บาท|บ\.|THB|thb|฿|baht)', caseSensitive: false),
    RegExp(r'(?:โอน/ถอน|ถอน/โอน|โอนเงิน|รับเงิน|ชำระ|จ่าย|หัก|เงินเข้า|เงินออก|โอน|ถอน|ฝาก|ยอด|บช\.)\s*(?:จำนวน|เป็นจำนวน|ยอด)?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)', caseSensitive: false),
    RegExp(r'(?:฿|\$)\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)'),
    RegExp(r'([0-9]{1,3}(?:,[0-9]{3})*\.[0-9]{2})'),
  ];

  /// Extract the transaction amount specifically using the bank's own Income/Expense rules
  double? extractAmountByBank({
    required String bankId,
    required TransactionType type,
    required String text,
  }) {
    return BankPatternRules.extractAmount(
      bankId: bankId,
      type: type,
      text: text,
    );
  }

  /// Extract the transaction amount using general fallback
  double? extractAmountCommon(String text) {
    return BankPatternRules.extractCommonAmount(text);
  }

  /// Extract remaining balance if present in notification text (e.g. เหลือ371.00บ., ยอดคงเหลือ 45,650.00 บ.)
  double? extractRemainingBalance(String text) {
    final match = _balanceRegex.firstMatch(text);
    if (match != null) {
      final rawStr = match.group(1)?.replaceAll(',', '').trim();
      if (rawStr != null) {
        return double.tryParse(rawStr);
      }
    }
    return null;
  }

  static const Map<String, int> _thaiMonths = {
    'ม.ค.': 1, 'มกราคม': 1,
    'ก.พ.': 2, 'กุมภาพันธ์': 2,
    'มี.ค.': 3, 'มีนาคม': 3,
    'เม.ย.': 4, 'เมษายน': 4,
    'พ.ค.': 5, 'พฤษภาคม': 5,
    'มิ.ย.': 6, 'มิถุนายน': 6,
    'ก.ค.': 7, 'กรกฎาคม': 7,
    'ส.ค.': 8, 'สิงหาคม': 8,
    'ก.ย.': 9, 'กันยายน': 9,
    'ต.ค.': 10, 'ตุลาคม': 10,
    'พ.ย.': 11, 'พฤศจิกายน': 11,
    'ธ.ค.': 12, 'ธันวาคม': 12,
  };

  static final RegExp _kplusDateRegex = RegExp(
    r'(?:วันที่\s*)?([0-9]{1,2})\s*(ม\.ค\.|ก\.พ\.|มี\.ค\.|เม\.ย\.|พ\.ค\.|มิ\.ย\.|ก\.ค\.|ส\.ค\.|ก\.ย\.|ต\.ค\.|พ\.ย\.|ธ\.ค\.|มกราคม|กุมภาพันธ์|มีนาคม|เมษายน|พฤษภาคม|มิถุนายน|กรกฎาคม|สิงหาคม|กันยายน|ตุลาคม|พฤศจิกายน|ธันวาคม)\s*([0-9]{2,4})\s*(?:เวลา\s*)?([0-9]{1,2}):([0-9]{2})',
    caseSensitive: false,
  );

  static final RegExp _ttbDateRegex = RegExp(
    r'([0-9]{1,2})/([0-9]{1,2})/([0-9]{2,4})@([0-9]{1,2}):([0-9]{2})',
  );

  /// Extract DateTime from Thai notification strings (e.g. K PLUS or ttb touch)
  DateTime? extractThaiDateTime(String text) {
    // Check K PLUS format: วันที่ 12 ก.ย. 69 17:39 น.
    final kMatch = _kplusDateRegex.firstMatch(text);
    if (kMatch != null) {
      final day = int.tryParse(kMatch.group(1) ?? '');
      final monthStr = kMatch.group(2);
      final month = monthStr != null ? _thaiMonths[monthStr] : null;
      var year = int.tryParse(kMatch.group(3) ?? '');
      final hour = int.tryParse(kMatch.group(4) ?? '');
      final minute = int.tryParse(kMatch.group(5) ?? '');

      if (day != null && month != null && year != null && hour != null && minute != null) {
        if (year < 100) {
          year += 2500; // e.g. 69 -> 2569
        }
        if (year >= 2400) {
          year -= 543; // Convert Buddhist Year (BE) to Common Era (CE)
        }
        return DateTime(year, month, day, hour, minute);
      }
    }

    // Check ttb touch format: 12/09/26@17:39 (DD/MM/YY@HH:mm)
    final tMatch = _ttbDateRegex.firstMatch(text);
    if (tMatch != null) {
      final day = int.tryParse(tMatch.group(1) ?? '');
      final month = int.tryParse(tMatch.group(2) ?? '');
      var year = int.tryParse(tMatch.group(3) ?? '');
      final hour = int.tryParse(tMatch.group(4) ?? '');
      final minute = int.tryParse(tMatch.group(5) ?? '');

      if (day != null && month != null && year != null && hour != null && minute != null) {
        if (year < 100) {
          year += 2000; // e.g. 26 -> 2026
        } else if (year >= 2500) {
          year -= 543;
        }
        return DateTime(year, month, day, hour, minute);
      }
    }

    return null;
  }
}
