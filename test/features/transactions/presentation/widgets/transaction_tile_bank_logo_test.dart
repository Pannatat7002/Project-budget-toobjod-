import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budget_planner/features/auto_sync/domain/entities/bank_profile.dart';
import 'package:budget_planner/features/transactions/domain/entities/transaction_entity.dart';
import 'package:budget_planner/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:budget_planner/shared/widgets/category_icon_badge.dart';

void main() {
  group('TransactionEntity.isUnknownCategory', () {
    test('identifies unknown/other categories correctly', () {
      final txOther = TransactionEntity(
        id: '1',
        title: '7-Eleven',
        amount: 150,
        type: TransactionType.expense,
        categoryId: 'other',
        categoryName: 'อื่นๆ',
        categoryIconCode: 0xe41d,
        categoryColorValue: 0xFF64748B,
        date: DateTime.now(),
      );
      expect(txOther.isUnknownCategory, isTrue);

      final txOtherIncome = TransactionEntity(
        id: '2',
        title: 'เงินโอน',
        amount: 500,
        type: TransactionType.income,
        categoryId: 'other_income',
        categoryName: 'รายรับอื่นๆ',
        categoryIconCode: 0xe41d,
        categoryColorValue: 0xFF64748B,
        date: DateTime.now(),
      );
      expect(txOtherIncome.isUnknownCategory, isTrue);

      final txFood = TransactionEntity(
        id: '3',
        title: 'ข้าวมันไก่',
        amount: 60,
        type: TransactionType.expense,
        categoryId: 'food',
        categoryName: 'อาหาร & เครื่องดื่ม',
        categoryIconCode: 0xe532,
        categoryColorValue: 0xFFEF4444,
        date: DateTime.now(),
      );
      expect(txFood.isUnknownCategory, isFalse);
    });
  });

  group('BankProfile.resolveBank', () {
    test('resolves from bankId', () {
      expect(BankProfile.resolveBank(bankId: 'kbank')?.id, 'kbank');
      expect(BankProfile.resolveBank(bankId: 'scb')?.id, 'scb');
      expect(BankProfile.resolveBank(bankId: 'ttb')?.id, 'ttb');
      expect(BankProfile.resolveBank(bankId: 'ktb')?.id, 'ktb');
      expect(BankProfile.resolveBank(bankId: 'bbl')?.id, 'bbl');
      expect(BankProfile.resolveBank(bankId: 'cash'), isNull);
    });

    test('resolves from bank short name or full name', () {
      expect(BankProfile.resolveBank(bankName: 'K PLUS')?.id, 'kbank');
      expect(BankProfile.resolveBank(bankName: 'SCB EASY')?.id, 'scb');
      expect(BankProfile.resolveBank(bankName: 'ttb touch')?.id, 'ttb');
      expect(BankProfile.resolveBank(bankName: 'TrueMoney')?.id, 'truemoney');
      expect(BankProfile.resolveBank(bankName: 'ไทยพาณิชย์')?.id, 'scb');
      expect(BankProfile.resolveBank(bankName: 'กสิกรไทย')?.id, 'kbank');
    });

    test('resolves from transaction note with bank keyword', () {
      expect(
        BankProfile.resolveBank(note: 'ตรวจจับอัตโนมัติจาก K PLUS')?.id,
        'kbank',
      );
      expect(
        BankProfile.resolveBank(note: 'โอนผ่าน SCB EASY สำเร็จ')?.id,
        'scb',
      );
    });
  });

  group('TransactionTile Bank Logo Display', () {
    testWidgets('shows Bank Logo when category is unknown and bank is selected', (tester) async {
      final tx = TransactionEntity(
        id: 'tx_kbank_other',
        title: 'รายการเงินโอน',
        amount: 250.0,
        type: TransactionType.expense,
        categoryId: 'other',
        categoryName: 'อื่นๆ',
        categoryIconCode: 0xe41d,
        categoryColorValue: 0xFF64748B,
        date: DateTime.now(),
        bankId: 'kbank',
        bankShortName: 'K PLUS',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionTile(transaction: tx),
          ),
        ),
      );

      // Verify CategoryIconBadge exists
      final badgeFinder = find.byType(CategoryIconBadge);
      expect(badgeFinder, findsOneWidget);

      final badge = tester.widget<CategoryIconBadge>(badgeFinder);
      expect(badge.isBankLogo, isTrue);
      expect(badge.assetPath, 'assets/images/banks/kbank.png');
      expect(badge.color, const Color(0xFF138F2D)); // KBank green
    });

    testWidgets('shows Bank Logo when category is unknown and bank is detected via note', (tester) async {
      final tx = TransactionEntity(
        id: 'tx_scb_detected',
        title: 'ชำระค่าบริการ',
        amount: 120.0,
        type: TransactionType.expense,
        categoryId: 'other',
        categoryName: 'อื่นๆ',
        categoryIconCode: 0xe41d,
        categoryColorValue: 0xFF64748B,
        date: DateTime.now(),
        note: 'ตรวจจับอัตโนมัติจาก SCB EASY',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionTile(transaction: tx),
          ),
        ),
      );

      final badgeFinder = find.byType(CategoryIconBadge);
      expect(badgeFinder, findsOneWidget);

      final badge = tester.widget<CategoryIconBadge>(badgeFinder);
      expect(badge.isBankLogo, isTrue);
      expect(badge.assetPath, 'assets/images/banks/scb.png');
      expect(badge.color, const Color(0xFF4E2A84)); // SCB purple
    });

    testWidgets('shows Category Icon (not Bank Logo) when category is known', (tester) async {
      final tx = TransactionEntity(
        id: 'tx_known_food',
        title: 'ชาบูชิ',
        amount: 450.0,
        type: TransactionType.expense,
        categoryId: 'food',
        categoryName: 'อาหาร & เครื่องดื่ม',
        categoryIconCode: 0xe532,
        categoryColorValue: 0xFFEF4444,
        date: DateTime.now(),
        bankId: 'kbank',
        bankShortName: 'K PLUS',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionTile(transaction: tx),
          ),
        ),
      );

      final badgeFinder = find.byType(CategoryIconBadge);
      expect(badgeFinder, findsOneWidget);

      final badge = tester.widget<CategoryIconBadge>(badgeFinder);
      expect(badge.isBankLogo, isFalse);
      expect(badge.assetPath, isNull);
      expect(badge.categoryId, 'food');
    });

    testWidgets('shows regular category icon when category is unknown but no bank is selected/detected', (tester) async {
      final tx = TransactionEntity(
        id: 'tx_cash_other',
        title: 'ซื้อของทั่วไป',
        amount: 50.0,
        type: TransactionType.expense,
        categoryId: 'other',
        categoryName: 'อื่นๆ',
        categoryIconCode: 0xe41d,
        categoryColorValue: 0xFF64748B,
        date: DateTime.now(),
        bankId: 'cash',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionTile(transaction: tx),
          ),
        ),
      );

      final badgeFinder = find.byType(CategoryIconBadge);
      expect(badgeFinder, findsOneWidget);

      final badge = tester.widget<CategoryIconBadge>(badgeFinder);
      expect(badge.isBankLogo, isFalse);
      expect(badge.assetPath, isNull);
      expect(badge.categoryId, 'other');
    });
  });
}
