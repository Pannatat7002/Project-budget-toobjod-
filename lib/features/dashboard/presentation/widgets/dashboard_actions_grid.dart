import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_colors.dart';

/// Unified Action Panel with Image-Centric Tactile Cards
/// Layout:
/// - Left Column: วิเคราะห์ (ขยายเต็มความสูง)
/// - Right Column: รับเงิน, จ่ายเงิน, โอนย้าย (3 items)
class DashboardActionsGrid extends StatelessWidget {
  final VoidCallback onAddIncome;
  final VoidCallback onAddExpense;
  final VoidCallback onTransfer;
  final VoidCallback? onSetBudget;
  final VoidCallback onAnalytics;

  const DashboardActionsGrid({
    super.key,
    required this.onAddIncome,
    required this.onAddExpense,
    required this.onTransfer,
    this.onSetBudget,
    required this.onAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Column (วิเคราะห์): ขยายเต็มความสูงเทียบเท่า 3 การ์ดฝั่งขวา
          Expanded(
            child: _TactileActionCard(
              isDark: isDark,
              isExpandedVertical: true,
              title: 'วิเคราะห์',
              subtitle: 'สถิติ & กราฟสรุป',
              imageAsset: 'assets/images/action_analytics.png',
              fallbackIcon: Icons.insights_rounded,
              accentColor: const Color.fromARGB(255, 110, 110, 110),
              imageSize: 56,
              titleFontSize: 15,
              subtitleFontSize: 11.5,
              onTap: onAnalytics,
            ),
          ),
          const SizedBox(width: 10),

          // Right Column (บันทึกรายการประจำวัน): 3 items (รับเงิน, จ่ายเงิน, โอนย้าย)
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
                    accentColor: const Color(0xFF10B981),
                    imageSize: 34,
                    titleFontSize: 13,
                    subtitleFontSize: 10,
                    onTap: onAddIncome,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: _TactileActionCard(
                    isDark: isDark,
                    title: 'จ่ายเงิน',
                    subtitle: 'บันทึกรายจ่าย 🐾',
                    imageAsset: 'assets/images/action_expense.png',
                    fallbackIcon: Icons.arrow_upward_rounded,
                    accentColor: const Color(0xFFEF4444),
                    imageSize: 34,
                    titleFontSize: 13,
                    subtitleFontSize: 10,
                    onTap: onAddExpense,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: _TactileActionCard(
                    isDark: isDark,
                    title: 'โอนย้าย',
                    subtitle: 'โอนระหว่างบัญชี 🐾',
                    imageAsset: 'assets/images/action_transfer.png',
                    fallbackIcon: Icons.swap_horiz_rounded,
                    accentColor: const Color(0xFF6366F1),
                    imageSize: 34,
                    titleFontSize: 13,
                    subtitleFontSize: 10,
                    onTap: onTransfer,
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
  final bool isExpandedVertical;
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
    this.isExpandedVertical = false,
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
          border: Border.all(color: borderColor, width: 1.2),
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
            child: widget.isExpandedVertical
                ? Stack(
                    children: [
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color: widget.accentColor.withValues(
                            alpha: widget.isDark ? 0.6 : 0.45,
                          ),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 3D Picture (Hero Focal Point)
                              Container(
                                width: widget.imageSize,
                                height: widget.imageSize,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(13),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.accentColor.withValues(
                                        alpha: widget.isDark ? 0.35 : 0.22,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2.5),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(13),
                                  child: Image.asset(
                                    widget.imageAsset,
                                    cacheWidth: (widget.imageSize * 3).round(),
                                    cacheHeight: (widget.imageSize * 3).round(),
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Container(
                                      decoration: BoxDecoration(
                                        color: widget.accentColor.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(13),
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
                              const SizedBox(height: 8),

                              // Title & Subtitle
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
                                textAlign: TextAlign.center,
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
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
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
                              cacheWidth: (widget.imageSize * 3).round(),
                              cacheHeight: (widget.imageSize * 3).round(),
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Container(
                                decoration: BoxDecoration(
                                  color: widget.accentColor.withValues(
                                    alpha: 0.15,
                                  ),
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
