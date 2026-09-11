import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';

class SpendingSummaryHeader extends StatelessWidget {
  final double monthlyIncome;
  final double totalExpenses;
  final double remainingSavings;
  final double savingsRatioPercentage;
  final VoidCallback onEditIncome;

  const SpendingSummaryHeader({
    super.key,
    required this.monthlyIncome,
    required this.totalExpenses,
    required this.remainingSavings,
    required this.savingsRatioPercentage,
    required this.onEditIncome,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPositiveSavings = remainingSavings >= 0;
    final expenseRatio = monthlyIncome > 0 ? ((totalExpenses / monthlyIncome) * 100).clamp(0.0, 100.0) : 0.0;
    final savingsRatio = monthlyIncome > 0 ? ((remainingSavings / monthlyIncome) * 100).clamp(0.0, 100.0) : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Monthly Income Header with Tap to Edit Button
          InkWell(
            onTap: onEditIncome,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF18264A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF22355E) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_wallet, size: 15, color: AppColors.accent),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'รายรับประจำเดือน',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary,
                            ),
                          ),
                          Text(
                            monthlyIncome > 0
                                ? CurrencyFormatter.format(monthlyIncome, showDecimals: false)
                                : '฿0 (แตะเพื่อตั้งค่า)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: monthlyIncome > 0
                                  ? (isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A))
                                  : AppColors.primary,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          monthlyIncome > 0 ? Icons.edit_outlined : Icons.add_circle_outline,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          monthlyIncome > 0 ? 'แก้ไขรายรับ' : 'ระบุรายรับ',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 2. Dual Comparison Cards (แผนงบรายจ่าย vs คาดว่าจะเหลือเก็บ)
          Row(
            children: [
              // Card 1: แผนงบรายจ่ายรวม (Shiba Orange)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.25),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'แผนงบรายจ่ายรวม',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.primaryLight : const Color(0xFFC2410C),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          CurrencyFormatter.format(totalExpenses, showDecimals: false),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF9A3412),
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${expenseRatio.toStringAsFixed(0)}% ของรายรับ',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextMuted : const Color(0xFFEA580C),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Card 2: คาดว่าจะเหลือเก็บ (Royal Blue)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: (isPositiveSavings ? AppColors.accent : const Color(0xFFEF4444))
                        .withValues(alpha: isDark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (isPositiveSavings ? AppColors.accent : const Color(0xFFEF4444))
                          .withValues(alpha: isDark ? 0.35 : 0.25),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isPositiveSavings ? AppColors.accent : const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isPositiveSavings ? 'คาดว่าจะเหลือเก็บ' : 'แผนงบเกินรายรับ!',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isPositiveSavings
                                  ? (isDark ? AppColors.accentLight : const Color(0xFF1D4ED8))
                                  : const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          CurrencyFormatter.format(remainingSavings, showDecimals: false),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isPositiveSavings
                                ? (isDark ? Colors.white : const Color(0xFF1E40AF))
                                : const Color(0xFFDC2626),
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPositiveSavings
                            ? '${savingsRatio.toStringAsFixed(0)}% เป้าหมายเงินออม'
                            : 'เกินงบ ${CurrencyFormatter.format(remainingSavings.abs(), showDecimals: false)}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: isPositiveSavings
                              ? (isDark ? AppColors.darkTextMuted : const Color(0xFF2563EB))
                              : const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3. Dual Ratio Progress Bar (หลอดเปรียบเทียบสัดส่วน แผนจ่าย vs เงินออม)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'สัดส่วนการจัดสรรเงิน',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary,
                    ),
                  ),
                  Text(
                    'แผนใช้จ่าย ${expenseRatio.toStringAsFixed(0)}% / ออม ${savingsRatio.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Stacked Progress Bar (Orange vs Blue)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF18264A) : const Color(0xFFF1F5F9),
                  ),
                  child: Row(
                    children: [
                      // Expense Ratio (Orange)
                      if (expenseRatio > 0)
                        Expanded(
                          flex: (expenseRatio * 10).toInt().clamp(1, 1000),
                          child: Container(color: AppColors.primary),
                        ),
                      // Savings Ratio (Royal Blue)
                      if (savingsRatio > 0)
                        Expanded(
                          flex: (savingsRatio * 10).toInt().clamp(1, 1000),
                          child: Container(color: AppColors.accent),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
