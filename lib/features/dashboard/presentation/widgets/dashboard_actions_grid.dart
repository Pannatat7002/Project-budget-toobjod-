import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_colors.dart';

/// Unified 2-Column Action Panel with Image-Centric Tactile Cards
/// Layout:
/// - Left Column: ตั้งงบประมาณ, แผนใช้จ่าย, วิเคราะห์ (3 items)
/// - Right Column: รับเงิน, จ่ายเงิน (2 items)
class DashboardActionsGrid extends StatelessWidget {
  final VoidCallback onAddIncome;
  final VoidCallback onAddExpense;
  final VoidCallback onSetBudget;
  final VoidCallback onSpendingPlan;
  final VoidCallback onAnalytics;

  const DashboardActionsGrid({
    super.key,
    required this.onAddIncome,
    required this.onAddExpense,
    required this.onSetBudget,
    required this.onSpendingPlan,
    required this.onAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Column (การวางแผน & วิเคราะห์): 3 items
          // 1. ตั้งงบประมาณ
          // 2. แผนใช้จ่าย
          // 3. วิเคราะห์
          Expanded(
            child: Column(
              children: [
                _TactileActionCard(
                  isDark: isDark,
                  title: 'ตั้งงบประมาณ',
                  subtitle: 'คุมงบรายหมวด',
                  imageAsset: 'assets/images/action_budget.png',
                  fallbackIcon: Icons.pie_chart_rounded,
                  accentColor: const Color(0xFF8B5CF6),
                  imageSize: 42,
                  titleFontSize: 12.5,
                  subtitleFontSize: 10,
                  onTap: onSetBudget,
                ),
                const SizedBox(height: 8),
                _TactileActionCard(
                  isDark: isDark,
                  title: 'แผนใช้จ่าย',
                  subtitle: 'สัดส่วน 50/30/20',
                  imageAsset: 'assets/images/action_spending_plan.png',
                  fallbackIcon: Icons.tune_rounded,
                  accentColor: const Color(0xFFEA580C),
                  imageSize: 42,
                  titleFontSize: 12.5,
                  subtitleFontSize: 10,
                  onTap: onSpendingPlan,
                ),
                const SizedBox(height: 8),
                _TactileActionCard(
                  isDark: isDark,
                  title: 'วิเคราะห์',
                  subtitle: 'สถิติ & กราฟสรุป',
                  imageAsset: 'assets/images/action_analytics.png',
                  fallbackIcon: Icons.insights_rounded,
                  accentColor: const Color(0xFF0284C7),
                  imageSize: 42,
                  titleFontSize: 12.5,
                  subtitleFontSize: 10,
                  onTap: onAnalytics,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Right Column (บันทึกรายการประจำวัน): 2 items
          // 1. รับเงิน
          // 2. จ่ายเงิน
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _TactileActionCard(
                    isDark: isDark,
                    title: 'รับเงิน',
                    subtitle: 'บันทึกรายรับ 🐾',
                    imageAsset: 'assets/images/action_income.png',
                    fallbackIcon: Icons.arrow_downward_rounded,
                    accentColor: AppColors.income,
                    imageSize: 48,
                    titleFontSize: 14.5,
                    subtitleFontSize: 11,
                    onTap: onAddIncome,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _TactileActionCard(
                    isDark: isDark,
                    title: 'จ่ายเงิน',
                    subtitle: 'บันทึกรายจ่าย 🐾',
                    imageAsset: 'assets/images/action_expense.png',
                    fallbackIcon: Icons.arrow_upward_rounded,
                    accentColor: AppColors.expense,
                    imageSize: 48,
                    titleFontSize: 14.5,
                    subtitleFontSize: 11,
                    onTap: onAddExpense,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Unified Tactile Action Card featuring prominent 3D artwork as tap focal point
class _TactileActionCard extends StatefulWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final String imageAsset;
  final IconData fallbackIcon;
  final Color accentColor;
  final double imageSize;
  final double titleFontSize;
  final double subtitleFontSize;
  final VoidCallback onTap;

  const _TactileActionCard({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    required this.fallbackIcon,
    required this.accentColor,
    required this.imageSize,
    required this.titleFontSize,
    required this.subtitleFontSize,
    required this.onTap,
  });

  @override
  State<_TactileActionCard> createState() => _TactileActionCardState();
}

class _TactileActionCardState extends State<_TactileActionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveSurface = widget.isDark
        ? AppColors.darkSurface
        : Colors.white;

    final borderColor = widget.isDark
        ? widget.accentColor.withValues(alpha: 0.28)
        : widget.accentColor.withValues(alpha: 0.20);

    return AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOutCubic,
      child: Container(
        decoration: BoxDecoration(
          color: effectiveSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.accentColor.withValues(
                alpha: widget.isDark ? 0.14 : 0.07,
              ),
              blurRadius: 8,
              offset: const Offset(0, 2.5),
            ),
            if (!widget.isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onTap();
            },
            onHighlightChanged: (highlighted) {
              setState(() => _isPressed = highlighted);
            },
            borderRadius: BorderRadius.circular(16),
            splashColor: widget.accentColor.withValues(alpha: 0.12),
            highlightColor: widget.accentColor.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  // 3D Picture (Hero Focal Point)
                  Container(
                    width: widget.imageSize,
                    height: widget.imageSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: [
                        BoxShadow(
                          color: widget.accentColor.withValues(
                            alpha: widget.isDark ? 0.35 : 0.22,
                          ),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.asset(
                        widget.imageAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: BoxDecoration(
                            color: widget.accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            widget.fallbackIcon,
                            color: widget.accentColor,
                            size: widget.imageSize * 0.55,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),

                  // Title & Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.prompt(
                            fontSize: widget.titleFontSize,
                            fontWeight: FontWeight.w700,
                            color: widget.isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1.5),
                        Text(
                          widget.subtitle,
                          style: GoogleFonts.prompt(
                            fontSize: widget.subtitleFontSize,
                            fontWeight: FontWeight.w500,
                            color: widget.isDark
                                ? AppColors.darkTextMuted
                                : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Subtle indicator micro-arrow
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: widget.accentColor.withValues(
                      alpha: widget.isDark ? 0.6 : 0.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
