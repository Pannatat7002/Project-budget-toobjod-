import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../utils/report_generator.dart';

class CashFlowBarChart extends StatelessWidget {
  final List<TransactionEntity> transactions;
  final PeriodRange period;
  final bool isDark;

  const CashFlowBarChart({
    super.key,
    required this.transactions,
    required this.period,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final groups = _aggregateCashFlow();

    if (groups.isEmpty) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        child: Text(
          'ไม่มีข้อมูลกระแสเงินสดในช่วงเวลานี้',
          style: GoogleFonts.prompt(
            fontSize: 12,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
      );
    }

    double maxVal = 0.0;
    for (final g in groups) {
      if (g.income > maxVal) maxVal = g.income;
      if (g.expense > maxVal) maxVal = g.expense;
    }
    if (maxVal <= 0) maxVal = 1000.0;
    final maxY = maxVal * 1.25;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildLegendItem(
              color: AppColors.income,
              label: 'เงินเข้า (Inflow)',
            ),
            const SizedBox(width: 14),
            _buildLegendItem(
              color: AppColors.expense,
              label: 'เงินออก (Outflow)',
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Bar Chart
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              alignment: BarChartAlignment.spaceAround,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                  tooltipRoundedRadius: 10,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final isIncomeRod = rodIndex == 0;
                    final title = isIncomeRod ? 'เงินเข้า (+)' : 'เงินออก (-)';
                    return BarTooltipItem(
                      '$title\n${CurrencyFormatter.format(rod.toY)} บ.',
                      GoogleFonts.prompt(
                        color: isIncomeRod ? const Color(0xFF34D399) : const Color(0xFFF87171),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx < 0 || idx >= groups.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          groups[idx].label,
                          style: GoogleFonts.prompt(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      );
                    },
                    reservedSize: 26,
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 3,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  strokeWidth: 0.8,
                  dashArray: [4, 4],
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(groups.length, (i) {
                final g = groups[i];
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: g.income,
                      color: AppColors.income,
                      width: 10,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                    BarChartRodData(
                      toY: g.expense,
                      color: AppColors.expense,
                      width: 10,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.prompt(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  List<_BarGroupData> _aggregateCashFlow() {
    final validTxs = transactions.where((t) => !t.isTransfer).toList();
    if (validTxs.isEmpty) return [];

    // Decide grouping mode based on days in period
    final days = period.dayCount;

    if (days <= 31) {
      // 4 Weeks / Segments of the month (1-7, 8-14, 15-21, 22+)
      final segments = [
        _BarGroupData(label: 'สัปดาห์ 1'),
        _BarGroupData(label: 'สัปดาห์ 2'),
        _BarGroupData(label: 'สัปดาห์ 3'),
        _BarGroupData(label: 'สัปดาห์ 4+'),
      ];

      for (final tx in validTxs) {
        final day = tx.date.day;
        int idx = 0;
        if (day <= 7) {
          idx = 0;
        } else if (day <= 14) {
          idx = 1;
        } else if (day <= 21) {
          idx = 2;
        } else {
          idx = 3;
        }

        if (tx.isIncome) {
          segments[idx].income += tx.amount;
        } else {
          segments[idx].expense += tx.amount;
        }
      }
      return segments;
    } else {
      // Group by Month (up to 6 months)
      final Map<String, _BarGroupData> monthMap = {};
      final sorted = List<TransactionEntity>.from(validTxs)..sort((a, b) => a.date.compareTo(b.date));

      String formatMonth(DateTime d) {
        try {
          return DateFormat('MMM yy', 'th').format(d);
        } catch (_) {
          return '${d.month}/${d.year}';
        }
      }

      for (final tx in sorted) {
        final key = DateFormat('yyyy-MM').format(tx.date);
        if (!monthMap.containsKey(key)) {
          monthMap[key] = _BarGroupData(label: formatMonth(tx.date));
        }
        if (tx.isIncome) {
          monthMap[key]!.income += tx.amount;
        } else {
          monthMap[key]!.expense += tx.amount;
        }
      }

      final list = monthMap.values.toList();
      if (list.length > 6) {
        return list.sublist(list.length - 6);
      }
      return list;
    }
  }
}

class _BarGroupData {
  final String label;
  double income = 0.0;
  double expense = 0.0;

  _BarGroupData({required this.label});
}
