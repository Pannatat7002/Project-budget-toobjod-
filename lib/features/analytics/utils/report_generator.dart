import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../transactions/domain/entities/transaction_entity.dart';

enum AnalyticsPeriod {
  thisMonth,
  lastMonth,
  last3Months,
  thisYear,
  allTime,
  custom,
}

class PeriodRange {
  final AnalyticsPeriod type;
  final DateTime startDate;
  final DateTime endDate;
  final String label;

  const PeriodRange({
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.label,
  });

  int get dayCount {
    final diff = endDate.difference(startDate).inDays;
    return diff <= 0 ? 1 : diff + 1;
  }

  static PeriodRange fromType(AnalyticsPeriod type, {DateTimeRange? customRange}) {
    final now = DateTime.now();

    switch (type) {
      case AnalyticsPeriod.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        final monthName = _safeMonthYear(now);
        return PeriodRange(
          type: type,
          startDate: start,
          endDate: end,
          label: 'เดือนนี้ ($monthName)',
        );

      case AnalyticsPeriod.lastMonth:
        final lastMonthDate = DateTime(now.year, now.month - 1, 1);
        final start = DateTime(lastMonthDate.year, lastMonthDate.month, 1);
        final end = DateTime(lastMonthDate.year, lastMonthDate.month + 1, 0, 23, 59, 59);
        final monthName = _safeMonthYear(lastMonthDate);
        return PeriodRange(
          type: type,
          startDate: start,
          endDate: end,
          label: 'เดือนที่แล้ว ($monthName)',
        );

      case AnalyticsPeriod.last3Months:
        final start = DateTime(now.year, now.month - 2, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return PeriodRange(
          type: type,
          startDate: start,
          endDate: end,
          label: '3 เดือนย้อนหลัง (ไตรมาส)',
        );

      case AnalyticsPeriod.thisYear:
        final start = DateTime(now.year, 1, 1);
        final end = DateTime(now.year, 12, 31, 23, 59, 59);
        return PeriodRange(
          type: type,
          startDate: start,
          endDate: end,
          label: 'ปีนี้ (ม.ค. - ธ.ค. ${now.year + 543})',
        );

      case AnalyticsPeriod.allTime:
        final start = DateTime(2020, 1, 1);
        final end = DateTime(2030, 12, 31, 23, 59, 59);
        return PeriodRange(
          type: type,
          startDate: start,
          endDate: end,
          label: 'ข้อมูลทั้งหมด (All Time)',
        );

      case AnalyticsPeriod.custom:
        if (customRange != null) {
          final start = DateTime(customRange.start.year, customRange.start.month, customRange.start.day);
          final end = DateTime(customRange.end.year, customRange.end.month, customRange.end.day, 23, 59, 59);
          return PeriodRange(
            type: type,
            startDate: start,
            endDate: end,
            label: '${_safeShortDate(start)} - ${_safeShortDate(end)}',
          );
        }
        return fromType(AnalyticsPeriod.thisMonth);
    }
  }

  static String _safeMonthYear(DateTime dt) {
    try {
      return DateFormat('MMMM yyyy', 'th').format(dt);
    } catch (_) {
      return '${dt.month}/${dt.year}';
    }
  }

  static String _safeShortDate(DateTime dt) {
    try {
      return DateFormat('d MMM yy', 'th').format(dt);
    } catch (_) {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }
}

enum FinancialHealthStatus {
  strongSurplus,
  stable,
  tight,
  deficit,
}

class FinancialKpis {
  final double totalIncome;
  final double totalExpense;
  final double netCashFlow;
  final double savingsRate;
  final double expenseRatio;
  final double dailyBurnRate;
  final int totalCount;
  final int incomeCount;
  final int expenseCount;
  final FinancialHealthStatus healthStatus;

  const FinancialKpis({
    required this.totalIncome,
    required this.totalExpense,
    required this.netCashFlow,
    required this.savingsRate,
    required this.expenseRatio,
    required this.dailyBurnRate,
    required this.totalCount,
    required this.incomeCount,
    required this.expenseCount,
    required this.healthStatus,
  });

  String get healthStatusTitle {
    switch (healthStatus) {
      case FinancialHealthStatus.strongSurplus:
        return 'สุขภาพการเงินยอดเยี่ยม (Strong Surplus) 🌟';
      case FinancialHealthStatus.stable:
        return 'การเงินสมดุลมั่นคง (Balanced) 👍';
      case FinancialHealthStatus.tight:
        return 'เริ่มตึงตัว ควรควบคุมค่าใช้จ่าย (Tight) ⚠️';
      case FinancialHealthStatus.deficit:
        return 'กระแสเงินสดติดลบ ใช้จ่ายเกินรายได้ (Deficit) 🚨';
    }
  }

  String get healthStatusAdvice {
    switch (healthStatus) {
      case FinancialHealthStatus.strongSurplus:
        return 'คุณมีอัตราการออมเงินสูงกว่าเกณฑ์สากล 20% แนะนำให้นำเงินส่วนเกินไปต่อยอดการลงทุนเพื่อความมั่งคั่งระยะยาว';
      case FinancialHealthStatus.stable:
        return 'การเงินอยู่ในเกณฑ์ดี มีเงินออมสำรองสม่ำเสมอ แนะนำให้รักษาวินัยนี้ต่อเนื่อง';
      case FinancialHealthStatus.tight:
        return 'ค่าใช้จ่ายคิดเป็นสัดส่วนสูงกว่า 90% ของรายรับ แนะนำให้ลดค่าใช้จ่ายหมวดหมู่ที่ไม่จำเป็นลง';
      case FinancialHealthStatus.deficit:
        return 'เดือนนี้รายจ่ายสูงกว่ารายรับ แนะนำให้หยุดการใช้จ่ายฟุ่มเฟือยทันที และตรวจสอบหมวดหมู่ที่ใช้เงินมากที่สุด';
    }
  }

  Color get healthStatusColor {
    switch (healthStatus) {
      case FinancialHealthStatus.strongSurplus:
        return const Color(0xFF10B981); // Emerald
      case FinancialHealthStatus.stable:
        return const Color(0xFF0EA5E9); // Sky
      case FinancialHealthStatus.tight:
        return const Color(0xFFF59E0B); // Amber
      case FinancialHealthStatus.deficit:
        return const Color(0xFFEF4444); // Red
    }
  }
}

class CategoryShare {
  final String categoryId;
  final String categoryName;
  final double amount;
  final double percentage;
  final int count;
  final int colorValue;

  const CategoryShare({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.percentage,
    required this.count,
    required this.colorValue,
  });
}

class ReportGenerator {
  static FinancialKpis calculateKpis(
    List<TransactionEntity> transactions,
    PeriodRange period,
  ) {
    double income = 0.0;
    double expense = 0.0;
    int inCount = 0;
    int exCount = 0;

    for (final tx in transactions) {
      if (tx.isTransfer) continue;
      if (tx.isIncome) {
        income += tx.amount;
        inCount++;
      } else {
        expense += tx.amount;
        exCount++;
      }
    }

    final netCashFlow = income - expense;
    final savingsRate = income > 0 ? ((netCashFlow / income) * 100).clamp(-100.0, 100.0) : (expense > 0 ? -100.0 : 0.0);
    final expenseRatio = income > 0 ? ((expense / income) * 100) : (expense > 0 ? 100.0 : 0.0);
    final days = period.dayCount > 0 ? period.dayCount : 1;
    final dailyBurnRate = expense / days;

    FinancialHealthStatus status;
    if (netCashFlow < 0) {
      status = FinancialHealthStatus.deficit;
    } else if (savingsRate >= 20.0) {
      status = FinancialHealthStatus.strongSurplus;
    } else if (savingsRate >= 10.0) {
      status = FinancialHealthStatus.stable;
    } else {
      status = FinancialHealthStatus.tight;
    }

    return FinancialKpis(
      totalIncome: income,
      totalExpense: expense,
      netCashFlow: netCashFlow,
      savingsRate: savingsRate,
      expenseRatio: expenseRatio,
      dailyBurnRate: dailyBurnRate,
      totalCount: inCount + exCount,
      incomeCount: inCount,
      expenseCount: exCount,
      healthStatus: status,
    );
  }

  static List<CategoryShare> calculateCategoryShares(List<TransactionEntity> transactions) {
    final Map<String, _CategoryAggregator> map = {};
    double totalExpense = 0.0;

    for (final tx in transactions) {
      if (tx.isIncome || tx.isTransfer) continue;
      totalExpense += tx.amount;
      if (!map.containsKey(tx.categoryId)) {
        map[tx.categoryId] = _CategoryAggregator(
          id: tx.categoryId,
          name: tx.categoryName,
          colorValue: tx.categoryColorValue,
        );
      }
      map[tx.categoryId]!.amount += tx.amount;
      map[tx.categoryId]!.count++;
    }

    if (totalExpense <= 0) return [];

    final list = map.values.map((agg) {
      final pct = (agg.amount / totalExpense) * 100;
      return CategoryShare(
        categoryId: agg.id,
        categoryName: agg.name,
        amount: agg.amount,
        percentage: pct,
        count: agg.count,
        colorValue: agg.colorValue,
      );
    }).toList();

    list.sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  /// Generates RFC 4180 compliant CSV with UTF-8 BOM (\uFEFF) for Excel compatibility
  static String generateCsv({
    required List<TransactionEntity> transactions,
    required PeriodRange period,
    required FinancialKpis kpis,
    required List<CategoryShare> categoryShares,
  }) {
    final buffer = StringBuffer();

    // 1. UTF-8 BOM so Microsoft Excel renders Thai text perfectly
    buffer.write('\uFEFF');

    // 2. Executive Report Header
    final nowStr = _safeFullDateTime(DateTime.now());
    buffer.writeln('รายงานสรุปสุขภาพการเงินและรายการบัญชี (Financial & Ledger Report)');
    buffer.writeln('แอปพลิเคชัน,เจ้าตูบจด (ToobJod Budget Planner)');
    buffer.writeln('ช่วงเวลาที่วิเคราะห์,"${period.label}"');
    buffer.writeln('วันที่ออกรายงาน,"$nowStr"');
    buffer.writeln('หน่วยเงิน,บาท (THB)');
    buffer.writeln('');

    // 3. KPI Metrics Summary
    buffer.writeln('--- สรุปภาพรวมทางการเงิน (Executive Financial KPIs) ---');
    buffer.writeln('ดัชนีชี้วัด,ค่าที่วัดได้,เกณฑ์มาตรฐานสากล');
    buffer.writeln('รายรับรวม (Total Inflow),${kpis.totalIncome.toStringAsFixed(2)},-');
    buffer.writeln('รายจ่ายรวม (Total Outflow),${kpis.totalExpense.toStringAsFixed(2)},-');
    buffer.writeln('กระแสเงินสดสุทธิ (Net Cash Flow),${kpis.netCashFlow.toStringAsFixed(2)},ควรเป็นบวก');
    buffer.writeln('อัตราการออมเงิน (Savings Rate),${kpis.savingsRate.toStringAsFixed(1)}%,มาตรฐานสากล >= 20%');
    buffer.writeln('อัตราส่วนรายจ่ายต่อรายรับ (Expense Ratio),${kpis.expenseRatio.toStringAsFixed(1)}%,มาตรฐานไม่เกิน 70-80%');
    buffer.writeln('ค่าใช้จ่ายเฉลี่ยต่อวัน (Daily Burn Rate),${kpis.dailyBurnRate.toStringAsFixed(2)},-');
    buffer.writeln('การประเมินสุขภาพการเงิน,"${kpis.healthStatusTitle}","${kpis.healthStatusAdvice}"');
    buffer.writeln('');

    // 4. Category Spending Breakdown
    buffer.writeln('--- สรุปสัดส่วนค่าใช้จ่ายตามหมวดหมู่ (Category Breakdown) ---');
    buffer.writeln('ลำดับ,หมวดหมู่,จำนวนรายการ,ยอดรวม (บาท),สัดส่วน (%)');
    for (int i = 0; i < categoryShares.length; i++) {
      final cat = categoryShares[i];
      buffer.writeln('${i + 1},"${_escapeCsv(cat.categoryName)}",${cat.count},${cat.amount.toStringAsFixed(2)},${cat.percentage.toStringAsFixed(1)}%');
    }
    buffer.writeln('');

    // 5. Detailed Transaction Ledger
    buffer.writeln('--- รายละเอียดรายการธุรกรรมทั้งหมด (Transaction Ledger) ---');
    buffer.writeln('วันที่,เวลา,ประเภท,หมวดหมู่,ชื่อรายการ/ร้านค้า,ธนาคาร/บัญชี,เลขบัญชี,หมายเหตุ,จำนวนเงิน (บาท)');

    final sortedTxs = List<TransactionEntity>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    for (final tx in sortedTxs) {
      final date = dateFormat.format(tx.date);
      final time = timeFormat.format(tx.date);
      final type = tx.isTransfer ? 'โอน' : (tx.isIncome ? 'รายรับ' : 'รายจ่าย');
      final amountPrefix = tx.isTransfer ? '' : (tx.isIncome ? '+' : '-');
      final amountStr = '$amountPrefix${tx.amount.toStringAsFixed(2)}';
      final bank = tx.bankShortName ?? tx.bankId ?? '-';
      final mask = tx.accountMask ?? '-';
      final note = tx.note ?? '-';

      buffer.writeln(
        '"$date","$time","$type","${_escapeCsv(tx.categoryName)}","${_escapeCsv(tx.title)}","${_escapeCsv(bank)}","${_escapeCsv(mask)}","${_escapeCsv(note)}",$amountStr',
      );
    }

    return buffer.toString();
  }

  /// Generates a clean, formatted executive summary text for copying or messaging
  static String generateExecutiveSummary({
    required PeriodRange period,
    required FinancialKpis kpis,
    required List<CategoryShare> categoryShares,
  }) {
    final nowStr = _safeExecutiveDate(DateTime.now());
    final buffer = StringBuffer();

    buffer.writeln('🐾 สรุปรายงานสุขภาพการเงิน - เจ้าตูบจด');
    buffer.writeln('📅 ช่วงเวลา: ${period.label}');
    buffer.writeln('⏱️ วันที่ออกรายงาน: $nowStr');
    buffer.writeln('────────────────────────');
    buffer.writeln('💰 รายรับรวม:  +${CurrencyFormatter.format(kpis.totalIncome)} บ.');
    buffer.writeln('💸 รายจ่ายรวม: -${CurrencyFormatter.format(kpis.totalExpense)} บ.');
    buffer.writeln('${kpis.netCashFlow >= 0 ? "✨" : "⚠️"} กระแสเงินสดสุทธิ: ${kpis.netCashFlow >= 0 ? "+" : ""}${CurrencyFormatter.format(kpis.netCashFlow)} บ.');
    buffer.writeln('📊 อัตราการออม (Savings Rate): ${kpis.savingsRate.toStringAsFixed(1)}% (เป้าหมายสากล ≥ 20%)');
    buffer.writeln('🔥 ค่าใช้จ่ายเฉลี่ยต่อวัน: ${CurrencyFormatter.format(kpis.dailyBurnRate)} บ./วัน');
    buffer.writeln('🏥 สุขภาพการเงิน: ${kpis.healthStatusTitle}');
    buffer.writeln('────────────────────────');

    if (categoryShares.isNotEmpty) {
      buffer.writeln('🏆 หมวดหมู่รายจ่ายสูงสุด:');
      final top3 = categoryShares.take(3).toList();
      for (int i = 0; i < top3.length; i++) {
        final c = top3[i];
        buffer.writeln('${i + 1}. ${c.categoryName}: ${CurrencyFormatter.format(c.amount)} บ. (${c.percentage.toStringAsFixed(1)}%)');
      }
      buffer.writeln('────────────────────────');
    }

    buffer.writeln('📝 รวมทั้งหมด ${kpis.totalCount} รายการ');
    buffer.writeln('สร้างจากแอป "เจ้าตูบจด" ผู้ช่วยวางแผนคุมงบการเงิน 🐾');

    return buffer.toString();
  }

  static String _escapeCsv(String val) {
    return val.replaceAll('"', '""');
  }

  static String _safeFullDateTime(DateTime dt) {
    try {
      return DateFormat('dd/MM/yyyy HH:mm', 'th').format(dt);
    } catch (_) {
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute}';
    }
  }

  static String _safeExecutiveDate(DateTime dt) {
    try {
      return DateFormat('d MMM yyyy HH:mm', 'th').format(dt);
    } catch (_) {
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute}';
    }
  }
}

class _CategoryAggregator {
  final String id;
  final String name;
  final int colorValue;
  double amount = 0.0;
  int count = 0;

  _CategoryAggregator({
    required this.id,
    required this.name,
    required this.colorValue,
  });
}
