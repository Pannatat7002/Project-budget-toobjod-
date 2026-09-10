import '../../../../core/constants/app_constants.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../domain/entities/detected_transaction.dart';

abstract class BankParserStrategy {
  String get bankId;
  String get bankName;
  String get shortName;
  int get brandColor;

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

  static final List<RegExp> commonAmountRegexes = [
    RegExp(r'(?:จำนวน|ยอดเงิน|ยอด|เงิน|฿|THB|thb|โอน/ถอน|ถอน/โอน|โอน|รับ|จ่าย|หัก|ฝาก)?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)\s*(?:บาท|บ\.|THB|thb|฿|baht)', caseSensitive: false),
    RegExp(r'(?:โอน/ถอน|ถอน/โอน|โอนเงิน|รับเงิน|ชำระ|จ่าย|หัก|เงินเข้า|เงินออก|โอน|ถอน|ฝาก|ยอด|บช\.)\s*(?:จำนวน|เป็นจำนวน|ยอด)?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)', caseSensitive: false),
    RegExp(r'(?:฿|\$)\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)'),
    RegExp(r'([0-9]{1,3}(?:,[0-9]{3})*\.[0-9]{2})'),
  ];

  double? extractAmountCommon(String text) {
    for (final reg in commonAmountRegexes) {
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
}
