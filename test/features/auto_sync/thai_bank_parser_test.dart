import 'package:flutter_test/flutter_test.dart';
import 'package:budget_planner/features/auto_sync/utils/rules/bank_pattern_rules.dart';
import 'package:budget_planner/features/auto_sync/utils/thai_bank_parser.dart';
import 'package:budget_planner/features/transactions/domain/entities/transaction_entity.dart';

void main() {
  group('ThaiBankParser Tests', () {
    test('should correctly parse K PLUS outgoing transfer', () {
      final parsed = ThaiBankParser.parse(
        packageName: 'com.kasikorn.bank',
        title: 'K PLUS',
        text: 'โอนเงินไปยัง นาย สมชาย ใจดี 1,500.00 บาท สำเร็จ',
      );

      expect(parsed, isNotNull);
      expect(parsed!.title, 'นาย สมชาย ใจดี');
      expect(parsed.rawText, 'โอนเงินไปยัง นาย สมชาย ใจดี 1,500.00 บาท สำเร็จ');
      expect(parsed.type, TransactionType.expense);
      expect(parsed.amount, 1500.00);
      expect(parsed.bankShortName, 'K PLUS');
      expect(parsed.suggestedCategoryId, 'other');
      expect(parsed.suggestedCategoryName, 'อื่นๆ');
      expect(parsed.merchantOrSender, contains('สมชาย'));

      final entity = parsed.toTransactionEntity();
      expect(entity.title, 'นาย สมชาย ใจดี');
      expect(entity.note, parsed.rawText);
    });

    test('should correctly parse real K PLUS official notification (รายการโอน/ถอน)', () {
      final parsed = ThaiBankParser.parse(
        packageName: 'com.kasikorn.retail.mbanking.wap',
        title: 'รายการโอน/ถอน',
        text: 'บัญชี xxx-x-x3287-x  จำนวนเงิน 1.00 บาท  วันที่ 2 ก.ย. 69  09:05 น.',
      );

      expect(parsed, isNotNull);
      expect(parsed!.title, 'รายการโอน/ถอน');
      expect(parsed.rawText, contains('จำนวนเงิน 1.00 บาท'));
      expect(parsed.type, TransactionType.expense);
      expect(parsed.amount, 1.00);
      expect(parsed.bankShortName, 'K PLUS');
      expect(parsed.suggestedCategoryId, 'other');
      expect(parsed.suggestedCategoryName, 'อื่นๆ');

      final entity = parsed.toTransactionEntity();
      expect(entity.title, 'รายการโอน/ถอน');
      expect(entity.note, parsed.rawText);
    });

    test('should correctly parse ADB shell K PLUS notifications accurately', () {
      // 1. รายการโอน/ถอน
      final notif1 = ThaiBankParser.parse(
        packageName: 'com.android.shell',
        title: 'รายการโอน/ถอน',
        text: 'บัญชี xxx-x-x3287-x จำนวนเงิน 150.00 บาท วันที่ 3 ก.ย. 69',
      );
      expect(notif1, isNotNull);
      expect(notif1!.bankShortName, 'K PLUS');
      expect(notif1.type, TransactionType.expense);
      expect(notif1.amount, 150.00);
      expect(notif1.suggestedCategoryId, 'other');

      // 2. โอนเงินไปยัง นาย สมชาย
      final notif2 = ThaiBankParser.parse(
        packageName: 'com.android.shell',
        title: 'K PLUS',
        text: 'โอนเงินไปยัง นาย สมชาย ใจดี 1,500.00 บาท สำเร็จ',
      );
      expect(notif2, isNotNull);
      expect(notif2!.bankShortName, 'K PLUS');
      expect(notif2.title, 'นาย สมชาย ใจดี');
      expect(notif2.type, TransactionType.expense);
      expect(notif2.amount, 1500.00);
      expect(notif2.suggestedCategoryId, 'other');

      // 3. เงินเข้า 3,500.00 บาท
      final notif3 = ThaiBankParser.parse(
        packageName: 'com.android.shell',
        title: 'K PLUS',
        text: 'เงินเข้า บัญชี xxx-x-x3287-x จำนวนเงิน 3,500.00 บาท',
      );
      expect(notif3, isNotNull);
      expect(notif3!.bankShortName, 'K PLUS');
      expect(notif3.type, TransactionType.income);
      expect(notif3.amount, 3500.00);
      expect(notif3.suggestedCategoryId, 'other_income');

      // 4. ชำระ 7-Eleven
      final notif4 = ThaiBankParser.parse(
        packageName: 'com.android.shell',
        title: 'K PLUS',
        text: 'ชำระเงินให้แก่ 7-Eleven สาขาอโศก 89.00 บาท สำเร็จ',
      );
      expect(notif4, isNotNull);
      expect(notif4!.bankShortName, 'K PLUS');
      expect(notif4.title, '7-Eleven สาขาอโศก');
      expect(notif4.type, TransactionType.expense);
      expect(notif4.amount, 89.00);
      expect(notif4.suggestedCategoryId, 'food');

      // 5. ถอนเงินไม่ใช้บัตร
      final notif5 = ThaiBankParser.parse(
        packageName: 'com.android.shell',
        title: 'K PLUS',
        text: 'ถอนเงินไม่ใช้บัตร จำนวนเงิน 500.00 บาท สำเร็จ',
      );
      expect(notif5, isNotNull);
      expect(notif5!.bankShortName, 'K PLUS');
      expect(notif5.title, 'ถอนเงินไม่ใช้บัตร');
      expect(notif5.type, TransactionType.expense);
      expect(notif5.amount, 500.00);
      expect(notif5.suggestedCategoryId, 'other');
    });

    test('should correctly parse SCB EASY income / salary', () {
      final parsed = ThaiBankParser.parse(
        packageName: 'com.scb.phone',
        title: 'SCB EASY',
        text: 'เงินเดือนเข้า บช. x-1234 จาก บริษัท ดิจิทัล โซลูชั่น จำกัด จำนวน 45,000.00 บาท',
      );

      expect(parsed, isNotNull);
      expect(parsed!.title, 'บริษัท ดิจิทัล โซลูชั่น จำกัด');
      expect(parsed.rawTitle, 'SCB EASY');
      expect(parsed.rawText, contains('45,000.00 บาท'));
      expect(parsed.type, TransactionType.income);
      expect(parsed.amount, 45000.00);
      expect(parsed.suggestedCategoryId, 'salary');
      expect(parsed.bankShortName, 'SCB EASY');

      final entity = parsed.toTransactionEntity();
      expect(entity.title, 'บริษัท ดิจิทัล โซลูชั่น จำกัด');
      expect(entity.note, parsed.rawText);
    });

    test('should correctly auto-categorize food from 7-Eleven', () {
      final parsed = ThaiBankParser.parse(
        packageName: 'com.kasikorn.bank',
        title: 'K PLUS',
        text: 'ชำระเงินให้แก่ 7-Eleven สาขาอโศก 125.00 บาท สำเร็จ',
      );

      expect(parsed, isNotNull);
      expect(parsed!.type, TransactionType.expense);
      expect(parsed.amount, 125.00);
      expect(parsed.suggestedCategoryId, 'food');
    });

    test('should correctly auto-categorize transport from PTT gas station', () {
      final parsed = ThaiBankParser.parse(
        packageName: 'ktb.cs.mobile.app',
        title: 'Krungthai NEXT',
        text: 'ชำระค่าสินค้า/บริการที่ PTT Station จำนวน 850.00 บาท',
      );

      expect(parsed, isNotNull);
      expect(parsed!.type, TransactionType.expense);
      expect(parsed.amount, 850.00);
      expect(parsed.suggestedCategoryId, 'transport');
    });

    test('should correctly auto-categorize shopping from Shopee with TrueMoney', () {
      final parsed = ThaiBankParser.parse(
        packageName: 'th.co.truemoney.wallet',
        title: 'TrueMoney',
        text: 'ชำระเงินให้ Shopee Official Store สำเร็จ 450.50 บาท',
      );

      expect(parsed, isNotNull);
      expect(parsed!.type, TransactionType.expense);
      expect(parsed.amount, 450.50);
      expect(parsed.suggestedCategoryId, 'shopping');
    });

    test('should return null for non-financial notification', () {
      final parsed = ThaiBankParser.parse(
        packageName: 'com.kasikorn.bank',
        title: 'K PLUS',
        text: 'ยินดีต้อนรับสู่ระบบ K PLUS โปรโมชั่นพิเศษวันนี้',
      );

      expect(parsed, isNull);
    });

    test('should correctly parse Bank SMS from messaging app', () {
      // 1. KBANK SMS
      final kbankSms = ThaiBankParser.parse(
        packageName: 'com.google.android.apps.messaging',
        title: 'KBANK',
        text: 'บช. x-4521 เงินเข้า 3,500.00 บ. จาก นายสมชาย ว. ยอดคงเหลือ 45,650.00 บ.',
      );
      expect(kbankSms, isNotNull);
      expect(kbankSms!.bankShortName, 'K PLUS');
      expect(kbankSms.type, TransactionType.income);
      expect(kbankSms.amount, 3500.00);

      // 2. SCB SMS
      final scbSms = ThaiBankParser.parse(
        packageName: 'com.google.android.apps.messaging',
        title: 'SCB',
        text: 'เงินเข้า 15,000.00บ เข้า บช x-8832 โอนจาก บจก.ไทยซอฟต์แวร์ ยอดคงเหลือ 28,500.00บ',
      );
      expect(scbSms, isNotNull);
      expect(scbSms!.bankShortName, 'SCB EASY');
      expect(scbSms.type, TransactionType.income);
      expect(scbSms.amount, 15000.00);

      // 3. KTB SMS
      final ktbSms = ThaiBankParser.parse(
        packageName: 'com.samsung.android.messaging',
        title: 'KTB',
        text: 'เงินเข้า บช. x-1290 จำนวน 5,000.00 บาท ยอดเงินใช้ได้ 12,300.00 บาท',
      );
      expect(ktbSms, isNotNull);
      expect(ktbSms!.bankShortName, 'Krungthai NEXT');
      expect(ktbSms.type, TransactionType.income);
      expect(ktbSms.amount, 5000.00);

      // 4. ttb SMS (Expense)
      final ttbSms = ThaiBankParser.parse(
        packageName: 'com.google.android.apps.messaging',
        title: 'ttb',
        text: 'โอนเงินออก 320.00 บาท จาก บช x-7714 ให้แก่ ข้าวมันไก่เจ๊หงษ์ ยอดคงเหลือ 8,450.00 บาท',
      );
      expect(ttbSms, isNotNull);
      expect(ttbSms!.bankShortName, 'ttb touch');
      expect(ttbSms.type, TransactionType.expense);
      expect(ttbSms.amount, 320.00);

      // 5. BBL SMS
      final bblSms = ThaiBankParser.parse(
        packageName: 'com.google.android.apps.messaging',
        title: 'Bangkok Bank',
        text: 'เงินโอนเข้า บช. x-9921 จำนวน 4,200.00 บาท จาก นายสมบัติ ส.',
      );
      expect(bblSms, isNotNull);
      expect(bblSms!.bankShortName, 'Bangkok Bank');
      expect(bblSms.type, TransactionType.income);
      expect(bblSms.amount, 4200.00);

      // 6. KMA Krungsri SMS / Push
      final kmaNotif = ThaiBankParser.parse(
        packageName: 'com.krungsri.kma',
        title: 'KMA',
        text: 'โอนเงินสำเร็จ 1,250.00 บาท ให้กับ บจก. แอดวานซ์ ไวร์เลส',
      );
      expect(kmaNotif, isNotNull);
      expect(kmaNotif!.bankShortName, 'KMA Krungsri');
      expect(kmaNotif.type, TransactionType.expense);
      expect(kmaNotif.amount, 1250.00);

      // 7. GSB MyMo Push
      final gsbNotif = ThaiBankParser.parse(
        packageName: 'com.gsb.mymo',
        title: 'MyMo',
        text: 'มีเงินเข้าบัญชี 2,000.00 บาท จาก พร้อมเพย์',
      );
      expect(gsbNotif, isNotNull);
      expect(gsbNotif!.bankShortName, 'MyMo GSB');
      expect(gsbNotif.type, TransactionType.income);
      expect(gsbNotif.amount, 2000.00);

      // 8. ShopeePay Push
      final shopeeNotif = ThaiBankParser.parse(
        packageName: 'com.shopeepay.th',
        title: 'ShopeePay',
        text: 'ชำระเงินสำเร็จ 299.00 บาท ที่ Shopee',
      );
      expect(shopeeNotif, isNotNull);
      expect(shopeeNotif!.bankShortName, 'ShopeePay');
      expect(shopeeNotif.type, TransactionType.expense);
      expect(shopeeNotif.amount, 299.00);

      // 9. Dime! Push
      final dimeNotif = ThaiBankParser.parse(
        packageName: 'co.th.dime',
        title: 'Dime!',
        text: 'ฝากเงินเข้าบัญชี Dime! Save สำเร็จ 3,000.00 บาท',
      );
      expect(dimeNotif, isNotNull);
      expect(dimeNotif!.bankShortName, 'Dime!');
      expect(dimeNotif.type, TransactionType.income);
      expect(dimeNotif.amount, 3000.00);
    });

    group('Real Screenshot Notifications (from test/ folder images)', () {
      test('K PLUS - รายการเงินเข้า 1.00 บาท (17:39 น.)', () {
        final parsed = ThaiBankParser.parse(
          packageName: 'com.kasikorn.retail.mbanking.wap',
          title: 'รายการเงินเข้า',
          text: 'บัญชี xxx-x-x3287-x จำนวนเงิน 1.00 บาท วันที่ 12 ก.ย. 69 17:39 น.',
        );

        expect(parsed, isNotNull);
        expect(parsed!.bankShortName, 'K PLUS');
        expect(parsed.type, TransactionType.income);
        expect(parsed.amount, 1.00);
        expect(parsed.accountMask, 'x-3287');
        expect(parsed.title, 'รายการเงินเข้า');
        expect(parsed.timestamp.year, 2026);
        expect(parsed.timestamp.month, 9);
        expect(parsed.timestamp.day, 12);
        expect(parsed.timestamp.hour, 17);
        expect(parsed.timestamp.minute, 39);
      });

      test('K PLUS - รายการโอน/ถอน (3.00, 4.00, 5.00, 300.00 บาท)', () {
        final items = [
          {
            'text': 'บัญชี xxx-x-x3287-x จำนวนเงิน 3.00 บาท วันที่ 12 ก.ย. 69 17:32 น.',
            'amount': 3.00,
            'hour': 17,
            'minute': 32,
          },
          {
            'text': 'บัญชี xxx-x-x3287-x จำนวนเงิน 4.00 บาท วันที่ 12 ก.ย. 69 17:27 น.',
            'amount': 4.00,
            'hour': 17,
            'minute': 27,
          },
          {
            'text': 'บัญชี xxx-x-x3287-x จำนวนเงิน 5.00 บาท วันที่ 12 ก.ย. 69 16:59 น.',
            'amount': 5.00,
            'hour': 16,
            'minute': 59,
          },
          {
            'text': 'บัญชี xxx-x-x3287-x จำนวนเงิน 300.00 บาท วันที่ 12 ก.ย. 69 16:45 น.',
            'amount': 300.00,
            'hour': 16,
            'minute': 45,
          },
        ];

        for (final item in items) {
          final parsed = ThaiBankParser.parse(
            packageName: 'com.kasikorn.retail.mbanking.wap',
            title: 'รายการโอน/ถอน',
            text: item['text'] as String,
          );

          expect(parsed, isNotNull);
          expect(parsed!.bankShortName, 'K PLUS');
          expect(parsed.type, TransactionType.expense);
          expect(parsed.amount, item['amount']);
          expect(parsed.accountMask, 'x-3287');
          expect(parsed.title, 'รายการโอน/ถอน');
          expect(parsed.timestamp.year, 2026);
          expect(parsed.timestamp.month, 9);
          expect(parsed.timestamp.day, 12);
          expect(parsed.timestamp.hour, item['hour']);
          expect(parsed.timestamp.minute, item['minute']);
        }
      });

      test('ttb touch - แจ้งรายการเงินเข้าบัญชี-สำเร็จ (Full Expanded Text)', () {
        final parsed = ThaiBankParser.parse(
          packageName: 'com.ttbbank.oneapp',
          title: 'แจ้งรายการเงินเข้าบัญชี-สำเร็จ',
          text: 'มีเงิน3.00บ.โอนเข้า/ชxx0264 จาก KBANK X2875 นาย ปัณณทัต สมา เหลือ372.00บ.12/09/26@17:32',
        );

        expect(parsed, isNotNull);
        expect(parsed!.bankShortName, 'ttb touch');
        expect(parsed.type, TransactionType.income);
        expect(parsed.amount, 3.00);
        expect(parsed.accountMask, 'x-0264');
        expect(parsed.title, 'แจ้งรายการเงินเข้าบัญชี-สำเร็จ');
        expect(parsed.merchantOrSender, contains('KBANK X2875 นาย ปัณณทัต สมา'));
        expect(parsed.timestamp.year, 2026);
        expect(parsed.timestamp.month, 9);
        expect(parsed.timestamp.day, 12);
        expect(parsed.timestamp.hour, 17);
        expect(parsed.timestamp.minute, 32);
      });

      test('ttb touch - แจ้งรายการเงินเข้าบัญชี-สำ... (Compact / Truncated Text)', () {
        final parsed = ThaiBankParser.parse(
          packageName: 'com.ttbbank.oneapp',
          title: 'แจ้งรายการเงินเข้าบัญชี-สำ...',
          text: 'มีเงิน3.00บ.โอนเข้า/ชxx0264 จาก KBANK X2875 นาย ปัณณทัต สมา เห...',
        );

        expect(parsed, isNotNull);
        expect(parsed!.bankShortName, 'ttb touch');
        expect(parsed.type, TransactionType.income);
        expect(parsed.amount, 3.00);
        expect(parsed.accountMask, 'x-0264');
        expect(parsed.title, 'แจ้งรายการเงินเข้าบัญชี-สำเร็จ');
      });

      test('ttb touch - แจ้งรายการโอนเงิน-สำเร็จ (Full Expanded Text)', () {
        final parsed = ThaiBankParser.parse(
          packageName: 'com.ttbbank.oneapp',
          title: 'แจ้งรายการโอนเงิน-สำเร็จ',
          text: 'โอนเงิน1.00บ.ไปยังบ/ช KBANK X2875 นาย ปัณณทัต สมา เหลือ371.00บ.12/09/26@17:39',
        );

        expect(parsed, isNotNull);
        expect(parsed!.bankShortName, 'ttb touch');
        expect(parsed.type, TransactionType.expense);
        expect(parsed.amount, 1.00);
        expect(parsed.title, 'แจ้งรายการโอนเงิน-สำเร็จ');
        expect(parsed.merchantOrSender, contains('KBANK X2875 นาย ปัณณทัต สมา'));
        expect(parsed.timestamp.year, 2026);
        expect(parsed.timestamp.month, 9);
        expect(parsed.timestamp.day, 12);
        expect(parsed.timestamp.hour, 17);
        expect(parsed.timestamp.minute, 39);
      });

      test('ttb touch - แจ้งรายการโอนเงิน-สำ... (Compact / Truncated Text)', () {
        final parsed = ThaiBankParser.parse(
          packageName: 'com.ttbbank.oneapp',
          title: 'แจ้งรายการโอนเงิน-สำ...',
          text: 'โอนเงิน1.00บ.ไปยังบ/ช KBANK X2875 นาย ปัณณทัต สมา เหลือ371.0...',
        );

        expect(parsed, isNotNull);
        expect(parsed!.bankShortName, 'ttb touch');
        expect(parsed.type, TransactionType.expense);
        expect(parsed.amount, 1.00);
        expect(parsed.title, 'แจ้งรายการโอนเงิน-สำเร็จ');
      });

      test('ttb touch - all other income notifications (4.00, 5.00, 300.00 บ.)', () {
        final amounts = [
          {
            'text': 'มีเงิน4.00บ.โอนเข้า/ชxx0264 จาก KBANK X2875 นาย ปัณณทัต สมา เหลือ369.00บ.12/09/26@17:27',
            'amount': 4.00,
            'minute': 27,
          },
          {
            'text': 'มีเงิน5.00บ.โอนเข้า/ชxx0264 จาก KBANK X2875 นาย ปัณณทัต สมา เหลือ365.00บ.12/09/26@16:59',
            'amount': 5.00,
            'minute': 59,
          },
          {
            'text': 'มีเงิน300.00บ.โอนเข้า/ชxx0264 จาก KBANK X2875 นาย ปัณณทัต สมา เหลือ360.00บ.12/09/26@16:45',
            'amount': 300.00,
            'minute': 45,
          },
        ];

        for (final item in amounts) {
          final parsed = ThaiBankParser.parse(
            packageName: 'com.ttbbank.oneapp',
            title: 'แจ้งรายการเงินเข้าบัญชี-สำเร็จ',
            text: item['text'] as String,
          );

          expect(parsed, isNotNull);
          expect(parsed!.bankShortName, 'ttb touch');
          expect(parsed.type, TransactionType.income);
          expect(parsed.amount, item['amount']);
          expect(parsed.accountMask, 'x-0264');
          expect(parsed.title, 'แจ้งรายการเงินเข้าบัญชี-สำเร็จ');
          expect(parsed.timestamp.minute, item['minute']);
        }
      });
    });

    group('BankPatternRules Engine Tests', () {
      test('should cleanly separate rules by bank and transaction type (income vs expense)', () {
        final kbankRules = BankPatternRules.getRuleSet('kbank');
        expect(kbankRules, isNotNull);
        expect(kbankRules!.expensePatterns, isNotEmpty);
        expect(kbankRules.incomePatterns, isNotEmpty);
        for (final p in kbankRules.expensePatterns) {
          expect(p.id, isNotEmpty);
          expect(p.label, isNotEmpty);
          expect(p.example, isNotEmpty);
        }

        final ttbRules = BankPatternRules.getRuleSet('ttb');
        expect(ttbRules, isNotNull);
        expect(ttbRules!.expensePatterns, isNotEmpty);
        expect(ttbRules.incomePatterns, isNotEmpty);

        final json = BankPatternRules.allRulesAsJson();
        expect(json.containsKey('KBANK'), isTrue);
        expect(json.containsKey('TTB'), isTrue);
        expect(json['KBANK']['เงินออก (Expense)'], isNotEmpty);
        expect(json['KBANK']['เงินเข้า (Income)'], isNotEmpty);
        expect(json['TTB']['เงินออก (Expense)'], isNotEmpty);
        expect(json['TTB']['เงินเข้า (Income)'], isNotEmpty);
      });
    });

    group('Exact Bank Package Name Direct Routing Tests', () {
      test('K PLUS exact package (com.kasikorn.retail.mbanking.wap)', () {
        final parsed = ThaiBankParser.parse(
          packageName: 'com.kasikorn.retail.mbanking.wap',
          title: 'รายการโอน/ถอน',
          text: 'โอนไป 500.00 บาท',
        );
        expect(parsed, isNotNull);
        expect(parsed!.bankId, 'kbank');
        expect(parsed.bankShortName, 'K PLUS');
      });

      test('ttb touch exact package (com.TMBTOUCH.PRODUCTION)', () {
        final parsed = ThaiBankParser.parse(
          packageName: 'com.TMBTOUCH.PRODUCTION',
          title: 'แจ้งรายการโอนเงิน-สำเร็จ',
          text: 'โอนเงิน 1,200.00 บ. ไปยัง บช. xxx-x-x1234-x',
        );
        expect(parsed, isNotNull);
        expect(parsed!.bankId, 'ttb');
        expect(parsed.bankShortName, 'ttb touch');
      });

      test('Krungthai NEXT exact package (ktbcs.netbank)', () {
        final parsed = ThaiBankParser.parse(
          packageName: 'ktbcs.netbank',
          title: 'โอนเงินสำเร็จ',
          text: 'ไปยัง นาย ก 350.00 บาท',
        );
        expect(parsed, isNotNull);
        expect(parsed!.bankId, 'ktb');
        expect(parsed.bankShortName, 'Krungthai NEXT');
      });

      test('Paotang exact package (com.ktb.customer.qr)', () {
        final parsed = ThaiBankParser.parse(
          packageName: 'com.ktb.customer.qr',
          title: 'โอนเงินสำเร็จ',
          text: 'ชำระให้ ร้านค้า 80.00 บาท สำเร็จ',
        );
        expect(parsed, isNotNull);
        expect(parsed!.bankId, 'paotang');
        expect(parsed.bankShortName, 'เป๋าตัง');
      });

      test('MAKE by KBank exact package (com.kasikornbank.makebykbank)', () {
        final parsed = ThaiBankParser.parse(
          packageName: 'com.kasikornbank.makebykbank',
          title: 'โอนเงินสำเร็จ',
          text: 'ไปยัง นาย ข 200.00 บาท สำเร็จ',
        );
        expect(parsed, isNotNull);
        expect(parsed!.bankId, 'make_kbank');
        expect(parsed.bankShortName, 'MAKE');
      });

      test('Kept exact package (com.krungsri.kept)', () {
        final parsed = ThaiBankParser.parse(
          packageName: 'com.krungsri.kept',
          title: 'โอนเงินสำเร็จ',
          text: 'ไปยัง นาย ค 300.00 บาท สำเร็จ',
        );
        expect(parsed, isNotNull);
        expect(parsed!.bankId, 'kept');
        expect(parsed.bankShortName, 'Kept');
      });

      test('TrueMoney exact package (th.co.truemoney.wallet)', () {
        final parsed = ThaiBankParser.parse(
          packageName: 'th.co.truemoney.wallet',
          title: 'ชำระเงินสำเร็จ',
          text: 'ชำระค่าสินค้าที่ 7-Eleven จำนวน 129.00 บาท',
        );
        expect(parsed, isNotNull);
        expect(parsed!.bankId, 'truemoney');
        expect(parsed.bankShortName, 'TrueMoney');
      });
    });
  });
}

