import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
            title: 'เงินเข้า (+)',
            imageAsset: 'assets/images/action_income.png',
            filter: TransactionFilterType.income,
            isSelected: currentFilter == TransactionFilterType.income,
            activeColor: AppColors.income,
          ),
          _buildFilterButton(
            context: context,
            title: 'เงินออก (-)',
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
        onTap: () {
          if (!isSelected) {
            HapticFeedback.selectionClick();
          }
          onFilterChanged(filter);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? (activeColor != null
                    ? activeColor.withValues(alpha: isDark ? 0.22 : 0.15)
                    : (isDark ? AppColors.darkCard : const Color(0xFFF1F5F9)))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected && activeColor != null
                ? Border.all(
                    color: activeColor.withValues(alpha: isDark ? 0.4 : 0.3),
                    width: 0.8,
                  )
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (imageAsset != null) ...[
                Image.asset(
                  imageAsset,
                  width: 14,
                  height: 14,
                  cacheWidth: 42,
                  cacheHeight: 42,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: GoogleFonts.prompt(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? (activeColor ?? (isDark ? Colors.white : AppColors.lightTextPrimary))
                          : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
