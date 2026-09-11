import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';

class CompactMonthSummaryHeader extends StatelessWidget {
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;
  final List<DateTime> availableMonths;
  final Map<DateTime, int>? transactionCounts;
  final double totalIncome;
  final double totalExpense;
  final double totalBalance;
  final bool isEyeViewHidden;
  final VoidCallback onToggleEyeView;

  const CompactMonthSummaryHeader({
    super.key,
    required this.selectedMonth,
    required this.onMonthChanged,
    required this.availableMonths,
    this.transactionCounts,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalBalance,
    required this.isEyeViewHidden,
    required this.onToggleEyeView,
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
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkBorderSubtle : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Row 1: Month Selector & Eye Toggle
            Row(
              children: [
                // Previous Month Button
                _buildNavIcon(
                  icon: Icons.chevron_left_rounded,
                  enabled: canGoEarlier,
                  onTap: goToPreviousMonth,
                  isDark: isDark,
                  tooltip: 'เดือนก่อนหน้า',
                ),

                // Center Month Pill / Text (Tap to pick)
                Expanded(
                  child: Center(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showAvailableMonthsSheet(context, effectiveMonths),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Text(
                                    DateFormatter.formatMonthYear(selectedMonth),
                                    key: ValueKey('${selectedMonth.year}-${selectedMonth.month}'),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Next Month Button
                _buildNavIcon(
                  icon: Icons.chevron_right_rounded,
                  enabled: canGoLater,
                  onTap: goToNextMonth,
                  isDark: isDark,
                  tooltip: 'เดือนถัดไป',
                ),

                // Small Divider
                Container(
                  width: 1,
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: isDark ? AppColors.darkBorderSubtle : const Color(0xFFE2E8F0),
                ),

                // Eye Toggle Button
                Tooltip(
                  message: isEyeViewHidden ? 'แสดงยอดเงิน' : 'ซ่อนยอดเงิน',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onToggleEyeView,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          isEyeViewHidden
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Row 2: 3-Column Quick Metrics Summary
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  // 1. Income (รายรับ)
                  Expanded(
                    child: _buildMetricItem(
                      label: 'รายรับ',
                      amount: totalIncome,
                      color: AppColors.income,
                      prefix: '+',
                      isEyeHidden: isEyeViewHidden,
                      isDark: isDark,
                    ),
                  ),

                  // Divider
                  Container(
                    width: 1,
                    height: 24,
                    color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                  ),

                  // 2. Expense (รายจ่าย)
                  Expanded(
                    child: _buildMetricItem(
                      label: 'รายจ่าย',
                      amount: totalExpense,
                      color: AppColors.expense,
                      prefix: '-',
                      isEyeHidden: isEyeViewHidden,
                      isDark: isDark,
                    ),
                  ),

                  // Divider
                  Container(
                    width: 1,
                    height: 24,
                    color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                  ),

                  // 3. Balance (คงเหลือสุทธิ)
                  Expanded(
                    child: _buildMetricItem(
                      label: 'คงเหลือ',
                      amount: totalBalance,
                      color: totalBalance >= 0
                          ? (isDark ? Colors.white : const Color(0xFF0F172A))
                          : AppColors.expense,
                      prefix: totalBalance > 0 ? '+' : '',
                      isEyeHidden: isEyeViewHidden,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    required bool isDark,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              icon,
              size: 22,
              color: enabled
                  ? (isDark ? Colors.white : const Color(0xFF1E293B))
                  : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required double amount,
    required Color color,
    required String prefix,
    required bool isEyeHidden,
    required bool isDark,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            isEyeHidden ? '••••••' : '$prefix${CurrencyFormatter.format(amount.abs())}',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }

  void _showAvailableMonthsSheet(BuildContext context, List<DateTime> months) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    final reversedMonths = List<DateTime>.from(months)
      ..sort((a, b) => b.compareTo(a));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'เลือกเดือนที่มีรายการ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${reversedMonths.length} เดือน',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: reversedMonths.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final month = reversedMonths[index];
                    final isSelected = month.year == selectedMonth.year && month.month == selectedMonth.month;
                    final isCurrent = month.year == now.year && month.month == now.month;
                    final count = transactionCounts?[month] ?? 0;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          onMonthChanged(month);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.12)
                                : (isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark ? AppColors.darkBorderSubtle : const Color(0xFFE2E8F0)),
                              width: isSelected ? 1.6 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 16,
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  DateFormatter.formatMonthYear(month),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected
                                        ? (isDark ? Colors.white : AppColors.primary)
                                        : (isDark ? Colors.white : AppColors.lightTextPrimary),
                                  ),
                                ),
                              ),
                              if (isCurrent) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'เดือนนี้',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (count > 0)
                                Text(
                                  '$count รายการ',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                ),
                              if (isSelected) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primary),
                              ],
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
      ),
    );
  }
}
