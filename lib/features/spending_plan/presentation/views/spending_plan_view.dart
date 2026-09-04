import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../transactions/presentation/state/transaction_cubit.dart';
import '../../../transactions/presentation/state/transaction_state.dart';
import '../state/spending_plan_cubit.dart';
import '../state/spending_plan_state.dart';
import '../widgets/segmented_expense_bar.dart';
import '../widgets/spending_slider_group.dart';
import '../widgets/spending_summary_header.dart';

class SpendingPlanView extends StatelessWidget {
  const SpendingPlanView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ปรับแผนการใช้จ่าย'),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
      ),
      body: BlocBuilder<SpendingPlanCubit, SpendingPlanState>(
        builder: (context, state) {
          if (state.status == SpendingPlanStatus.loading && state.plan == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final plan = state.plan;
          if (plan == null) {
            return const Center(child: Text('ไม่พบข้อมูลแผนการใช้จ่าย'));
          }

          return BlocBuilder<TransactionCubit, TransactionState>(
            builder: (context, txState) {
              // Calculate actual monthly expense per category from transactions
              final now = DateTime.now();
              final monthlyExpenses = txState.transactions.where((t) =>
                  !t.isIncome && t.date.year == now.year && t.date.month == now.month);

              final Map<String, double> categorySpentMap = {};
              for (final tx in monthlyExpenses) {
                categorySpentMap[tx.categoryId] = (categorySpentMap[tx.categoryId] ?? 0.0) + tx.amount;
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    context.read<SpendingPlanCubit>().loadPlan(),
                    context.read<TransactionCubit>().loadTransactions(),
                  ]);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Top Summary Header Card (Income, Total Planned Budget, Expected Savings & Ratio)
                      SpendingSummaryHeader(
                        monthlyIncome: plan.monthlyIncome,
                        totalExpenses: plan.totalExpenses,
                        remainingSavings: plan.remainingSavings,
                        savingsRatioPercentage: plan.savingsRatioPercentage,
                        onEditIncome: () => _showIncomeEditDialog(context, plan.monthlyIncome),
                      ),
                      const SizedBox(height: 16),

                      // 2. Segmented Multi-Color Progress Bar & Group Breakdown
                      SegmentedExpenseBar(
                        groups: plan.groups,
                        totalExpenses: plan.totalExpenses,
                      ),
                      const SizedBox(height: 22),

                      // 3. Section Title: ปรับแผนการใช้จ่าย
                      Text(
                        'ปรับแผนการใช้จ่ายรายหมวดหมู่',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              letterSpacing: -0.3,
                            ),
                      ),
                      const SizedBox(height: 12),

                      // 4. Direct Continuous Slider Category Groups (with Actual Spent & % comparison)
                      ...plan.groups.map((group) {
                        final actualSpent = categorySpentMap[group.id] ?? 0.0;

                        return SpendingSliderGroup(
                          group: group,
                          actualSpent: actualSpent,
                          onAmountChanged: (itemId, amount) {
                            context.read<SpendingPlanCubit>().updateItemAmount(group.id, itemId, amount);
                          },
                        );
                      }),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showIncomeEditDialog(BuildContext context, double currentIncome) {
    final controller = TextEditingController(text: currentIncome > 0 ? currentIncome.toStringAsFixed(0) : '');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        title: const Text('ระบุรายรับต่อเดือน', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            prefixText: '฿ ',
            hintText: 'เช่น 25000',
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
              context.read<SpendingPlanCubit>().updateMonthlyIncome(val.clamp(0.0, 10000000.0));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }
}
