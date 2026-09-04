import 'package:flutter_test/flutter_test.dart';
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
  });
}
