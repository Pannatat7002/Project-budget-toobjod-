import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../state/budget_cubit.dart';
import '../state/budget_state.dart';
import '../widgets/budget_progress_card.dart';
import 'set_budget_dialog.dart';

class BudgetView extends StatelessWidget {
  const BudgetView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'วางแผนงบประมาณ',
          style: GoogleFonts.prompt(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            onPressed: () => SetBudgetDialog.show(context),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: AppColors.primary, size: 18),
            ),
            tooltip: 'ตั้งงบประมาณใหม่',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<BudgetCubit, BudgetState>(
        // Rebuild only when budgets or status changes
        buildWhen: (prev, curr) =>
            prev.status != curr.status || prev.budgets != curr.budgets,
        builder: (context, state) {
          if (state.status == BudgetStatus.loading && state.budgets.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final budgets = state.budgets;
          final totalLimit = state.totalBudgetLimit;
          final totalSpent = state.totalBudgetSpent;
          final totalRemaining = state.totalBudgetRemaining;
          final progress = state.totalProgressPercentage;

          return RefreshIndicator(
            onRefresh: () => context.read<BudgetCubit>().loadBudgets(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overall Budget Summary Hero Card with Mascot
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    const Color(0xFF1E293B),
                                    const Color(0xFF0F172A),
                                  ]
                                : [
                                    const Color(0xFFFF7A00),
                                    const Color(0xFFEA580C),
                                    const Color(0xFFC2410C),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? const Color(
                                    0xFFEA580C,
                                  ).withValues(alpha: 0.35)
                                : Colors.white.withValues(alpha: 0.25),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.3)
                                  : const Color(
                                      0xFFEA580C,
                                    ).withValues(alpha: 0.25),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'งบประมาณรวมประจำเดือน',
                                  style: GoogleFonts.prompt(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.25,
                                      ),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    '${(progress * 100).toInt()}% ใช้ไปแล้ว',
                                    style: GoogleFonts.prompt(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              CurrencyFormatter.format(totalLimit),
                              style: GoogleFonts.prompt(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.22,
                                ),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progress > 1.0
                                      ? const Color(0xFFEF4444)
                                      : (progress >= 0.8
                                            ? const Color(0xFFFBBF24)
                                            : Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSummaryItem(
                                  label: 'ใช้ไปแล้ว',
                                  amount: CurrencyFormatter.format(totalSpent),
                                  color: Colors.white,
                                ),
                                _buildSummaryItem(
                                  label: 'เหลืองบประมาณ',
                                  amount: CurrencyFormatter.format(
                                    totalRemaining,
                                  ),
                                  color: totalRemaining > 0
                                      ? const Color(0xFF6EE7B7)
                                      : const Color(0xFFFCA5A5),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 14,
                        top: -12,
                        child: IgnorePointer(
                          child: SizedBox(
                            width: 60,
                            height: 60,
                            child: Image.asset(
                              'assets/images/mascot_dog_peek.png',
                              cacheWidth: 120,
                              cacheHeight: 120,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'งบประมาณตามหมวดหมู่',
                        style: GoogleFonts.prompt(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          letterSpacing: -0.3,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => SetBudgetDialog.show(context),
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(
                          'เพิ่มงบ',
                          style: GoogleFonts.prompt(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Budget items list or empty state
                  if (budgets.isEmpty)
                    EmptyStateWidget(
                      icon: Icons.pie_chart_outline,
                      title: 'ยังไม่ได้ตั้งงบประมาณ',
                      // message: 'วางแผนและคุมค่าใช้จ่ายล่วงหน้าเพื่อไม่ให้ใช้เงินเกินตัว!',
                      // actionText: 'ตั้งงบประมาณแรก',
                      onAction: () => SetBudgetDialog.show(context),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: budgets.length,
                      itemBuilder: (context, index) {
                        final b = budgets[index];
                        return BudgetProgressCard(
                          budget: b,
                          onEdit: () =>
                              SetBudgetDialog.show(context, existingBudget: b),
                          onDelete: () {
                            context.read<BudgetCubit>().deleteBudget(b.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'ลบงบประมาณ "${b.categoryName}" แล้ว',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String amount,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.prompt(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          amount,
          style: GoogleFonts.prompt(
            color: color,
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
