import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';

class CategoryPieChart extends StatefulWidget {
  final List<TransactionEntity> transactions;

  const CategoryPieChart({super.key, required this.transactions});

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expenseTransactions = widget.transactions.where((t) => t.isExpense).toList();
    final totalExpense = expenseTransactions.fold(0.0, (sum, t) => sum + t.amount);

    if (totalExpense == 0) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: Text(
          'ยังไม่มีรายการค่าใช้จ่ายเพื่อสร้างกราฟ',
          style: TextStyle(
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
      );
    }

    // Group expenses by category
    final Map<String, _CategoryBreakdown> categoryMap = {};
    for (final tx in expenseTransactions) {
      if (!categoryMap.containsKey(tx.categoryId)) {
        categoryMap[tx.categoryId] = _CategoryBreakdown(
          id: tx.categoryId,
          name: tx.categoryName,
          color: Color(tx.categoryColorValue),
          amount: tx.amount,
        );
      } else {
        categoryMap[tx.categoryId]!.amount += tx.amount;
      }
    }

    final categories = categoryMap.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 3,
                  centerSpaceRadius: 60,
                  sections: List.generate(categories.length, (i) {
                    final isTouched = i == touchedIndex;
                    final cat = categories[i];
                    final percentage = (cat.amount / totalExpense) * 100;
                    final radius = isTouched ? 30.0 : 22.0;

                    return PieChartSectionData(
                      color: cat.color,
                      value: cat.amount,
                      title: isTouched ? '${percentage.toStringAsFixed(0)}%' : '',
                      radius: radius,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'รายจ่ายรวม',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.formatCompact(totalExpense),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Legend Breakdown List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final cat = categories[index];
            final percent = ((cat.amount / totalExpense) * 100).toStringAsFixed(1);

            return Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: cat.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
                Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  CurrencyFormatter.format(cat.amount),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CategoryBreakdown {
  final String id;
  final String name;
  final Color color;
  double amount;

  _CategoryBreakdown({
    required this.id,
    required this.name,
    required this.color,
    required this.amount,
  });
}
