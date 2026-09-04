import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../state/transaction_state.dart';

class TransactionFilterBar extends StatelessWidget {
  final TransactionFilterType currentFilter;
  final ValueChanged<TransactionFilterType> onFilterChanged;

  const TransactionFilterBar({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorderSubtle : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          _buildFilterButton(
            context: context,
            title: 'ทั้งหมด',
            filter: TransactionFilterType.all,
            isSelected: currentFilter == TransactionFilterType.all,
          ),
          _buildFilterButton(
            context: context,
            title: 'รับเงินเข้า (+)',
            imageAsset: 'assets/images/action_income.png',
            filter: TransactionFilterType.income,
            isSelected: currentFilter == TransactionFilterType.income,
            activeColor: AppColors.income,
          ),
          _buildFilterButton(
            context: context,
            title: 'จ่ายเงินออก (-)',
            imageAsset: 'assets/images/action_expense.png',
            filter: TransactionFilterType.expense,
            isSelected: currentFilter == TransactionFilterType.expense,
            activeColor: AppColors.expense,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required BuildContext context,
    required String title,
    String? imageAsset,
    required TransactionFilterType filter,
    required bool isSelected,
    Color? activeColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => onFilterChanged(filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (activeColor != null
                    ? activeColor.withValues(alpha: isDark ? 0.22 : 0.15)
                    : (isDark ? AppColors.darkCard : const Color(0xFFF1F5F9)))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected && !isDark && activeColor == null
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (imageAsset != null) ...[
                Image.asset(
                  imageAsset,
                  width: 16,
                  height: 16,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (activeColor ?? (isDark ? Colors.white : AppColors.lightTextPrimary))
                      : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
