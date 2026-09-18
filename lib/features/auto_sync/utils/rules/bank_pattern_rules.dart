import '../../../transactions/domain/entities/transaction_entity.dart';

/// โครงสร้างหนึ่งรูปแบบการดักจับยอดเงิน (Amount Pattern Rule)
/// ออกแบบให้อ่านเข้าใจง่ายสำหรับทั้ง Developer และ User มีคำอธิบายและตัวอย่างจริงกำกับ
class AmountPattern {
  /// รหัสระบุกฎ เช่น 'kbank_exp_amount_baht'
  final String id;

  /// คำอธิบายภาษาไทย เช่น 'จำนวนเงิน ... บาท (รายการโอน/ถอน)'
  final String label;

  /// รูปแบบ Regular Expression สำหรับดักจับตัวเลขจำนวนเงิน
  final RegExp regex;

  /// ตัวอย่างข้อความแจ้งเตือนจริงที่ใช้กับรูปแบบนี้
  final String example;

  /// คำอธิบายเพิ่มเติมสำหรับ Dev/User (Optional)
  final String? note;

  const AmountPattern({
    required this.id,
    required this.label,
    required this.regex,
    required this.example,
    this.note,
  });

  /// สกัดยอดเงินจากข้อความตาม RegExp ที่กำหนด
  double? extract(String text) {
    final match = regex.firstMatch(text);
    if (match != null) {
      final rawStr = match.group(1)?.replaceAll(',', '').trim();
      if (rawStr != null) {
        final val = double.tryParse(rawStr);
        if (val != null && val > 0 && val < 100000000) {
          return val;
        }
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'pattern': regex.pattern,
    'example': example,
    if (note != null) 'note': note,
  };
}

/// ชุดกฎการดักจับของแต่ละธนาคาร (Bank Rule Set)
/// แบ่งแยกเป็น "เงินออก (Expense)" และ "เงินเข้า (Income)" อย่างชัดเจน
class BankRuleSet {
  final String bankId;
  final String bankName;
  final String shortName;

  /// 🔴 กฎการดักจับยอดเงิน: เงินออก (โอนออก / ถอนเงิน / ชำระสินค้า / จ่ายบิล)
  final List<AmountPattern> expensePatterns;

  /// 🟢 กฎการดักจับยอดเงิน: เงินเข้า (รับโอน / เงินเดือน / เงินเข้าบัญชี / ดอกเบี้ย)
  final List<AmountPattern> incomePatterns;

  /// 💰 กฎการดักจับยอดเงินคงเหลือ (Remaining Balance)
  final List<RegExp> balancePatterns;

  const BankRuleSet({
    required this.bankId,
    required this.bankName,
    required this.shortName,
    required this.expensePatterns,
    required this.incomePatterns,
    this.balancePatterns = const [],
  });

  /// ดึงยอดเงินตามประเภทธุรกรรม (เงินเข้า หรือ เงินออก)
  double? extractAmount(String text, TransactionType type) {
    // 1. นำส่วนที่เป็นยอดเงินคงเหลือออกก่อน เพื่อป้องกันการสับสนกับยอดเงินโอน
    var cleanText = text;
    for (final bReg in balancePatterns) {
      cleanText = cleanText.replaceAll(bReg, ' ');
    }
    // Fallback balance removal
    cleanText = cleanText.replaceAll(
      RegExp(r'(?:ยอดคงเหลือ|คงเหลือ|เหลือ)\s*[0-9,]+(?:\.[0-9]{1,2})?\s*(?:บาท|บ\.|฿|THB)?', caseSensitive: false),
      ' ',
    );

    // 2. เลือกชุดกฎตามประเภทรายการ (เงินเข้า หรือ เงินออก)
    final patterns = type == TransactionType.income ? incomePatterns : expensePatterns;

    for (final p in patterns) {
      final amount = p.extract(cleanText);
      if (amount != null) {
        return amount;
      }
    }

    // 3. หากยังไม่พบ ให้ลองสลับอีกชุดเพื่อความปลอดภัย (กรณีวิเคราะห์ type คลาดเคลื่อน)
    final fallbackPatterns = type == TransactionType.income ? expensePatterns : incomePatterns;
    for (final p in fallbackPatterns) {
      final amount = p.extract(cleanText);
      if (amount != null) {
        return amount;
      }
    }

    // 4. สกัดจากรูปแบบสากล (Global fallback)
    return BankPatternRules.extractCommonAmount(cleanText);
  }

  /// สกัดยอดเงินคงเหลือในบัญชี
  double? extractRemainingBalance(String text) {
    final regexes = [
      ...balancePatterns,
      RegExp(r'(?:ยอดคงเหลือ|คงเหลือ|เหลือ)\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*(?:บาท|บ\.|฿|THB)?', caseSensitive: false),
    ];
    for (final reg in regexes) {
      final match = reg.firstMatch(text);
      if (match != null) {
        final rawStr = match.group(1)?.replaceAll(',', '').trim();
        if (rawStr != null) {
          final val = double.tryParse(rawStr);
          if (val != null && val >= 0) {
            return val;
          }
        }
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'bankId': bankId,
    'bankName': bankName,
    'shortName': shortName,
    'เงินออก (Expense)': expensePatterns.map((p) => p.toJson()).toList(),
    'เงินเข้า (Income)': incomePatterns.map((p) => p.toJson()).toList(),
  };
}

/// ศูนย์รวมกฎการดักจับข้อความแจ้งเตือนของทุกธนาคาร (Bank Pattern Rules Registry)
/// แยกตามธนาคาร และจำแนกเป็น เงินเข้า / เงินออก
class BankPatternRules {
  static final Map<String, BankRuleSet> _bankRules = {
    // -------------------------------------------------------------
    // 🟢 1. ธนาคารกสิกรไทย (K PLUS)
    // -------------------------------------------------------------
    'kbank': BankRuleSet(
      bankId: 'kbank',
      bankName: 'กสิกรไทย (K PLUS)',
      shortName: 'K PLUS',
      expensePatterns: [
        AmountPattern(
          id: 'kbank_exp_standard',
          label: 'จำนวนเงิน ... บาท (รายการโอน/ถอน มาตรฐาน)',
          regex: RegExp(r'จำนวนเงิน\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*บาท'),
          example: 'บัญชี xxx-x-x3287-x จำนวนเงิน 3.00 บาท วันที่ 12 ก.ย. 69 17:32 น.',
          note: 'ใช้กับแจ้งเตือน K PLUS Push notification หัวข้อ รายการโอน/ถอน',
        ),
        AmountPattern(
          id: 'kbank_exp_transfer_person',
          label: 'โอนเงินไปยัง ... X.XX บาท สำเร็จ',
          regex: RegExp(r'โอนเงินไปยัง\s*.+?\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*บาท'),
          example: 'โอนเงินไปยัง นาย สมชาย ใจดี 1,500.00 บาท สำเร็จ',
        ),
        AmountPattern(
          id: 'kbank_exp_merchant',
          label: 'ชำระเงินให้แก่ร้านค้า',
          regex: RegExp(r'(?:ชำระเงินให้แก่|ชำระให้)\s*.+?\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*บาท'),
          example: 'ชำระเงินให้แก่ 7-Eleven สาขาอโศก 89.00 บาท สำเร็จ',
        ),
        AmountPattern(
          id: 'kbank_exp_cardless_atm',
          label: 'ถอนเงินไม่ใช้บัตร',
          regex: RegExp(r'ถอนเงินไม่ใช้บัตร\s*จำนวนเงิน\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*บาท'),
          example: 'ถอนเงินไม่ใช้บัตร จำนวนเงิน 500.00 บาท สำเร็จ',
        ),
      ],
      incomePatterns: [
        AmountPattern(
          id: 'kbank_inc_standard',
          label: 'จำนวนเงิน ... บาท (รายการเงินเข้า มาตรฐาน)',
          regex: RegExp(r'จำนวนเงิน\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*บาท'),
          example: 'บัญชี xxx-x-x3287-x จำนวนเงิน 1.00 บาท วันที่ 12 ก.ย. 69 17:39 น.',
          note: 'ใช้กับแจ้งเตือน K PLUS Push notification หัวข้อ รายการเงินเข้า',
        ),
        AmountPattern(
          id: 'kbank_inc_money_in',
          label: 'เงินเข้า บัญชี ... จำนวนเงิน ... บาท',
          regex: RegExp(r'เงินเข้า\s*(?:บัญชี\s*[0-9xX\-]+)?\s*จำนวนเงิน\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*บาท'),
          example: 'เงินเข้า บัญชี xxx-x-x3287-x จำนวนเงิน 3,500.00 บาท',
        ),
        AmountPattern(
          id: 'kbank_inc_sms',
          label: 'KBANK SMS เงินเข้า',
          regex: RegExp(r'เงินเข้า\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*บ\.'),
          example: 'บช. x-4521 เงินเข้า 3,500.00 บ. จาก นายสมชาย ว.',
        ),
      ],
    ),

    // -------------------------------------------------------------
    // 🔵 2. ธนาคารทหารไทยธนชาต (ttb touch)
    // -------------------------------------------------------------
    'ttb': BankRuleSet(
      bankId: 'ttb',
      bankName: 'ทีทีบี (ttb touch)',
      shortName: 'ttb touch',
      expensePatterns: [
        AmountPattern(
          id: 'ttb_exp_transfer_push',
          label: 'โอนเงิน...บ.ไปยัง (ttb touch Push notification)',
          regex: RegExp(r'โอนเงิน\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*บ\.'),
          example: 'โอนเงิน1.00บ.ไปยังบ/ช KBANK X2875 นาย ปัณณทัต สมา เหลือ371.00บ.12/09/26@17:39',
          note: 'รูปแบบกระชับของ ttb push แจ้งรายการโอนเงิน-สำเร็จ',
        ),
        AmountPattern(
          id: 'ttb_exp_sms_out',
          label: 'โอนเงินออก ... บาท (ttb SMS)',
          regex: RegExp(r'โอนเงินออก\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*บาท'),
          example: 'โอนเงินออก 320.00 บาท จาก บช x-7714 ให้แก่ ข้าวมันไก่เจ๊หงษ์',
        ),
        AmountPattern(
          id: 'ttb_exp_standard_baht',
          label: 'โอนเงิน ... บาท (ttb ทั่วไป)',
          regex: RegExp(r'โอนเงิน\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*บาท'),
          example: 'โอนเงิน 500.00 บาท ไปยังบัญชีพร้อมเพย์',
        ),
      ],
      incomePatterns: [
        AmountPattern(
          id: 'ttb_inc_money_in_push',
          label: 'มีเงิน...บ.โอนเข้า (ttb touch Push notification)',
          regex: RegExp(r'มีเงิน\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*บ\.'),
          example: 'มีเงิน3.00บ.โอนเข้า/ชxx0264 จาก KBANK X2875 นาย ปัณณทัต สมา เหลือ372.00บ.12/09/26@17:32',
          note: 'รูปแบบกระชับของ ttb push แจ้งรายการเงินเข้าบัญชี-สำเร็จ',
        ),
        AmountPattern(
          id: 'ttb_inc_general',
          label: 'เงินเข้าบัญชี ... บาท (ttb ทั่วไป)',
          regex: RegExp(r'(?:เงินเข้า|โอนเข้า|มีเงินเข้า)\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*บาท'),
          example: 'เงินเข้าบัญชี 1,200.00 บาท สำเร็จ',
        ),
      ],
      balancePatterns: [
        RegExp(r'เหลือ\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*บ\.'),
        RegExp(r'ยอดคงเหลือ\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*บาท'),
      ],
    ),

    // -------------------------------------------------------------
    // 🟣 3. ธนาคารไทยพาณิชย์ (SCB EASY)
    // -------------------------------------------------------------
    'scb': BankRuleSet(
      bankId: 'scb',
      bankName: 'ไทยพาณิชย์ (SCB EASY)',
      shortName: 'SCB EASY',
      expensePatterns: [
        AmountPattern(
          id: 'scb_exp_transfer',
          label: 'โอนเงิน ... บาท (SCB โอนเงิน)',
          regex: RegExp(r'(?:โอนเงิน|จ่ายเงิน|ชำระเงิน)\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*บาท'),
          example: 'โอนเงิน 1,500.00 บาท ไปยัง นาย สมชาย',
        ),
        AmountPattern(
          id: 'scb_exp_general',
          label: 'จำนวน ... บาท (SCB ทั่วไป)',
          regex: RegExp(r'จำนวน\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*บาท'),
          example: 'หักบัญชี ค่าสินค้า จำนวน 250.00 บาท',
        ),
      ],
      incomePatterns: [
        AmountPattern(
          id: 'scb_inc_salary',
          label: 'เงินเดือนเข้า ... จำนวน ... บาท',
          regex: RegExp(r'จำนวน\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*บาท'),
          example: 'เงินเดือนเข้า บช. x-1234 จาก บริษัท ดิจิทัล โซลูชั่น จำกัด จำนวน 45,000.00 บาท',
        ),
        AmountPattern(
          id: 'scb_inc_sms',
          label: 'เงินเข้า ...บ เข้า บช (SCB SMS)',
          regex: RegExp(r'เงินเข้า\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*(?:บ|บาท)'),
          example: 'เงินเข้า 15,000.00บ เข้า บช x-8832 โอนจาก บจก.ไทยซอฟต์แวร์',
        ),
      ],
    ),

    // -------------------------------------------------------------
    // 🔷 4. ธนาคารกรุงไทย (Krungthai NEXT / เป๋าตัง)
    // -------------------------------------------------------------
    'ktb': BankRuleSet(
      bankId: 'ktb',
      bankName: 'กรุงไทย (Krungthai NEXT)',
      shortName: 'Krungthai NEXT',
      expensePatterns: [
        AmountPattern(
          id: 'ktb_exp_pay',
          label: 'ชำระค่าสินค้า/บริการ ... จำนวน ... บาท',
          regex: RegExp(r'จำนวน\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*บาท'),
          example: 'ชำระค่าสินค้า/บริการที่ PTT Station จำนวน 850.00 บาท',
        ),
        AmountPattern(
          id: 'ktb_exp_transfer',
          label: 'โอนเงิน ... บาท สำเร็จ',
          regex: RegExp(r'โอนเงิน\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*บาท'),
          example: 'โอนเงิน 500.00 บาท สำเร็จ',
        ),
      ],
      incomePatterns: [
        AmountPattern(
          id: 'ktb_inc_standard',
          label: 'เงินเข้า บช. ... จำนวน ... บาท',
          regex: RegExp(r'จำนวน\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*บาท'),
          example: 'เงินเข้า บช. x-1290 จำนวน 5,000.00 บาท ยอดเงินใช้ได้ 12,300.00 บาท',
        ),
      ],
    ),

    // -------------------------------------------------------------
    // 🔵 5. ธนาคารกรุงเทพ (Bangkok Bank)
    // -------------------------------------------------------------
    'bbl': BankRuleSet(
      bankId: 'bbl',
      bankName: 'กรุงเทพ (Bangkok Bank)',
      shortName: 'Bangkok Bank',
      expensePatterns: [
        AmountPattern(
          id: 'bbl_exp_transfer',
          label: 'โอนเงิน ... บาท',
          regex: RegExp(r'(?:โอนเงิน|ชำระเงิน)\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*บาท'),
          example: 'โอนเงิน 2,000.00 บาท สำเร็จ',
        ),
      ],
      incomePatterns: [
        AmountPattern(
          id: 'bbl_inc_transfer',
          label: 'เงินโอนเข้า บช. ... จำนวน ... บาท',
          regex: RegExp(r'จำนวน\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*บาท'),
          example: 'เงินโอนเข้า บช. x-9921 จำนวน 4,200.00 บาท จาก นายสมบัติ ส.',
        ),
      ],
    ),

    // -------------------------------------------------------------
    // 🟡 6. ธนาคารกรุงศรีอยุธยา (KMA Krungsri)
    // -------------------------------------------------------------
    'kma': BankRuleSet(
      bankId: 'kma',
      bankName: 'กรุงศรี (KMA)',
      shortName: 'KMA Krungsri',
      expensePatterns: [
        AmountPattern(
          id: 'kma_exp_transfer',
          label: 'โอนเงินสำเร็จ ... บาท',
          regex: RegExp(r'โอนเงินสำเร็จ\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*บาท'),
          example: 'โอนเงินสำเร็จ 1,250.00 บาท ให้กับ บจก. แอดวานซ์ ไวร์เลส',
        ),
      ],
      incomePatterns: [
        AmountPattern(
          id: 'kma_inc_transfer',
          label: 'เงินเข้า ... บาท',
          regex: RegExp(r'(?:เงินเข้า|รับเงิน)\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*บาท'),
          example: 'เงินเข้าบัญชี 3,000.00 บาท',
        ),
      ],
    ),

    // -------------------------------------------------------------
    // 💖 7. ธนาคารออมสิน (MyMo GSB)
    // -------------------------------------------------------------
    'gsb': BankRuleSet(
      bankId: 'gsb',
      bankName: 'ออมสิน (MyMo)',
      shortName: 'MyMo GSB',
      expensePatterns: [
        AmountPattern(
          id: 'gsb_exp_transfer',
          label: 'โอนเงิน ... บาท',
          regex: RegExp(r'โอนเงิน\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*บาท'),
          example: 'โอนเงิน 500.00 บาท สำเร็จ',
        ),
      ],
      incomePatterns: [
        AmountPattern(
          id: 'gsb_inc_transfer',
          label: 'มีเงินเข้าบัญชี ... บาท',
          regex: RegExp(r'มีเงินเข้าบัญชี\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*บาท'),
          example: 'มีเงินเข้าบัญชี 2,000.00 บาท จาก พร้อมเพย์',
        ),
      ],
    ),

    // -------------------------------------------------------------
    // 🟠 8. TrueMoney
    // -------------------------------------------------------------
    'truemoney': BankRuleSet(
      bankId: 'truemoney',
      bankName: 'ทรูมันนี่ (TrueMoney)',
      shortName: 'TrueMoney',
      expensePatterns: [
        AmountPattern(
          id: 'tmn_exp_pay',
          label: 'ชำระเงินสำเร็จ ... บาท',
          regex: RegExp(r'สำเร็จ\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*บาท'),
          example: 'ชำระเงินให้ Shopee Official Store สำเร็จ 450.50 บาท',
        ),
        AmountPattern(
          id: 'tmn_exp_general',
          label: 'ชำระเงิน ... บาท',
          regex: RegExp(r'ชำระเงิน\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*บาท'),
          example: 'ชำระเงิน 100.00 บาท ที่ 7-Eleven',
        ),
      ],
      incomePatterns: [
        AmountPattern(
          id: 'tmn_inc_transfer',
          label: 'ได้รับเงิน ... บาท',
          regex: RegExp(r'(?:ได้รับเงิน|เติมเงินสำเร็จ)\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*บาท'),
          example: 'ได้รับเงิน 200.00 บาท จาก พร้อมเพย์',
        ),
      ],
    ),

    // -------------------------------------------------------------
    // 🔴 9. ShopeePay
    // -------------------------------------------------------------
    'shopeepay': BankRuleSet(
      bankId: 'shopeepay',
      bankName: 'ช้อปปี้เพย์ (ShopeePay)',
      shortName: 'ShopeePay',
      expensePatterns: [
        AmountPattern(
          id: 'shopee_exp_pay',
          label: 'ชำระเงินสำเร็จ ... บาท ที่ Shopee',
          regex: RegExp(r'ชำระเงินสำเร็จ\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*บาท'),
          example: 'ชำระเงินสำเร็จ 299.00 บาท ที่ Shopee',
        ),
      ],
      incomePatterns: [
        AmountPattern(
          id: 'shopee_inc_refund',
          label: 'คืนเงิน / รับเงิน ... บาท',
          regex: RegExp(r'(?:คืนเงิน|รับเงิน)\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*บาท'),
          example: 'คืนเงินสำเร็จ 299.00 บาท',
        ),
      ],
    ),

    // -------------------------------------------------------------
    // 🌐 10. Dime! by KKP
    // -------------------------------------------------------------
    'dime': BankRuleSet(
      bankId: 'dime',
      bankName: 'ไดม์ (Dime!)',
      shortName: 'Dime!',
      expensePatterns: [
        AmountPattern(
          id: 'dime_exp_transfer',
          label: 'โอนเงิน / ซื้อหุ้นสำเร็จ ... บาท',
          regex: RegExp(r'สำเร็จ\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*บาท'),
          example: 'โอนเงินสำเร็จ 1,000.00 บาท',
        ),
      ],
      incomePatterns: [
        AmountPattern(
          id: 'dime_inc_deposit',
          label: 'ฝากเงินเข้าบัญชี ... สำเร็จ ... บาท',
          regex: RegExp(r'สำเร็จ\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*บาท'),
          example: 'ฝากเงินเข้าบัญชี Dime! Save สำเร็จ 3,000.00 บาท',
        ),
      ],
    ),
  };

  /// ดึงชุดกฎของธนาคารตาม bankId (เช่น 'kbank', 'ttb', 'scb')
  static BankRuleSet? getRuleSet(String bankId) {
    return _bankRules[bankId.toLowerCase()];
  }

  /// สกัดจำนวนเงินจากข้อความตามธนาคารและประเภทรายการ (เงินเข้า / เงินออก)
  static double? extractAmount({
    required String bankId,
    required TransactionType type,
    required String text,
  }) {
    final ruleSet = getRuleSet(bankId);
    if (ruleSet != null) {
      return ruleSet.extractAmount(text, type);
    }
    // Fallback if bank is not in registry
    return extractCommonAmount(text);
  }

  /// กฎสากลสำรอง (Global Fallback Regexes) กรณีไม่ตรงกับธนาคารใดโดยเฉพาะ
  static final List<RegExp> _commonAmountRegexes = [
    RegExp(r'(?:จำนวนเงิน|จำนวน|ยอดเงิน|ยอด|เงิน|฿|THB|thb|โอน/ถอน|ถอน/โอน|โอน|รับ|จ่าย|หัก|ฝาก)\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)\s*(?:บาท|บ\.|THB|thb|฿|baht)?', caseSensitive: false),
    RegExp(r'(?:โอนเงิน|มีเงิน|เงินเข้า|เงินออก)\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)\s*(?:บาท|บ\.|THB|thb|฿|baht)', caseSensitive: false),
    RegExp(r'([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)\s*(?:บาท|บ\.|THB|thb|฿|baht)', caseSensitive: false),
    RegExp(r'(?:โอน/ถอน|ถอน/โอน|โอนเงิน|รับเงิน|ชำระ|จ่าย|หัก|เงินเข้า|เงินออก|โอน|ถอน|ฝาก|ยอด|บช\.)\s*(?:จำนวน|เป็นจำนวน|ยอด)?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)', caseSensitive: false),
    RegExp(r'(?:฿|\$)\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)'),
    RegExp(r'([0-9]{1,3}(?:,[0-9]{3})*\.[0-9]{2})'),
  ];

  static double? extractCommonAmount(String text) {
    // ลบส่วนที่เป็นยอดเงินคงเหลือออกก่อน
    final cleanText = text.replaceAll(
      RegExp(r'(?:ยอดคงเหลือ|คงเหลือ|เหลือ)\s*[0-9,]+(?:\.[0-9]{1,2})?\s*(?:บาท|บ\.|฿|THB)?', caseSensitive: false),
      ' ',
    );

    for (final reg in _commonAmountRegexes) {
      final match = reg.firstMatch(cleanText);
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

  /// ส่งออกกฎทั้งหมดเป็น Map/JSON อ่านง่าย เพื่อให้ Dev หรือแสดงใน UI ของแอปได้
  static Map<String, dynamic> allRulesAsJson() {
    return _bankRules.map((key, value) => MapEntry(key.toUpperCase(), value.toJson()));
  }
}
