import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../spending_plan/presentation/state/spending_plan_cubit.dart';
import '../../../spending_plan/presentation/state/spending_plan_state.dart';
import '../../../transactions/presentation/state/transaction_cubit.dart';
import '../../../transactions/presentation/state/transaction_state.dart';

class FinanceHubSection extends StatelessWidget {
  const FinanceHubSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 18,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'วางแผน & วิเคราะห์การเงิน',
                style: GoogleFonts.prompt(
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                  letterSpacing: -0.3,
                  color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            // 1. แผนใช้จ่าย (Spending Plan Card)
            Expanded(
              child: _buildSpendingPlanCard(context, isDark),
            ),
            const SizedBox(width: 12),
            // 2. วิเคราะห์ (Analytics Card)
            Expanded(
              child: _buildAnalyticsCard(context, isDark),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpendingPlanCard(BuildContext context, bool isDark) {
    return BlocBuilder<SpendingPlanCubit, SpendingPlanState>(
      buildWhen: (prev, curr) => prev.plan != curr.plan,
      builder: (context, state) {
        final plan = state.plan;
        final hasPlan = plan != null && plan.monthlyIncome > 0;
        final plannedBudget = hasPlan ? plan.totalExpenses : 0.0;
        final targetSavings = hasPlan ? plan.remainingSavings : 0.0;

        return _buildFeatureCard(
          context: context,
          isDark: isDark,
          title: 'แผนใช้จ่าย',
          badgeText: hasPlan ? 'มีแผน' : 'ยังไม่ตั้ง',
          badgeColor: hasPlan ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          icon: Icons.tune_rounded,
          iconGradient: const [Color(0xFFFF9800), Color(0xFFF59E0B)],
          bgGradientLight: const [Color(0xFFFFFBEB), Color(0xFFFFF7ED)],
          bgGradientDark: const [Color(0xFF221A11), Color(0xFF1C1814)],
          borderColorLight: const Color(0xFFFED7AA),
          borderColorDark: const Color(0xFF653910).withValues(alpha: 0.6),
          mainLabel: 'งบใช้จ่ายที่ตั้งไว้',
          mainValue: hasPlan
              ? CurrencyFormatter.formatCompact(plannedBudget)
              : 'แตะเพื่อตั้งงบ',
          subLabel: hasPlan
              ? 'เป้าหมายออม ${CurrencyFormatter.formatCompact(targetSavings)}'
              : 'แบ่งสัดส่วนเงินออม & ใช้จ่าย',
          actionText: 'ปรับแผน',
          actionColor: const Color(0xFFEA580C),
          onTap: () => context.push('/spending-plan'),
        );
      },
    );
  }

  Widget _buildAnalyticsCard(BuildContext context, bool isDark) {
    return BlocBuilder<TransactionCubit, TransactionState>(
      buildWhen: (prev, curr) => prev.transactions != curr.transactions,
      builder: (context, state) {
        final totalIncome = state.totalIncome;
        final totalExpense = state.totalExpense;
        final netSavings = totalIncome - totalExpense;
        final savingsRate = totalIncome > 0
            ? ((netSavings / totalIncome) * 100).clamp(0.0, 100.0)
            : 0.0;

        final hasData = totalIncome > 0 || totalExpense > 0;

        return _buildFeatureCard(
          context: context,
          isDark: isDark,
          title: 'วิเคราะห์',
          badgeText: hasData ? 'สถิติสด' : 'รอข้อมูล',
          badgeColor: const Color(0xFF0284C7),
          icon: Icons.insights_rounded,
          iconGradient: const [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
          bgGradientLight: const [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
          bgGradientDark: const [Color(0xFF0F1B2B), Color(0xFF131D2E)],
          borderColorLight: const Color(0xFFBAE6FD),
          borderColorDark: const Color(0xFF1E3A5F).withValues(alpha: 0.6),
          mainLabel: 'อัตราการออมเงิน',
          mainValue: hasData
              ? '${savingsRate.toStringAsFixed(0)}%'
              : '0%',
          subLabel: hasData
              ? 'สุทธิ ${CurrencyFormatter.formatCompact(netSavings)}'
              : 'ดูสรุปแนวโน้มการเงิน',
          actionText: 'ดูรายงาน',
          actionColor: const Color(0xFF0284C7),
          onTap: () => context.push('/analytics'),
        );
      },
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required bool isDark,
    required String title,
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
    required List<Color> iconGradient,
    required List<Color> bgGradientLight,
    required List<Color> bgGradientDark,
    required Color borderColorLight,
    required Color borderColorDark,
    required String mainLabel,
    required String mainValue,
    required String subLabel,
    required String actionText,
    required Color actionColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? bgGradientDark : bgGradientLight,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? borderColorDark : borderColorLight,
          width: 1.1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: actionColor.withValues(alpha: 0.12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Icon + Title
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                           colors: iconGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.prompt(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Main Value & Label
                Text(
                  mainLabel,
                  style: GoogleFonts.prompt(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  mainValue,
                  style: GoogleFonts.prompt(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),

                // Subtitle
                Text(
                  subLabel,
                  style: GoogleFonts.prompt(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : const Color(0xFF475569),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Action Arrow
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      actionText,
                      style: GoogleFonts.prompt(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? actionColor.withValues(alpha: 0.9) : actionColor,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 11,
                      color: isDark ? actionColor.withValues(alpha: 0.9) : actionColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
