import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../auto_sync/presentation/state/auto_sync_cubit.dart';
import '../../../auto_sync/presentation/widgets/auto_sync_banner.dart';
import '../../../budget/presentation/state/budget_cubit.dart';
import '../../../budget/presentation/state/budget_state.dart';
import '../../../spending_plan/presentation/state/spending_plan_cubit.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/presentation/state/transaction_cubit.dart';
import '../../../transactions/presentation/state/transaction_state.dart';
import '../../../transactions/presentation/views/add_transaction_sheet.dart';
import '../../../transactions/presentation/widgets/transaction_tile.dart';
import '../widgets/quick_actions_bar.dart';
import '../widgets/toob_jod_hero_card.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Mascot Avatar Logo
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFDB813), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFDB813).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/mascot_dog_peek.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.pets, color: Color(0xFFFDB813), size: 20),
                ),
              ),
            ),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'เจ้าตูบจด',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: AppColors.yellowBadgeGradient,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF78350F)),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'วางแผนคุมงบการเงิน 🐾',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (val) {
              if (val == 'auto_sync') {
                context.push('/auto-sync-settings');
              } else if (val == 'reset') {
                _showResetConfirmDialog(context);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'auto_sync',
                child: Row(
                  children: [
                    Icon(Icons.bolt, color: AppColors.primary, size: 18),
                    SizedBox(width: 10),
                    Text('ตั้งค่าตรวจจับธนาคาร', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: AppColors.expense, size: 18),
                    SizedBox(width: 10),
                    Text('ล้างข้อมูลทั้งหมด', style: TextStyle(color: AppColors.expense, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: BlocConsumer<TransactionCubit, TransactionState>(
        listener: (context, txState) {
          context.read<BudgetCubit>().updateWithTransactions(txState.transactions);
        },
        builder: (context, txState) {
          if (txState.status == TransactionStatus.loading && txState.transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final recentTransactions = txState.transactions.take(5).toList();

          return RefreshIndicator(
            onRefresh: () async {
              final txCubit = context.read<TransactionCubit>();
              final budgetCubit = context.read<BudgetCubit>();
              final autoSyncCubit = context.read<AutoSyncCubit>();
              await txCubit.loadTransactions();
              await budgetCubit.loadBudgets();
              await autoSyncCubit.syncNativeBuffer();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  // Auto-Sync Detected Transaction / Setup Banner
                  const AutoSyncBanner(),

                  // 1. MeowJod-Style Yellow Hero Summary Card with Big Overhanging Mascot Dog (PNG)
                  ToobJodHeroCard(
                    totalExpense: txState.totalExpense,
                    totalIncome: txState.totalIncome,
                    totalBalance: txState.totalBalance,
                    onViewSummary: () => context.go('/spending-plan'),
                  ),
                  const SizedBox(height: 16),

                  // 2. Mascot Speech Bubble Banner
                  _buildMascotGreetingCard(context, txState.transactions.length, isDark),
                  const SizedBox(height: 16),

                  // 3. Quick Actions Bar
                  QuickActionsBar(
                    onAddIncome: () => AddTransactionSheet.show(context, initialType: TransactionType.income),
                    onAddExpense: () => AddTransactionSheet.show(context, initialType: TransactionType.expense),
                    onSetBudget: () => context.go('/spending-plan'),
                  ),
                  const SizedBox(height: 18),

                  // 4. Budget Health Preview Widget
                  _buildBudgetHealthPreview(context, isDark),
                  const SizedBox(height: 20),

                  // 5. Recent Transactions Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'รายการล่าสุด',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              letterSpacing: -0.3,
                            ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/transactions'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: AppColors.primary,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('ดูทั้งหมด', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios, size: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 6. Recent Transactions List
                  if (recentTransactions.isEmpty)
                    EmptyStateWidget(
                      imageAsset: 'assets/images/mascot_dog_writing.png',
                      title: 'ยังไม่มีรายการเลยนะโฮ่ง!',
                      message: 'เริ่มจดบันทึกรายรับหรือรายจ่าย ให้เจ้าตูบช่วยคำนวณงบให้นะครับ',
                      actionText: 'จดรายการแรก',
                      onAction: () => AddTransactionSheet.show(context),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recentTransactions.length,
                      itemBuilder: (context, index) {
                        final item = recentTransactions[index];
                        return TransactionTile(
                          transaction: item,
                          onTap: () => AddTransactionSheet.show(context, existingTransaction: item),
                          onDelete: () {
                            context.read<TransactionCubit>().deleteTransaction(item.id);
                          },
                        );
                      },
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMascotGreetingCard(BuildContext context, int txCount, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131E3A) : const Color(0xFFFFEDD5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF22355E) : const Color(0xFFFED7AA),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Mascot Mini Image (PNG)
          SizedBox(
            width: 46,
            height: 46,
            child: Image.asset(
              'assets/images/mascot_dog_writing.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.pets, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),

          // Speech Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txCount > 0
                      ? 'วันนี้ตูบจดให้ $txCount รายการแล้วนะโฮ่ง!'
                      : 'วันนี้มีค่าใช้จ่ายอะไรไหม ให้ตูบช่วยจดนะ!',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: isDark ? Colors.white : const Color(0xFF9A3412),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'คุมงบตามแผน ช่วยให้มีเงินเก็บ 🐾',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextMuted : const Color(0xFFC2410C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetHealthPreview(BuildContext context, bool isDark) {
    return BlocBuilder<BudgetCubit, BudgetState>(
      builder: (context, budgetState) {
        final totalLimit = budgetState.totalBudgetLimit;
        final totalSpent = budgetState.totalBudgetSpent;
        final progress = budgetState.totalProgressPercentage;

        if (totalLimit == 0) {
          return const SizedBox.shrink();
        }

        final percentage = (progress * 100).toInt();
        Color statusColor = AppColors.income;
        if (progress > 1.0) {
          statusColor = AppColors.expense;
        } else if (progress >= 0.8) {
          statusColor = AppColors.warning;
        }

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle,
              width: 1,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/action_budget.png',
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'สถานะงบประมาณรวม',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ใช้ไป ${CurrencyFormatter.format(totalSpent)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  Text(
                    'จากงบ ${CurrencyFormatter.format(totalLimit)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showResetConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ล้างข้อมูลทั้งหมด?'),
        content: const Text(
          'การดำเนินการนี้จะลบรายการและแผนงบประมาณทั้งหมดและเริ่มต้นใหม่ ไม่สามารถกู้คืนได้',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              final txCubit = context.read<TransactionCubit>();
              final budgetCubit = context.read<BudgetCubit>();
              final planCubit = context.read<SpendingPlanCubit>();
              final autoSyncCubit = context.read<AutoSyncCubit>();
              final nav = Navigator.of(ctx);

              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              await autoSyncCubit.clearAllPending();
              await txCubit.loadTransactions();
              await budgetCubit.loadBudgets();
              await planCubit.loadPlan();
              await autoSyncCubit.initialize();
              nav.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            child: const Text('ล้างข้อมูล'),
          ),
        ],
      ),
    );
  }
}
