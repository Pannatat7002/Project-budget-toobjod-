import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';

class ToobJodHeroCard extends StatelessWidget {
  final double totalExpense;
  final double totalIncome;
  final double totalBalance;
  final VoidCallback onViewSummary;

  const ToobJodHeroCard({
    super.key,
    required this.totalExpense,
    required this.totalIncome,
    required this.totalBalance,
    required this.onViewSummary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final monthStr = DateFormatter.formatMonthYear(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Time header text (เช่น 🕒 ยอดสรุปประจำเดือน)
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 13,
                color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
              ),
              const SizedBox(width: 5),
              Text(
                'ยอดสรุปประจำเดือน',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),

        // 2. Orange Hero Card with Overhanging Mascot Dog (ตัวใหญ่โปร่งแสง PNG)
        Stack(
          clipBehavior: Clip.none,
          children: [
            // The Main Vibrant Orange Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8A00), Color(0xFFEA580C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month Picker Pill `< 🗓 ส.ค. 67 >`
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chevron_left, size: 16, color: Colors.white),
                        const SizedBox(width: 2),
                        const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          monthStr,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.chevron_right, size: 16, color: Colors.white),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Label: ยอดใช้จ่าย
                  Text(
                    'ยอดใช้จ่าย',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Big Expense Number & Blue Summary Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Amount
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            CurrencyFormatter.format(totalExpense),
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Blue Pill Button `(⏱ ดูสรุป)`
                      InkWell(
                        onTap: onViewSummary,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: AppColors.blueActionGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.pie_chart_outline_rounded, size: 14, color: Colors.white),
                              SizedBox(width: 5),
                              Text(
                                'ดูสรุป',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Overhanging Mascot Dog (PNG ตัวใหญ่ 95px โผล่ขึ้นมาตรงมุมขวาบนของการ์ดสีส้ม)
            Positioned(
              right: 14,
              top: -30,
              child: IgnorePointer(
                child: SizedBox(
                  width: 95,
                  height: 95,
                  child: Image.asset(
                    'assets/images/mascot_dog_peek.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/mascot_avatar.jpg',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
