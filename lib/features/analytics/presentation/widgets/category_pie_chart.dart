import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../utils/report_generator.dart';

class CategoryPieChart extends StatefulWidget {
  final List<TransactionEntity> transactions;
  final List<CategoryShare>? categoryShares;

  const CategoryPieChart({
    super.key,
    required this.transactions,
    this.categoryShares,
  });

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int _touchedIndex = -1;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Use precomputed categoryShares if available, otherwise compute from transactions
    final List<CategoryShare> categories = widget.categoryShares ??
        ReportGenerator.calculateCategoryShares(widget.transactions);

    final double totalExpense = categories.fold(0.0, (sum, c) => sum + c.amount);

    if (categories.isEmpty || totalExpense <= 0) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pie_chart_outline_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'ยังไม่มีรายการรายจ่ายในช่วงเวลานี้',
              style: GoogleFonts.prompt(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'เมื่อมีการบันทึกรายจ่าย กราฟสัดส่วนจะแสดงผลที่นี่',
              style: GoogleFonts.prompt(
                fontSize: 11,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ],
        ),
      );
    }

    // Determine touched item for center display
    final touchedCat = (_touchedIndex >= 0 && _touchedIndex < categories.length)
        ? categories[_touchedIndex]
        : null;

    final displayItems = _isExpanded ? categories : categories.take(4).toList();

    return Column(
      children: [
        // Donut Chart with Dynamic Center Hole
        SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        final newIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        if (_touchedIndex != newIndex) {
                          HapticFeedback.selectionClick();
                        }
                        _touchedIndex = newIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2.5,
                  centerSpaceRadius: 68,
                  sections: List.generate(categories.length, (i) {
                    final isTouched = i == _touchedIndex;
                    final cat = categories[i];
                    final radius = isTouched ? 28.0 : 20.0;
                    final color = Color(cat.colorValue != 0 ? cat.colorValue : 0xFFFF7A00);

                    return PieChartSectionData(
                      color: color,
                      value: cat.amount,
                      showTitle: false,
                      radius: radius,
                      badgeWidget: isTouched
                          ? Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: color, width: 2.5),
                              ),
                            )
                          : null,
                      badgePositionPercentageOffset: 1.15,
                    );
                  }),
                ),
              ),
              // Center Dynamic Summary
              GestureDetector(
                onTap: () {
                  if (_touchedIndex != -1) {
                    setState(() => _touchedIndex = -1);
                  }
                },
                child: Container(
                  width: 130,
                  height: 130,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (touchedCat != null) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: Color(touchedCat.colorValue != 0 ? touchedCat.colorValue : 0xFFFF7A00),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                touchedCat.categoryName,
                                style: GoogleFonts.prompt(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${CurrencyFormatter.format(touchedCat.amount)} บ.',
                          style: GoogleFonts.prompt(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: Color(touchedCat.colorValue != 0 ? touchedCat.colorValue : 0xFFFF7A00),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: (Color(touchedCat.colorValue != 0 ? touchedCat.colorValue : 0xFFFF7A00)).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${touchedCat.percentage.toStringAsFixed(1)}%',
                            style: GoogleFonts.prompt(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(touchedCat.colorValue != 0 ? touchedCat.colorValue : 0xFFFF7A00),
                            ),
                          ),
                        ),
                      ] else ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🐾', style: TextStyle(fontSize: 10)),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                'รายจ่ายรวม',
                                style: GoogleFonts.prompt(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          CurrencyFormatter.format(totalExpense),
                          style: GoogleFonts.prompt(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${categories.length} หมวดหมู่',
                          style: GoogleFonts.prompt(
                            fontSize: 10,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Category Breakdown Ranking List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayItems.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final cat = displayItems[index];
            final isTouched = _touchedIndex == index;
            final color = Color(cat.colorValue != 0 ? cat.colorValue : 0xFFFF7A00);

            return InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _touchedIndex = _touchedIndex == index ? -1 : index;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isTouched
                      ? color.withValues(alpha: isDark ? 0.18 : 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isTouched
                      ? Border.all(color: color.withValues(alpha: 0.4), width: 1)
                      : null,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Rank Badge
                        Container(
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: index < 3
                                ? (index == 0
                                    ? AppColors.primary.withValues(alpha: 0.18)
                                    : (index == 1
                                        ? const Color(0xFF3B82F6).withValues(alpha: 0.18)
                                        : const Color(0xFF10B981).withValues(alpha: 0.18)))
                                : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${index + 1}',
                            style: GoogleFonts.prompt(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: index < 3
                                  ? (index == 0
                                      ? AppColors.primary
                                      : (index == 1
                                          ? const Color(0xFF3B82F6)
                                          : const Color(0xFF10B981)))
                                  : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Color Indicator Dot
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Category Name
                        Expanded(
                          child: Text(
                            cat.categoryName,
                            style: GoogleFonts.prompt(
                              fontSize: 12.5,
                              fontWeight: isTouched ? FontWeight.w700 : FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Percentage Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${cat.percentage.toStringAsFixed(1)}%',
                            style: GoogleFonts.prompt(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Formatted Amount
                        Text(
                          '${CurrencyFormatter.format(cat.amount)} บ.',
                          style: GoogleFonts.prompt(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Proportion Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (cat.percentage / 100).clamp(0.0, 1.0),
                        minHeight: 4.5,
                        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Expand / Collapse Toggle if more than 4 categories
        if (categories.length > 4) ...[
          const SizedBox(height: 10),
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _isExpanded = !_isExpanded);
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isExpanded
                        ? 'ย่อหมวดหมู่ลง'
                        : 'ดูทั้งหมด (${categories.length} หมวดหมู่)',
                    style: GoogleFonts.prompt(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

