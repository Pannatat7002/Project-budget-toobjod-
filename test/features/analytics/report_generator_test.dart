import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:budget_planner/features/analytics/utils/report_generator.dart';
import 'package:budget_planner/features/transactions/domain/entities/transaction_entity.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('th', null);
  });

  group('ReportGenerator & PeriodRange Tests', () {
    test('PeriodRange calculates dates and days correctly', () {
      final periodMonth = PeriodRange.fromType(AnalyticsPeriod.thisMonth);
      expect(periodMonth.dayCount, greaterThanOrEqualTo(28));
      expect(periodMonth.label, contains('เดือนนี้'));

      final periodAll = PeriodRange.fromType(AnalyticsPeriod.allTime);
      expect(periodAll.dayCount, greaterThan(365));
    });

    test('calculateKpis computes KPIs and financial health status accurately', () {
      final now = DateTime.now();
      final period = PeriodRange.fromType(AnalyticsPeriod.thisMonth);

      final txs = [
        TransactionEntity(
          id: '1',
          title: 'เงินเดือน',
          amount: 50000.0,
          type: TransactionType.income,
          categoryId: 'salary',
          categoryName: 'เงินเดือน',
          categoryIconCode: 0xe040,
          categoryColorValue: 0xFF10B981,
          date: now,
        ),
        TransactionEntity(
          id: '2',
          title: 'ค่าเช่าห้อง',
          amount: 10000.0,
          type: TransactionType.expense,
          categoryId: 'bills',
          categoryName: 'ที่พัก & สาธารณูปโภค',
          categoryIconCode: 0xe88a,
          categoryColorValue: 0xFF6366F1,
          date: now,
        ),
        TransactionEntity(
          id: '3',
          title: 'อาหาร',
          amount: 5000.0,
          type: TransactionType.expense,
          categoryId: 'food',
          categoryName: 'อาหาร & เครื่องดื่ม',
          categoryIconCode: 0xe532,
          categoryColorValue: 0xFFEF4444,
          date: now,
        ),
      ];

      final kpis = ReportGenerator.calculateKpis(txs, period);
      expect(kpis.totalIncome, 50000.0);
      expect(kpis.totalExpense, 15000.0);
      expect(kpis.netCashFlow, 35000.0);
      expect(kpis.savingsRate, 70.0);
      expect(kpis.expenseRatio, 30.0);
      expect(kpis.healthStatus, FinancialHealthStatus.strongSurplus);
      expect(kpis.totalCount, 3);
      expect(kpis.incomeCount, 1);
      expect(kpis.expenseCount, 2);
    });

    test('calculateKpis identifies deficit status when expense exceeds income', () {
      final now = DateTime.now();
      final period = PeriodRange.fromType(AnalyticsPeriod.thisMonth);

      final txs = [
        TransactionEntity(
          id: '1',
          title: 'งานพิเศษ',
          amount: 5000.0,
          type: TransactionType.income,
          categoryId: 'freelance',
          categoryName: 'งานเสริม',
          categoryIconCode: 0xe3e3,
          categoryColorValue: 0xFF8B5CF6,
          date: now,
        ),
        TransactionEntity(
          id: '2',
          title: 'ซ่อมรถ',
          amount: 12000.0,
          type: TransactionType.expense,
          categoryId: 'transport',
          categoryName: 'การเดินทาง',
          categoryIconCode: 0xe1d5,
          categoryColorValue: 0xFFF59E0B,
          date: now,
        ),
      ];

      final kpis = ReportGenerator.calculateKpis(txs, period);
      expect(kpis.netCashFlow, -7000.0);
      expect(kpis.healthStatus, FinancialHealthStatus.deficit);
    });

    test('calculateCategoryShares aggregates and ranks categories correctly', () {
      final now = DateTime.now();
      final txs = [
        TransactionEntity(
          id: '1',
          title: 'ก๋วยเตี๋ยว',
          amount: 100.0,
          type: TransactionType.expense,
          categoryId: 'food',
          categoryName: 'อาหาร & เครื่องดื่ม',
          categoryIconCode: 0xe532,
          categoryColorValue: 0xFFEF4444,
          date: now,
        ),
        TransactionEntity(
          id: '2',
          title: 'กาแฟ',
          amount: 200.0,
          type: TransactionType.expense,
          categoryId: 'food',
          categoryName: 'อาหาร & เครื่องดื่ม',
          categoryIconCode: 0xe532,
          categoryColorValue: 0xFFEF4444,
          date: now,
        ),
        TransactionEntity(
          id: '3',
          title: 'รถไฟฟ้า',
          amount: 100.0,
          type: TransactionType.expense,
          categoryId: 'transport',
          categoryName: 'การเดินทาง',
          categoryIconCode: 0xe1d5,
          categoryColorValue: 0xFFF59E0B,
          date: now,
        ),
      ];

      final shares = ReportGenerator.calculateCategoryShares(txs);
      expect(shares.length, 2);
      expect(shares.first.categoryId, 'food');
      expect(shares.first.amount, 300.0);
      expect(shares.first.percentage, 75.0);
      expect(shares.last.categoryId, 'transport');
      expect(shares.last.amount, 100.0);
      expect(shares.last.percentage, 25.0);
    });

    test('generateCsv includes UTF-8 BOM, KPI summary, and ledger lines', () {
      final now = DateTime.now();
      final period = PeriodRange.fromType(AnalyticsPeriod.thisMonth);
      final txs = [
        TransactionEntity(
          id: '1',
          title: 'K PLUS โอนเข้า',
          amount: 15000.0,
          type: TransactionType.income,
          categoryId: 'salary',
          categoryName: 'เงินเดือน',
          categoryIconCode: 0xe040,
          categoryColorValue: 0xFF10B981,
          date: now,
          bankId: 'kbank',
          bankShortName: 'K PLUS',
        ),
      ];

      final kpis = ReportGenerator.calculateKpis(txs, period);
      final shares = ReportGenerator.calculateCategoryShares(txs);
      final csv = ReportGenerator.generateCsv(
        transactions: txs,
        period: period,
        kpis: kpis,
        categoryShares: shares,
      );

      // Verify UTF-8 BOM
      expect(csv.startsWith('\uFEFF'), isTrue);
      // Verify headers
      expect(csv, contains('รายงานสรุปสุขภาพการเงินและรายการบัญชี'));
      expect(csv, contains('รายรับรวม (Total Inflow)'));
      expect(csv, contains('K PLUS'));
      expect(csv, contains('15000.00'));
    });

    test('generateExecutiveSummary generates readable formatted text', () {
      final now = DateTime.now();
      final period = PeriodRange.fromType(AnalyticsPeriod.thisMonth);
      final txs = [
        TransactionEntity(
          id: '1',
          title: 'อาหาร',
          amount: 200.0,
          type: TransactionType.expense,
          categoryId: 'food',
          categoryName: 'อาหาร & เครื่องดื่ม',
          categoryIconCode: 0xe532,
          categoryColorValue: 0xFFEF4444,
          date: now,
        ),
      ];

      final kpis = ReportGenerator.calculateKpis(txs, period);
      final shares = ReportGenerator.calculateCategoryShares(txs);
      final text = ReportGenerator.generateExecutiveSummary(
        period: period,
        kpis: kpis,
        categoryShares: shares,
      );

      expect(text, contains('สรุปรายงานสุขภาพการเงิน - เจ้าตูบจด'));
      expect(text, contains('อาหาร & เครื่องดื่ม'));
      expect(text, contains('รวมทั้งหมด 1 รายการ'));
    });
  });
}
