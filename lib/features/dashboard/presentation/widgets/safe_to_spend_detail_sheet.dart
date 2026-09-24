import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';

class SafeToSpendDetailSheet extends StatelessWidget {
  final double totalBudgetLimit;
  final double totalBudgetSpent;
  final double totalBudgetRemaining;
  final int daysRemainingInMonth;
  final int totalDaysInMonth;
  final double dailyBaseAllowance;
  final double todaySpent;
  final double safeToSpendToday;
  final double? effectiveRemaining;

  const SafeToSpendDetailSheet({
    super.key,
    required this.totalBudgetLimit,
    required this.totalBudgetSpent,
    required this.totalBudgetRemaining,
    required this.daysRemainingInMonth,
    required this.totalDaysInMonth,
    required this.dailyBaseAllowance,
    required this.todaySpent,
    required this.safeToSpendToday,
    this.effectiveRemaining,
  });

  static void show(
    BuildContext context, {
    required double totalBudgetLimit,
    required double totalBudgetSpent,
    required double totalBudgetRemaining,
    required int daysRemainingInMonth,
    required int totalDaysInMonth,
    required double dailyBaseAllowance,
    required double todaySpent,
    required double safeToSpendToday,
    double? effectiveRemaining,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SafeToSpendDetailSheet(
        totalBudgetLimit: totalBudgetLimit,
        totalBudgetSpent: totalBudgetSpent,
        totalBudgetRemaining: totalBudgetRemaining,
        daysRemainingInMonth: daysRemainingInMonth,
        totalDaysInMonth: totalDaysInMonth,
        dailyBaseAllowance: dailyBaseAllowance,
        todaySpent: todaySpent,
        safeToSpendToday: safeToSpendToday,
        effectiveRemaining: effectiveRemaining,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExceeded = safeToSpendToday < 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 42,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header with Mascot
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFFFF9E44), const Color(0xFFFF6500)]
                        : [const Color(0xFFFF8F26), const Color(0xFFEA580C)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF7A00).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🐾', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'สูตรคำนวณ Safe-to-Spend',
                      style: GoogleFonts.prompt(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'งบประมาณที่คุณใช้ได้วันนี้อย่างปลอดภัย',
                      style: GoogleFonts.prompt(
                        fontSize: 12.5,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Formula Breakdown Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.7)
                  : const Color(0xFFFFF8F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFFFF7A00).withValues(alpha: 0.25)
                    : const Color(0xFFFF7A00).withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                _buildMathRow(
                  title: 'งบประมาณทั้งเดือน',
                  value: CurrencyFormatter.format(totalBudgetLimit),
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildMathRow(
                  title: 'หัก รายจ่ายสะสมในเดือนนี้',
                  value: '- ${CurrencyFormatter.format(totalBudgetSpent.abs())}',
                  isDark: isDark,
                  textColor: const Color(0xFFF59E0B),
                ),
                const Divider(height: 16),
                _buildMathRow(
                  title: 'คงเหลืองบในเดือนนี้',
                  value: CurrencyFormatter.format(totalBudgetRemaining),
                  isDark: isDark,
                  isBold: true,
                ),
                if (effectiveRemaining != null && effectiveRemaining! < totalBudgetRemaining) ...[
                  const SizedBox(height: 8),
                  _buildMathRow(
                    title: '⚠️ ยอดที่เหลือจริง (จำกัดตามเงินในบัญชี)',
                    value: CurrencyFormatter.format(effectiveRemaining!),
                    isDark: isDark,
                    isBold: true,
                    textColor: const Color(0xFFFBBF24),
                  ),
                ],
                const SizedBox(height: 8),
                _buildMathRow(
                  title: 'หาร วันที่เหลือในเดือน ($daysRemainingInMonth จาก $totalDaysInMonth วัน)',
                  value: '÷ $daysRemainingInMonth วัน',
                  isDark: isDark,
                ),
                const Divider(height: 16),
                _buildMathRow(
                  title: (effectiveRemaining != null && effectiveRemaining! < totalBudgetRemaining)
                      ? 'โควตางบเฉลี่ยต่อวัน (คำนวณจากเหลือจริง)'
                      : 'โควตางบเฉลี่ยต่อวัน',
                  value: CurrencyFormatter.format(
                    (effectiveRemaining != null && effectiveRemaining! < totalBudgetRemaining)
                        ? (daysRemainingInMonth > 0 ? effectiveRemaining! / daysRemainingInMonth : 0.0)
                        : dailyBaseAllowance,
                  ),
                  isDark: isDark,
                  textColor: const Color(0xFF0A84FF),
                ),
                const SizedBox(height: 8),
                _buildMathRow(
                  title: 'หัก ใช้จ่ายไปแล้ววันนี้',
                  value: '- ${CurrencyFormatter.format(todaySpent.abs())}',
                  isDark: isDark,
                  textColor: const Color(0xFFF59E0B),
                ),
                const Divider(height: 20, thickness: 1.2),
                _buildMathRow(
                  title: isExceeded
                      ? 'สถานะงบวันนี้ (ใช้เกินโควต้า)'
                      : 'งบที่ใช้ได้วันนี้ (Safe-to-Spend)',
                  value: isExceeded
                      ? 'เกินงบ ฿${CurrencyFormatter.format(safeToSpendToday.abs())}'
                      : CurrencyFormatter.format(safeToSpendToday),
                  isDark: isDark,
                  isHighlight: true,
                  textColor: isExceeded
                      ? const Color(0xFFF59E0B)
                      : (isDark ? const Color(0xFF34D399) : const Color(0xFF059669)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tip & Explanation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ถ้าวันนี้ใช้น้อยกว่างบ ส่วนที่เหลือจะช่วยเพิ่มงบรายวันในวันต่อๆ ไปโดยอัตโนมัติ! แต่ถ้าใช้เกิน วันถัดไปจะปรับลดลงเล็กน้อยเพื่อความสมดุล 🐾',
                    style: GoogleFonts.prompt(
                      fontSize: 12,
                      height: 1.45,
                      color: isDark ? AppColors.darkTextMuted : const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/budgets');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(
                'จัดการและตั้งงบประมาณ 🐾',
                style: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMathRow({
    required String title,
    required String value,
    required bool isDark,
    bool isBold = false,
    bool isHighlight = false,
    Color? textColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            title,
            style: GoogleFonts.prompt(
              fontSize: isHighlight ? 14.5 : 13,
              fontWeight: isHighlight || isBold ? FontWeight.bold : FontWeight.w500,
              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF334155),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.prompt(
            fontSize: isHighlight ? 17 : 13.5,
            fontWeight: isHighlight || isBold ? FontWeight.w800 : FontWeight.w600,
            color: textColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }
}
