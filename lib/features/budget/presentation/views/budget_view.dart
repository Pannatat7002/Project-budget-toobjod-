import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        title: const Text('วางแผนงบประมาณ'),
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
                  // Overall Budget Summary Hero Card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF161F36), const Color(0xFF0F1728)]
                            : [const Color(0xFF4F46E5), const Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: isDark ? const Color(0xFF283553) : Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? Colors.black : AppColors.primary).withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
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
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${(progress * 100).toInt()}% ใช้ไปแล้ว',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          CurrencyFormatter.format(totalLimit),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 18),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress > 1.0
                                  ? AppColors.expense
                                  : (progress >= 0.8 ? AppColors.warning : AppColors.income),
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
                              amount: CurrencyFormatter.format(totalRemaining),
                              color: totalRemaining > 0 ? AppColors.incomeLight : AppColors.expenseLight,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'งบประมาณตามหมวดหมู่',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              letterSpacing: -0.3,
                            ),
                      ),
                      TextButton.icon(
                        onPressed: () => SetBudgetDialog.show(context),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('เพิ่มงบ'),
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
                      message: 'วางแผนและคุมค่าใช้จ่ายล่วงหน้าเพื่อไม่ให้ใช้เงินเกินตัว!',
                      actionText: 'ตั้งงบประมาณแรก',
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
                          onEdit: () => SetBudgetDialog.show(context, existingBudget: b),
                          onDelete: () {
                            context.read<BudgetCubit>().deleteBudget(b.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('ลบงบประมาณ "${b.categoryName}" แล้ว'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        );
                      },
                    ),
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
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          amount,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
