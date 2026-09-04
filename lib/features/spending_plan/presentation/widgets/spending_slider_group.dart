import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/category_icon_badge.dart';
import '../../domain/entities/spending_plan_group.dart';
import '../../domain/entities/spending_plan_item.dart';

class SpendingSliderGroup extends StatelessWidget {
  final SpendingPlanGroup group;
  final double actualSpent;
  final Function(String itemId, double amount) onAmountChanged;

  const SpendingSliderGroup({
    super.key,
    required this.group,
    required this.actualSpent,
    required this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = group.items.isNotEmpty ? group.items.first : null;
    if (item == null) return const SizedBox.shrink();

    // Find category metadata (icon, color)
    final categoryItem = AppConstants.defaultExpenseCategories.firstWhere(
      (c) => c.id == group.id,
      orElse: () => CategoryItem(
        id: group.id,
        name: group.title,
        iconCode: 0xe54e,
        colorValue: group.colorValue,
      ),
    );

    final planAmount = item.amount;
    final double percentage;
    if (planAmount > 0) {
      percentage = (actualSpent / planAmount) * 100;
    } else if (actualSpent > 0) {
      percentage = 100.0;
    } else {
      percentage = 0.0;
    }

    final isOverBudget = planAmount > 0 && actualSpent > planAmount;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOverBudget
              ? AppColors.expense.withValues(alpha: 0.45)
              : (isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle),
          width: isOverBudget ? 1.5 : 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: (isOverBudget ? AppColors.expense : Colors.black).withValues(alpha: isOverBudget ? 0.06 : 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Icon + Category Name + Percentage Badge
          Row(
            children: [
              CategoryIconBadge(
                icon: categoryItem.icon,
                color: categoryItem.color,
                size: 32,
                iconSize: 16,
                categoryId: categoryItem.id,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  group.title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),

              // Percentage Badge (% ใช้จริงเทียบแผน)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOverBudget
                      ? AppColors.expense.withValues(alpha: 0.15)
                      : (percentage >= 80
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                          : (categoryItem.color.withValues(alpha: 0.15))),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isOverBudget) ...[
                      const Icon(Icons.warning_amber_rounded, size: 12, color: AppColors.expense),
                      const SizedBox(width: 3),
                    ],
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: isOverBudget
                            ? AppColors.expense
                            : (percentage >= 80 ? const Color(0xFFD97706) : categoryItem.color),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 2. Metric Row: ใช้จริง vs แผนใช้จ่าย & ยอดคงเหลือ/เกินงบ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                  ),
                  children: [
                    const TextSpan(text: 'ใช้จริง: '),
                    TextSpan(
                      text: CurrencyFormatter.format(actualSpent, showDecimals: false),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isOverBudget
                            ? AppColors.expense
                            : (isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A)),
                      ),
                    ),
                    const TextSpan(text: ' / แผน: '),
                    TextSpan(
                      text: CurrencyFormatter.format(planAmount, showDecimals: false),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                isOverBudget
                    ? 'เกินแผน ${CurrencyFormatter.format(actualSpent - planAmount, showDecimals: false)}'
                    : 'เหลือ ${CurrencyFormatter.format(planAmount - actualSpent, showDecimals: false)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isOverBudget ? AppColors.expense : AppColors.income,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 3. Combined Slider + Progress Track Row (หลอดความคืบหน้าและ Slider เป็นเนื้อเดียวกัน)
          Row(
            children: [
              // Slider with Custom Integrated Progress Track
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 10,
                    trackShape: _ProgressSliderTrackShape(
                      actualSpent: actualSpent,
                      maxAmount: item.maxAmount,
                      categoryColor: categoryItem.color,
                      overBudgetColor: AppColors.expense,
                      isDark: isDark,
                    ),
                    thumbColor: isDark ? Colors.white : const Color(0xFF0F172A),
                    thumbShape: const _CapsuleSliderThumbShape(
                      thumbWidth: 8,
                      thumbHeight: 22,
                      thumbRadius: 4,
                    ),
                    overlayColor: categoryItem.color.withValues(alpha: 0.12),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  ),
                  child: Slider(
                    value: item.amount.clamp(0.0, item.maxAmount),
                    min: 0.0,
                    max: item.maxAmount,
                    divisions: (item.maxAmount / 50).toInt(),
                    onChanged: (val) {
                      onAmountChanged(item.id, (val / 50).round() * 50.0);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Rounded Amount Pill (แตะเพื่อพิมพ์จำนวนเงิน)
              GestureDetector(
                onTap: () => _showManualInputDialog(context, item, group.title),
                child: Container(
                  width: 88,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    CurrencyFormatter.format(item.amount, showDecimals: false),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showManualInputDialog(BuildContext context, SpendingPlanItem item, String title) {
    final controller = TextEditingController(text: item.amount.toStringAsFixed(0));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        title: Text('ระบุแผนงบประมาณ: $title', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            prefixText: '฿ ',
            hintText: '0',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text.replaceAll(',', '')) ?? 0.0;
              onAmountChanged(item.id, val.clamp(0.0, item.maxAmount > 0 ? item.maxAmount : 100000.0));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }
}

/// Custom Slider Track Shape that integrates Actual Progress and Over-budget Red Fill into the Slider Track
class _ProgressSliderTrackShape extends SliderTrackShape with BaseSliderTrackShape {
  final double actualSpent;
  final double maxAmount;
  final Color categoryColor;
  final Color overBudgetColor;
  final bool isDark;

  const _ProgressSliderTrackShape({
    required this.actualSpent,
    required this.maxAmount,
    required this.categoryColor,
    required this.overBudgetColor,
    required this.isDark,
  });

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 0,
  }) {
    final canvas = context.canvas;
    final trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final trackRadius = Radius.circular(trackRect.height / 2);

    // 1. Draw Full Background Track
    final backgroundPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(trackRect, trackRadius), backgroundPaint);

    final trackWidth = trackRect.width;
    final safeMax = maxAmount > 0 ? maxAmount : 1.0;
    final spentRatio = (actualSpent / safeMax).clamp(0.0, 1.0);
    final spentRight = trackRect.left + (trackWidth * spentRatio);
    final thumbX = thumbCenter.dx;

    // 2. Draw Planned Zone (Subtle tint up to thumb)
    if (thumbX > trackRect.left) {
      final plannedRect = Rect.fromLTRB(trackRect.left, trackRect.top, thumbX, trackRect.bottom);
      final plannedPaint = Paint()
        ..color = categoryColor.withValues(alpha: isDark ? 0.35 : 0.22)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(RRect.fromRectAndRadius(plannedRect, trackRadius), plannedPaint);
    }

    // 3. Draw Actual Spent Progress (Combined directly inside track)
    if (actualSpent > 0) {
      if (spentRight <= thumbX) {
        // Normal spent (within budget plan)
        final spentRect = Rect.fromLTRB(trackRect.left, trackRect.top, spentRight, trackRect.bottom);
        final spentPaint = Paint()
          ..color = categoryColor
          ..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(spentRect, trackRadius), spentPaint);
      } else {
        // Spent exceeds budget plan:
        // Portion up to thumb is category color
        if (thumbX > trackRect.left) {
          final withinPlanRect = Rect.fromLTRB(trackRect.left, trackRect.top, thumbX, trackRect.bottom);
          final withinPlanPaint = Paint()
            ..color = categoryColor
            ..style = PaintingStyle.fill;
          canvas.drawRRect(RRect.fromRectAndRadius(withinPlanRect, trackRadius), withinPlanPaint);
        }

        // Portion beyond thumb is ALERT RED (หลอดสีแดงส่วนที่เกินแผน)
        final excessRect = Rect.fromLTRB(thumbX, trackRect.top, spentRight, trackRect.bottom);
        final excessPaint = Paint()
          ..color = overBudgetColor
          ..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(excessRect, trackRadius), excessPaint);
      }
    }
  }
}

/// Custom Capsule Slider Thumb Handle
class _CapsuleSliderThumbShape extends SliderComponentShape {
  final double thumbWidth;
  final double thumbHeight;
  final double thumbRadius;

  const _CapsuleSliderThumbShape({
    this.thumbWidth = 8,
    this.thumbHeight = 22,
    this.thumbRadius = 4,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size(thumbWidth, thumbHeight);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    // Outer subtle shadow/glow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final shadowRect = Rect.fromCenter(center: center.translate(0, 1), width: thumbWidth, height: thumbHeight);
    canvas.drawRRect(RRect.fromRectAndRadius(shadowRect, Radius.circular(thumbRadius)), shadowPaint);

    // Thumb Body
    final paint = Paint()
      ..color = sliderTheme.thumbColor ?? const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    final rect = Rect.fromCenter(center: center, width: thumbWidth, height: thumbHeight);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(thumbRadius));
    canvas.drawRRect(rrect, paint);

    // Center Grip Line Indicator
    final gripPaint = Paint()
      ..color = (sliderTheme.thumbColor == Colors.white ? Colors.black38 : Colors.white70)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx, center.dy - (thumbHeight * 0.25)),
      Offset(center.dx, center.dy + (thumbHeight * 0.25)),
      gripPaint,
    );
  }
}
