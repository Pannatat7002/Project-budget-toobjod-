import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';

class QuickActionsBar extends StatelessWidget {
  final VoidCallback onAddIncome;
  final VoidCallback onAddExpense;
  final VoidCallback onSetBudget;

  const QuickActionsBar({
    super.key,
    required this.onAddIncome,
    required this.onAddExpense,
    required this.onSetBudget,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: _buildActionItem(
            context: context,
            imageAsset: 'assets/images/action_income.png',
            icon: Icons.arrow_downward,
            label: 'รับเงินเข้า',
            color: AppColors.income,
            onTap: onAddIncome,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionItem(
            context: context,
            imageAsset: 'assets/images/action_expense.png',
            icon: Icons.arrow_upward,
            label: 'จ่ายเงินออก',
            color: AppColors.expense,
            onTap: onAddExpense,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionItem(
            context: context,
            imageAsset: 'assets/images/action_budget.png',
            icon: Icons.pie_chart_outline,
            label: 'ตั้งงบประมาณ',
            color: AppColors.primary,
            onTap: onSetBudget,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required String imageAsset,
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final effectiveColor = color ?? (isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A));

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorderSubtle : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: effectiveColor.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: Image.asset(
                    imageAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: effectiveColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: effectiveColor, size: 28),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
