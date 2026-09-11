import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';

class MonthSelectorBar extends StatelessWidget {
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;
  final List<DateTime> availableMonths;
  final Map<DateTime, int>? transactionCounts;

  const MonthSelectorBar({
    super.key,
    required this.selectedMonth,
    required this.onMonthChanged,
    required this.availableMonths,
    this.transactionCounts,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sortedMonths = List<DateTime>.from(availableMonths)
      ..sort((a, b) => a.compareTo(b));

    final effectiveMonths = sortedMonths.isNotEmpty
        ? sortedMonths
        : [DateTime(DateTime.now().year, DateTime.now().month)];

    int currentIndex = effectiveMonths.indexWhere(
      (m) => m.year == selectedMonth.year && m.month == selectedMonth.month,
    );
    if (currentIndex == -1) {
      currentIndex = effectiveMonths.length - 1;
    }

    final canGoEarlier = currentIndex > 0;
    final canGoLater = currentIndex < effectiveMonths.length - 1;

    void goToPreviousMonth() {
      if (canGoEarlier) {
        onMonthChanged(effectiveMonths[currentIndex - 1]);
      }
    }

    void goToNextMonth() {
      if (canGoLater) {
        onMonthChanged(effectiveMonths[currentIndex + 1]);
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        if (details.primaryVelocity! < -150) {
          goToNextMonth();
        } else if (details.primaryVelocity! > 150) {
          goToPreviousMonth();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 1. < Button (Previous Month with transactions)
            _buildNavButton(
              context: context,
              icon: Icons.chevron_left_rounded,
              tooltip: canGoEarlier
                  ? 'เดือนก่อนหน้า (${DateFormatter.formatMonthYear(effectiveMonths[currentIndex - 1])})'
                  : 'ไม่มีรายการในเดือนก่อนหน้าแล้ว',
              enabled: canGoEarlier,
              onTap: goToPreviousMonth,
              isDark: isDark,
            ),

            // 2. Middle Month Display: แสดง Text โดยตรง ไม่ต้องมีกล่อง/border ซ้อน
            Expanded(
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showAvailableMonthsSheet(context, effectiveMonths),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.0, 0.15),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: Text(
                                'เดือน : ${DateFormatter.formatMonthYear(selectedMonth)}',
                                key: ValueKey('${selectedMonth.year}-${selectedMonth.month}'),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 3. > Button (Next Month with transactions)
            _buildNavButton(
              context: context,
              icon: Icons.chevron_right_rounded,
              tooltip: canGoLater
                  ? 'เดือนถัดไป (${DateFormatter.formatMonthYear(effectiveMonths[currentIndex + 1])})'
                  : 'ไม่มีรายการในเดือนถัดไปแล้ว',
              enabled: canGoLater,
              onTap: goToNextMonth,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required bool enabled,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Icon(
              icon,
              size: 24,
              color: enabled
                  ? (isDark ? Colors.white : const Color(0xFF1E293B))
                  : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
            ),
          ),
        ),
      ),
    );
  }

  void _showAvailableMonthsSheet(BuildContext context, List<DateTime> months) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AvailableMonthsBottomSheet(
        availableMonths: months,
        selectedMonth: selectedMonth,
        transactionCounts: transactionCounts,
        onMonthSelected: (date) {
          Navigator.pop(ctx);
          onMonthChanged(date);
        },
      ),
    );
  }
}

class _AvailableMonthsBottomSheet extends StatelessWidget {
  final List<DateTime> availableMonths;
  final DateTime selectedMonth;
  final Map<DateTime, int>? transactionCounts;
  final ValueChanged<DateTime> onMonthSelected;

  const _AvailableMonthsBottomSheet({
    required this.availableMonths,
    required this.selectedMonth,
    this.transactionCounts,
    required this.onMonthSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    final reversedMonths = List<DateTime>.from(availableMonths)
      ..sort((a, b) => b.compareTo(a));

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 42,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header with ToobJod Mascot accent
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: AppColors.orangeBadgeGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_month_rounded, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'เลือกเดือนที่มีรายการ 🐾',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      'แตะเพื่อสลับดูรายการในแต่ละเดือน',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${reversedMonths.length} เดือน',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Available Months List
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: reversedMonths.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final month = reversedMonths[index];
                  final isSelected = month.year == selectedMonth.year && month.month == selectedMonth.month;
                  final isCurrentMonth = month.year == now.year && month.month == now.month;
                  final count = transactionCounts?[month] ?? 0;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onMonthSelected(month),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.12)
                              : (isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? AppColors.darkBorderSubtle : const Color(0xFFE2E8F0)),
                            width: isSelected ? 1.8 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark ? AppColors.darkCard : Colors.white),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark ? AppColors.darkBorderSubtle : const Color(0xFFE2E8F0)),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.calendar_today_rounded,
                                size: 16,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        DateFormatter.formatMonthYear(month),
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                          color: isSelected
                                              ? (isDark ? Colors.white : AppColors.primary)
                                              : (isDark ? Colors.white : AppColors.lightTextPrimary),
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      if (isCurrentMonth) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            gradient: AppColors.orangeBadgeGradient,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'เดือนนี้ 🐾',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (count > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        '$count รายการ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 22,
                                color: AppColors.primary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
