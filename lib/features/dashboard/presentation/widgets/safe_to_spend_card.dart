import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import 'safe_to_spend_detail_sheet.dart';

class SafeToSpendCard extends StatelessWidget {
  final double totalBudgetLimit;
  final double totalBudgetSpent;
  final double totalBudgetRemaining;
  final int daysRemainingInMonth;
  final int totalDaysInMonth;
  final double dailyBaseAllowance;
  final double todaySpent;
  final double? actualAccountBalance;
  final VoidCallback? onSetBudgetTap;

  const SafeToSpendCard({
    super.key,
    required this.totalBudgetLimit,
    required this.totalBudgetSpent,
    required this.totalBudgetRemaining,
    required this.daysRemainingInMonth,
    required this.totalDaysInMonth,
    required this.dailyBaseAllowance,
    required this.todaySpent,
    this.actualAccountBalance,
    this.onSetBudgetTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasBudget = totalBudgetLimit > 0;
    final dynamicDailyAllowance = daysRemainingInMonth > 0
        ? (totalBudgetRemaining / daysRemainingInMonth)
        : dailyBaseAllowance;

    // Hybrid Safe-Guard: Cap with cash if actual bank balance is lower than remaining budget
    final isCashConstrained = actualAccountBalance != null &&
        actualAccountBalance! < totalBudgetRemaining;
    final effectiveDailyAllowance = isCashConstrained
        ? (daysRemainingInMonth > 0 ? actualAccountBalance! / daysRemainingInMonth : 0.0).clamp(0.0, dynamicDailyAllowance)
        : dynamicDailyAllowance;

    final safeToSpendToday = hasBudget ? effectiveDailyAllowance - todaySpent : 0.0;
    final isExceeded = hasBudget && safeToSpendToday < 0;

    // Daily progress percentage (0.0 to 1.0+)
    final dailyProgress = (hasBudget && effectiveDailyAllowance > 0)
        ? (todaySpent / effectiveDailyAllowance).clamp(0.0, 1.5)
        : 0.0;

    // Mood & Mascot Advice
    String mascotMoodText;
    Color moodColor;
    IconData moodIcon;

    if (!hasBudget) {
      mascotMoodText = 'ยังไม่ได้ตั้งงบเดือนนี้ แตะเพื่อเริ่มคุมเงิน 🐾';
      moodColor = const Color(0xFFFF7A00);
      moodIcon = Icons.add_circle_outline_rounded;
    } else if (isCashConstrained && actualAccountBalance! <= 0) {
      mascotMoodText = '⚠️ เงินในบัญชีหมดแล้ว งดใช้จ่ายชั่วคราวน้าโฮ่ง 🦴';
      moodColor = const Color(0xFFF59E0B);
      moodIcon = Icons.warning_amber_rounded;
    } else if (isExceeded) {
      final overAmount = CurrencyFormatter.format(safeToSpendToday.abs());
      mascotMoodText = 'วันนี้เกินงบไป $overAmount พรุ่งนี้ค่อยลดลงหน่อยโฮ่ง 🦴';
      moodColor = const Color(0xFFF59E0B);
      moodIcon = Icons.warning_amber_rounded;
    } else if (isCashConstrained) {
      mascotMoodText = '⚠️ เงินในบัญชีเหลือน้อยกว่างบ ปรับลดงบวันนี้เพื่อความปลอดภัย 🐾';
      moodColor = const Color(0xFFF59E0B);
      moodIcon = Icons.shield_outlined;
    } else if (dailyProgress >= 0.75) {
      mascotMoodText = 'ใกล้ชนเพดานงบวันนี้แล้ว ค่อยๆ ใช้น้าโฮ่ง 🐾';
      moodColor = const Color(0xFFF59E0B);
      moodIcon = Icons.pets;
    } else {
      mascotMoodText = 'วันนี้กินช้อปได้สบายใจ ยังอยู่ในงบโฮ่ง! 🍖';
      moodColor = const Color(0xFF10B981);
      moodIcon = Icons.sentiment_very_satisfied_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1A2338),
                  const Color(0xFF111827),
                ]
              : [
                  const Color(0xFFFFF9F5),
                  const Color(0xFFFFFFFF),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? moodColor.withValues(alpha: 0.35)
              : moodColor.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: moodColor.withValues(alpha: isDark ? 0.12 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            if (!hasBudget && onSetBudgetTap != null) {
              onSetBudgetTap!();
            } else {
              SafeToSpendDetailSheet.show(
                context,
                totalBudgetLimit: totalBudgetLimit,
                totalBudgetSpent: totalBudgetSpent,
                totalBudgetRemaining: totalBudgetRemaining,
                effectiveRemaining:
                    isCashConstrained ? actualAccountBalance : null,
                daysRemainingInMonth: daysRemainingInMonth,
                totalDaysInMonth: totalDaysInMonth,
                dailyBaseAllowance: dailyBaseAllowance,
                todaySpent: todaySpent,
                safeToSpendToday: safeToSpendToday,
              );
            }
          },
          borderRadius: BorderRadius.circular(20),
          splashColor: moodColor.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: moodColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(moodIcon, size: 12, color: moodColor),
                              const SizedBox(width: 4),
                              Text(
                                'งบที่ใช้ได้วันนี้',
                                style: GoogleFonts.prompt(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: moodColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Safe-to-Spend',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'สูตรคำนวณ',
                          style: GoogleFonts.prompt(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 15,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Big Amount & Today Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      hasBudget
                          ? (isExceeded
                              ? 'เกินงบ ฿${CurrencyFormatter.format(safeToSpendToday.abs())}'
                              : CurrencyFormatter.format(safeToSpendToday))
                          : 'ตั้งงบเลย 🐾',
                      style: GoogleFonts.prompt(
                        fontSize: hasBudget ? 27 : 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: !hasBudget
                            ? const Color(0xFFFF7A00)
                            : isExceeded
                                ? const Color(0xFFF59E0B)
                                : (isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                    ),
                    if (hasBudget) ...[
                      const SizedBox(width: 6),
                      Text(
                        '/ วันนี้',
                        style: GoogleFonts.prompt(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),

                // Mascot Advice speech
                Text(
                  mascotMoodText,
                  style: GoogleFonts.prompt(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: moodColor,
                  ),
                ),
                const SizedBox(height: 10),

                // Progress bar (only if budget is active)
                if (hasBudget) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: dailyProgress > 1.0 ? 1.0 : dailyProgress,
                      minHeight: 5,
                      backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isExceeded
                            ? const Color(0xFFF59E0B)
                            : dailyProgress >= 0.75
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF10B981),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'วันนี้ใช้ไป: ${CurrencyFormatter.format(todaySpent.abs())}',
                        style: GoogleFonts.prompt(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                      Text(
                        'เหลืออีก $daysRemainingInMonth วันในเดือนนี้',
                        style: GoogleFonts.prompt(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
