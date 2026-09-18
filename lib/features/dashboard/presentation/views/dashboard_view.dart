import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../accounts/presentation/state/account_cubit.dart';
import '../../../accounts/presentation/state/account_state.dart';
import '../../../accounts/presentation/widgets/bank_cards_carousel.dart';
import '../../../auto_sync/presentation/state/auto_sync_cubit.dart';
import '../../../auto_sync/presentation/widgets/auto_sync_banner.dart';
import '../../../auto_sync/presentation/widgets/notification_bell_button.dart';
import '../../../budget/presentation/state/budget_cubit.dart';
import '../../../budget/presentation/state/budget_state.dart';
import '../../../spending_plan/presentation/state/spending_plan_cubit.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/presentation/state/transaction_cubit.dart';
import '../../../transactions/presentation/state/transaction_state.dart';
import '../../../transactions/presentation/views/add_transaction_sheet.dart';
import '../../../transactions/presentation/widgets/transaction_tile.dart';
import '../widgets/dashboard_actions_grid.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  String _dogName = AppConstants.appName;
  bool _isMascotGreetingDismissed = false;

  @override
  void initState() {
    super.initState();
    _loadDogName();
    _loadMascotGreetingState();
  }

  Future<void> _loadMascotGreetingState() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool('bp_mascot_greeting_dismissed') ?? false;
    if (dismissed && mounted) {
      setState(() {
        _isMascotGreetingDismissed = true;
      });
    }
  }

  Future<void> _dismissMascotGreeting() async {
    setState(() {
      _isMascotGreetingDismissed = true;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bp_mascot_greeting_dismissed', true);
  }

  Future<void> _toggleMascotGreeting() async {
    final nextState = !_isMascotGreetingDismissed;
    setState(() {
      _isMascotGreetingDismissed = nextState;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bp_mascot_greeting_dismissed', nextState);
  }

  Future<void> _loadDogName() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString(AppConstants.customDogNameKey);
    if (savedName != null && savedName.isNotEmpty) {
      if (mounted) {
        setState(() {
          _dogName = savedName;
        });
      }
    }
  }

  Future<void> _saveDogName(String newName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.customDogNameKey, newName);
    if (mounted) {
      setState(() {
        _dogName = newName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: InkWell(
          onTap: () => _showRenameDogDialog(context),
          borderRadius: BorderRadius.circular(16),
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mascot Avatar Logo (Spacious & Clean)
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFDB813),
                      width: 2.2,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/mascot_dog_peek.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.pets,
                        color: Color(0xFFFDB813),
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                              _dogName,
                              style: GoogleFonts.prompt(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFFDB813,
                              ).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 11,
                              color: Color(0xFFD97706),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.yellowBadgeGradient,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'PRO',
                              style: GoogleFonts.prompt(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF78350F),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'วางแผนคุมงบการเงิน 🐾',
                        style: GoogleFonts.prompt(
                          fontSize: 11.5,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
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
          ),
        ),
        actions: [
          const NotificationBellButton(),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.settings,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (val) {
              if (val == 'rename_dog') {
                _showRenameDogDialog(context);
              } else if (val == 'auto_sync') {
                context.push('/auto-sync-settings');
              } else if (val == 'toggle_mascot_greeting') {
                _toggleMascotGreeting();
              } else if (val == 'reset') {
                _showResetConfirmDialog(context);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'toggle_mascot_greeting',
                child: Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: Color(0xFFFDB813),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isMascotGreetingDismissed
                          ? 'แสดงคำทักทายเจ้าตูบ'
                          : 'ซ่อนคำทักทายเจ้าตูบ',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'auto_sync',
                child: Row(
                  children: [
                    Icon(Icons.bolt, color: AppColors.primary, size: 18),
                    SizedBox(width: 10),
                    Text(
                      'ตั้งค่าตรวจจับธนาคาร',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: AppColors.expense,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'ล้างข้อมูลทั้งหมด',
                      style: TextStyle(color: AppColors.expense, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: BlocBuilder<AccountCubit, AccountState>(
        // Only rebuild when accounts list, selected bank, eye-view or loading state changes
        buildWhen: (prev, curr) =>
            prev.accounts != curr.accounts ||
            prev.selectedBankId != curr.selectedBankId ||
            prev.isEyeViewHidden != curr.isEyeViewHidden ||
            prev.isLoading != curr.isLoading,
        builder: (context, accountState) {
          return BlocConsumer<TransactionCubit, TransactionState>(
            // Only fire listener when the actual transactions list changes
            listenWhen: (previous, current) =>
                !identical(previous.transactions, current.transactions) &&
                previous.transactions != current.transactions,
            listener: (context, txState) {
              context.read<BudgetCubit>().updateWithTransactions(
                txState.transactions,
              );
              context.read<AccountCubit>().refreshBalancesFromTransactions(
                txState.transactions,
              );
            },
            builder: (context, txState) {
              if (txState.status == TransactionStatus.loading &&
                  txState.transactions.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final selectedBankId = accountState.selectedBankId;
              final recentTransactions =
                  (selectedBankId == null
                          ? txState.transactions
                          : txState.getTransactionsForBank(selectedBankId))
                      .take(6)
                      .toList();

              final recentHeaderTitle = selectedBankId == null
                  ? 'รายการล่าสุด (ทุกบัญชี)'
                  : 'รายการล่าสุด (${accountState.selectedAccount?.shortName ?? 'บัญชีที่เลือก'})';

              return RefreshIndicator(
                onRefresh: () async {
                  final txCubit = context.read<TransactionCubit>();
                  final budgetCubit = context.read<BudgetCubit>();
                  final autoSyncCubit = context.read<AutoSyncCubit>();
                  final accCubit = context.read<AccountCubit>();
                  await txCubit.loadTransactions();
                  await budgetCubit.loadBudgets();
                  await accCubit.loadAccounts();
                  await autoSyncCubit.syncNativeBuffer();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),

                      // Auto-Sync Detected Transaction / Setup Banner
                      const AutoSyncBanner(),

                      // Mascot Greeting Pill Banner (Dismissible)
                      if (!_isMascotGreetingDismissed) ...[
                        _buildMascotGreetingCard(
                          context,
                          txState.transactions.length,
                          isDark,
                        ),
                        const SizedBox(height: 8),
                      ],

                      // 1. Multi-Bank Cards Carousel (Swipe Left/Right to Switch Bank)
                      BankCardsCarousel(
                        accounts: accountState.accounts,
                        selectedBankId: accountState.selectedBankId,
                        totalBalance: txState.totalBalance,
                        totalMonthlyIncome: txState.totalIncome,
                        totalMonthlyExpense: txState.totalExpense,
                        getBankBalance: (bankId) =>
                            txState.getBankBalance(bankId),
                        getBankIncome: (bankId) =>
                            txState.getBankIncome(bankId),
                        getBankExpense: (bankId) =>
                            txState.getBankExpense(bankId),
                        isEyeViewHidden: accountState.isEyeViewHidden,
                        onToggleEyeView: () =>
                            context.read<AccountCubit>().toggleEyeView(),
                        onBankSelected: (bankId) =>
                            context.read<AccountCubit>().selectBank(bankId),
                        onAddBankTap: () => context.push('/bank-selection'),
                      ),
                      const SizedBox(height: 10),

                      // 2. Unified Dashboard Actions Grid (ซ้าย: ตั้งงบ, แผนใช้จ่าย, วิเคราะห์ / ขวา: รับเงินเข้า, จ่ายเงินออก)
                      DashboardActionsGrid(
                        onAddIncome: () => AddTransactionSheet.show(
                          context,
                          initialType: TransactionType.income,
                          initialBankId: accountState.selectedBankId,
                        ),
                        onAddExpense: () => AddTransactionSheet.show(
                          context,
                          initialType: TransactionType.expense,
                          initialBankId: accountState.selectedBankId,
                        ),
                        onSetBudget: () => context.push('/budgets'),
                        onSpendingPlan: () => context.push('/spending-plan'),
                        onAnalytics: () => context.push('/analytics'),
                      ),
                      const SizedBox(height: 10),

                      // 6. Budget Health Preview Widget
                      _buildBudgetHealthPreview(context, isDark),
                      const SizedBox(height: 12),

                      // 6. Recent Transactions Header (Dynamic by selected bank)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    recentHeaderTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.prompt(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      letterSpacing: -0.3,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                if (selectedBankId != null) ...[
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => context
                                        .read<AccountCubit>()
                                        .selectBank(null),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.darkCard
                                            : AppColors.lightBackground,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isDark
                                              ? AppColors.darkBorderSubtle
                                              : AppColors.lightBorder,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'ล้าง',
                                            style: GoogleFonts.prompt(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          const Icon(Icons.close, size: 10),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              context
                                  .read<TransactionCubit>()
                                  .setSelectedBankId(selectedBankId);
                              context.go('/transactions');
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'ดูทั้งหมด',
                                    style: GoogleFonts.prompt(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 11,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // 7. Recent Transactions List (Smooth AnimatedSwitcher transition when changing bank)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: KeyedSubtree(
                          key: ValueKey('recent_${selectedBankId ?? 'all'}'),
                          child: recentTransactions.isEmpty
                              ? EmptyStateWidget(
                                  imageAsset:
                                      'assets/images/mascot_dog_writing.png',
                                  title: selectedBankId != null
                                      ? 'ยังไม่มีรายการของบัญชีนี้นะโฮ่ง!'
                                      : 'ยังไม่มีรายการเลยนะโฮ่ง!',
                                  // message: selectedBankId != null
                                  //     ? 'เมื่อมีรายการเข้าหรือจ่ายออกจากธนาคารนี้ จะปรากฏที่นี่ครับ'
                                  //     : 'เริ่มจดบันทึกรายรับหรือรายจ่าย ให้เจ้าตูบช่วยคำนวณงบให้นะครับ',
                                  // actionText: 'จดรายการใหม่',
                                  onAction: () =>
                                      AddTransactionSheet.show(context),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: recentTransactions.length,
                                  itemBuilder: (context, index) {
                                    final item = recentTransactions[index];
                                    return TransactionTile(
                                      transaction: item,
                                      onTap: () => AddTransactionSheet.show(
                                        context,
                                        existingTransaction: item,
                                      ),
                                      onDelete: () {
                                        context
                                            .read<TransactionCubit>()
                                            .deleteTransaction(item.id);
                                      },
                                    );
                                  },
                                ),
                        ),
                      ),
                      const SizedBox(height: 60),
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

  Widget _buildMascotGreetingCard(
    BuildContext context,
    int txCount,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.only(left: 12, top: 6, bottom: 6, right: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131E3A) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF22355E) : const Color(0xFFFED7AA),
          width: 0.9,
        ),
      ),
      child: Row(
        children: [
          // Mascot Mini Avatar
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFFEA580C).withValues(alpha: 0.2)
                  : Colors.white,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/mascot_dog_writing.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.pets, size: 14, color: Color(0xFFEA580C)),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Speech Text
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    txCount > 0
                        ? 'วันนี้ตูบจดให้ $txCount รายการแล้วนะโฮ่ง!'
                        : 'วันนี้มีค่าใช้จ่ายอะไร ให้ตูบช่วยจดนะ!',
                    style: GoogleFonts.prompt(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: isDark ? Colors.white : const Color(0xFF9A3412),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? Colors.white38
                        : const Color(0xFFC2410C).withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  flex: 0,
                  child: Text(
                    'คุมงบมีเงินเก็บ 🐾',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.prompt(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : const Color(0xFFC2410C),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),

          // Dismiss / Close button
          GestureDetector(
            onTap: _dismissMascotGreeting,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 15,
                color: isDark
                    ? AppColors.darkTextMuted
                    : const Color(0xFF9A3412).withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetHealthPreview(BuildContext context, bool isDark) {
    return BlocBuilder<BudgetCubit, BudgetState>(
      // Only rebuild when budget totals or status changes
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.totalBudgetLimit != curr.totalBudgetLimit ||
          prev.totalBudgetSpent != curr.totalBudgetSpent,
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

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/budgets'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorderSubtle
                      : AppColors.lightBorderSubtle,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                    blurRadius: 8,
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
                      Expanded(
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/images/action_budget.png',
                              width: 20,
                              height: 20,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                'สถานะงบประมาณรวม',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.prompt(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$percentage%',
                              style: GoogleFonts.prompt(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: statusColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: isDark
                          ? AppColors.darkBackground
                          : const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      minHeight: 6.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ใช้ไป ${CurrencyFormatter.format(totalSpent)}',
                        style: GoogleFonts.prompt(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      Text(
                        'จากงบ ${CurrencyFormatter.format(totalLimit)}',
                        style: GoogleFonts.prompt(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showRenameDogDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String initialSuffix = _dogName;
    if (initialSuffix.startsWith('เจ้าตูบ')) {
      initialSuffix = initialSuffix.substring('เจ้าตูบ'.length).trim();
    }
    if (initialSuffix.isEmpty) {
      initialSuffix = 'จด';
    }

    final controller = TextEditingController(text: initialSuffix);
    final suggestions = [
      'จด',
      'นำโชค',
      'ถุงทอง',
      'เศรษฐี',
      'มีตังค์',
      'พาเพลิน',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
            final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

            return Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header Row: Dog Avatar + Title + Close Button
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(
                              0xFFFDB813,
                            ).withValues(alpha: 0.15),
                            border: Border.all(
                              color: const Color(
                                0xFFFDB813,
                              ).withValues(alpha: 0.4),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/mascot_dog_writing.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/images/mascot_dog_peek.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ตั้งชื่อคู่หูเจ้าตูบ 🐾',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ชื่อคู่หูจะขึ้นต้นด้วย "เจ้าตูบ" เสมอ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark ? Colors.white54 : Colors.black45,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(bottomSheetCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Text Field with locked "เจ้าตูบ" prefix
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFDB813).withValues(alpha: 0.6),
                          width: 1.4,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFFDB813,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'เจ้าตูบ',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: controller,
                              autofocus: true,
                              maxLength: 12,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'เช่น จด, นำโชค',
                                counterText: '',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Preset suggestion chips
                    Text(
                      'ไอเดียชื่อน่ารัก:',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: suggestions.map((name) {
                        final isSelected = controller.text.trim() == name;
                        return InkWell(
                          onTap: () {
                            controller.text = name;
                            controller.selection = TextSelection.fromPosition(
                              TextPosition(offset: name.length),
                            );
                            setDialogState(() {});
                          },
                          borderRadius: BorderRadius.circular(12),
                          hoverColor: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFDB813)
                                  : (isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFF78350F)
                                    : (isDark
                                          ? Colors.white70
                                          : Colors.black87),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Action: Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          String suffix = controller.text.trim();
                          if (suffix.startsWith('เจ้าตูบ')) {
                            suffix = suffix.substring('เจ้าตูบ'.length).trim();
                          }
                          if (suffix.isEmpty) {
                            suffix = 'จด';
                          }
                          final newFullName = 'เจ้าตูบ$suffix';
                          await _saveDogName(newFullName);
                          if (bottomSheetCtx.mounted) {
                            Navigator.pop(bottomSheetCtx);
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Text('🐶 '),
                                    Expanded(
                                      child: Text(
                                        'เปลี่ยนชื่อคู่หูเป็น "$newFullName" เรียบร้อยแล้ว โฮ่ง!',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFDB813),
                          foregroundColor: const Color(0xFF78350F),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'บันทึกชื่อคู่หู 🐾',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
              final accCubit = context.read<AccountCubit>();
              final nav = Navigator.of(ctx);

              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              await autoSyncCubit.clearAllPending();
              await txCubit.loadTransactions();
              await budgetCubit.loadBudgets();
              await planCubit.loadPlan();
              await accCubit.loadAccounts();
              accCubit.selectBank(null);
              await autoSyncCubit.initialize();

              if (mounted) {
                setState(() {
                  _dogName = AppConstants.appName;
                  _isMascotGreetingDismissed = false;
                });
              }

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
