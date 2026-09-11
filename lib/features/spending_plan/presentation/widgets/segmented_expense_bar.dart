import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/spending_plan_group.dart';

class SegmentedExpenseBar extends StatelessWidget {
  final List<SpendingPlanGroup> groups;
  final double totalExpenses;

  const SegmentedExpenseBar({
    super.key,
    required this.groups,
    required this.totalExpenses,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'สรุปสัดส่วนค่าใช้จ่าย',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  letterSpacing: -0.3,
                ),
          ),
          const SizedBox(height: 14),

          // Horizontal Stacked Multi-Color Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9),
              ),
              child: totalExpenses == 0
                  ? Container(color: isDark ? AppColors.darkBorder : Colors.grey[300])
                  : Row(
                      children: groups.map((g) {
                        final flexValue = ((g.totalAmount / totalExpenses) * 1000).toInt();
                        if (flexValue <= 0) return const SizedBox.shrink();
                        return Expanded(
                          flex: flexValue,
                          child: Container(
                            color: Color(g.colorValue),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ),
          const SizedBox(height: 18),

          // Group List with Color Dot, Name, and Total Amount
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: groups.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final group = groups[index];
              return Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Color(group.colorValue),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      group.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextPrimary : const Color(0xFF334155),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(group.totalAmount, showDecimals: false),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
