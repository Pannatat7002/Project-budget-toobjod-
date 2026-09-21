import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/dog_sound_helper.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../features/settings/presentation/state/theme_cubit.dart';
import '../../../accounts/presentation/state/account_cubit.dart';
import '../../../accounts/presentation/state/account_state.dart';
import '../../../accounts/presentation/widgets/bank_cards_carousel.dart';
import '../../../auto_sync/presentation/state/auto_sync_cubit.dart';
import '../../../auto_sync/presentation/widgets/auto_sync_banner.dart';
import '../../../auto_sync/presentation/widgets/notification_bell_button.dart';
import '../../../budget/presentation/state/budget_cubit.dart';
import '../../../budget/presentation/state/budget_state.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/presentation/state/transaction_cubit.dart';
import '../../../transactions/presentation/state/transaction_state.dart';
import '../../../transactions/presentation/views/add_transaction_sheet.dart';
import '../../../transactions/presentation/widgets/delete_transaction_dialog.dart';
import '../../../transactions/presentation/widgets/transaction_tile.dart';
import '../widgets/dashboard_actions_grid.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  String _dogName = AppConstants.appName;
  @override
  void initState() {
    super.initState();
    _loadDogName();
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

  String _getDynamicDogGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'อรุณสวัสดิ์โฮ่ง! เช้าแล้ววางแผนเงินกัน 🐾';
    } else if (hour >= 12 && hour < 17) {
      return 'มื้อเที่ยงกินอะไรดี อย่าลืมให้ตูบจดนะ 🍖';
    } else if (hour >= 17 && hour < 21) {
      return 'ตกเย็นแล้ว วันนี้ใช้เงินไปกี่บาทโฮ่ง? 🐾';
    } else {
      return 'ดึกแล้ว ตูบช่วยเฝ้ากระเป๋าเงินให้นะ ฝันดีโฮ่ง 🌙';
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
                // Mascot Avatar Logo (Spacious & Clean - แตะเพื่อส่งเสียงเห่า)
                GestureDetector(
                  onTap: () {
                    DogSoundHelper.playBark();
                  },
                  child: Container(
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
                        cacheWidth: 126,
                        cacheHeight: 126,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.pets,
                          color: Color(0xFFFDB813),
                          size: 20,
                        ),
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
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getDynamicDogGreeting(),
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
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (val) {
              if (val == 'rename_dog') {
                _showRenameDogDialog(context);
              } else if (val == 'security_settings') {
                context.push('/security-settings');
              } else if (val == 'auto_sync') {
                context.push('/auto-sync-settings');
              } else if (val == 'reset') {
                _showResetConfirmDialog(context);
              } else if (val == 'theme_light') {
                context.read<ThemeCubit>().setTheme(ThemeMode.light);
              } else if (val == 'theme_dark') {
                context.read<ThemeCubit>().setTheme(ThemeMode.dark);
              } else if (val == 'theme_system') {
                context.read<ThemeCubit>().setTheme(ThemeMode.system);
              }
            },
            itemBuilder: (ctx) {
              final currentMode = ctx.read<ThemeCubit>().state;
              return [
                const PopupMenuItem(
                  value: 'security_settings',
                  child: Row(
                    children: [
                      Icon(
                        Icons.shield_rounded,
                        color: AppColors.primaryOrange,
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'ความปลอดภัย & รหัส PIN',
                        style: TextStyle(fontSize: 13),
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
                // ─── Theme 3-Way Toggle ───────────────────────────
                const PopupMenuDivider(),
                PopupMenuItem(
                  enabled: false,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: _ThemeModeSegmentedToggle(
                    currentMode: currentMode,
                    onThemeChanged: (mode) {
                      ctx.read<ThemeCubit>().setTheme(mode);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
                // ─── Danger zone ──────────────────────────────────
                const PopupMenuDivider(),
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
                        style: TextStyle(
                          color: AppColors.expense,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ];
            },
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
          return BlocBuilder<TransactionCubit, TransactionState>(
            buildWhen: (previous, current) =>
                previous.transactions != current.transactions ||
                previous.status != current.status,
            builder: (context, txState) {
              if (txState.status == TransactionStatus.loading &&
                  txState.transactions.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final selectedBankId = accountState.selectedBankId;
              final bankTransactions = selectedBankId == null
                  ? txState.transactions
                  : txState.getTransactionsForBank(selectedBankId);
              final recentTransactions = bankTransactions.take(6).toList();
              final hasMoreTransactions =
                  bankTransactions.length > recentTransactions.length;
              final remainingTransactionsCount =
                  bankTransactions.length - recentTransactions.length;

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

                      // 2. Unified Dashboard Actions Grid (ซ้าย: วิเคราะห์ขยายเต็ม / ขวา: รับเงิน, จ่ายเงิน, โอนย้าย)
                      DashboardActionsGrid(
                        onAddIncome: () => _handleTransactionAction(
                          context,
                          accountState,
                          TransactionType.income,
                        ),
                        onAddExpense: () => _handleTransactionAction(
                          context,
                          accountState,
                          TransactionType.expense,
                        ),
                        onTransfer: () => _handleTransactionAction(
                          context,
                          accountState,
                          TransactionType.transfer,
                        ),
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
                        ],
                      ),
                      const SizedBox(height: 8),

                      // 7. Recent Transactions List (Grouped Apple Wallet Style)
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
                                  onAction: () {
                                    if (accountState.accounts.isEmpty) {
                                      _showNoBankWarningDialog(context);
                                    } else {
                                      AddTransactionSheet.show(context);
                                    }
                                  },
                                )
                              : Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.darkSurface
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: isDark
                                              ? AppColors.darkBorderSubtle
                                              : const Color(0xFFE2E8F0),
                                          width: 0.9,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: isDark ? 0.12 : 0.025,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          for (
                                            int i = 0;
                                            i < recentTransactions.length;
                                            i++
                                          )
                                            TransactionTile(
                                              transaction:
                                                  recentTransactions[i],
                                              isGrouped: true,
                                              showDivider:
                                                  i <
                                                  recentTransactions.length - 1,
                                              onTap: () =>
                                                  AddTransactionSheet.show(
                                                    context,
                                                    existingTransaction:
                                                        recentTransactions[i],
                                                  ),
                                              confirmDelete: () =>
                                                  DeleteTransactionDialog.show(
                                                    context,
                                                    recentTransactions[i],
                                                  ),
                                              onDelete: () {
                                                final item =
                                                    recentTransactions[i];
                                                context
                                                    .read<TransactionCubit>()
                                                    .deleteTransaction(item.id);
                                              },
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    _buildViewAllTransactionsButton(
                                      context,
                                      hasMore: hasMoreTransactions,
                                      remainingCount:
                                          remainingTransactionsCount,
                                      selectedBankId: selectedBankId,
                                      isDark: isDark,
                                    ),
                                  ],
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

  Widget _buildViewAllTransactionsButton(
    BuildContext context, {
    required bool hasMore,
    required int remainingCount,
    required String? selectedBankId,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.read<TransactionCubit>().setSelectedBankId(selectedBankId);
          context.go('/transactions');
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.28),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  hasMore
                      ? 'ดูรายการทั้งหมด (ยังมีอีก $remainingCount รายการ)'
                      : 'ดูรายการทั้งหมด',
                  style: GoogleFonts.prompt(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
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
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/budgets'),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
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
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.15 : 0.03,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDB813).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      padding: const EdgeInsets.all(7),
                      child: Image.asset(
                        'assets/images/action_budget.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.pie_chart_rounded,
                          color: Color(0xFFD97706),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ตั้งงบประมาณ',
                            style: GoogleFonts.prompt(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 1.5),
                          Text(
                            'วางแผนคุมงบประมาณรายหมวด 🐾',
                            style: GoogleFonts.prompt(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ],
                ),
              ),
            ),
          );
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
                              cacheWidth: 60,
                              cacheHeight: 60,
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
                  const SizedBox(height: 7),
                  GestureDetector(
                    onTap: () {
                      if (progress >= 0.8) {
                        DogSoundHelper.playAlertBark();
                      } else {
                        DogSoundHelper.playBark();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: isDark ? 0.15 : 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              progress > 1.0
                                  ? '🛑 หงิง... เดือนนี้ใช้เกินงบแล้ว พักก่อนนะเจ้านาย'
                                  : (progress >= 0.8
                                      ? '⚠️ โฮ่ง! งบใกล้หมดแล้วนะ ตูบเริ่มเฝ้าระวัง'
                                      : '🐾 เงินเหลือสบายใจ ตูบยกสองเท้าหน้าให้เลยโฮ่ง! ✨'),
                              style: GoogleFonts.prompt(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                              cacheWidth: 120,
                              cacheHeight: 120,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/images/mascot_dog_peek.png',
                                cacheWidth: 120,
                                cacheHeight: 120,
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
                            ? const Color(0xFF334155).withValues(alpha: 0.45)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
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
              final autoSyncCubit = context.read<AutoSyncCubit>();
              final accCubit = context.read<AccountCubit>();
              final nav = Navigator.of(ctx);

              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              await autoSyncCubit.clearAllPending();
              await txCubit.loadTransactions();
              await budgetCubit.loadBudgets();
              await accCubit.loadAccounts();
              accCubit.selectBank(null);
              await autoSyncCubit.initialize();

              if (mounted) {
                setState(() {
                  _dogName = AppConstants.appName;
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

  void _handleTransactionAction(
    BuildContext context,
    AccountState accountState,
    TransactionType type,
  ) {
    if (accountState.accounts.isEmpty) {
      _showNoBankWarningDialog(context);
      return;
    }

    AddTransactionSheet.show(
      context,
      initialType: type,
      initialBankId: accountState.selectedBankId,
    );
  }

  void _showNoBankWarningDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        icon: Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFDB813).withValues(alpha: 0.15),
              border: Border.all(
                color: const Color(0xFFFDB813),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/mascot_dog_peek.png',
                cacheWidth: 160,
                cacheHeight: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.pets,
                  color: Color(0xFFFDB813),
                  size: 32,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'ยังไม่มีบัญชีธนาคาร',
          textAlign: TextAlign.center,
          style: GoogleFonts.prompt(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'กรุณาเพิ่มหรือเชื่อมต่อบัญชีธนาคาร\nอย่างน้อย 1 บัญชี เพื่อเริ่มต้นทำรายการ 🐾',
              textAlign: TextAlign.center,
              style: GoogleFonts.prompt(
                fontSize: 13.5,
                color: textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/bank-selection');
                  },
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(
                    'เพิ่มบัญชีธนาคาร & เชื่อมต่อ',
                    style: GoogleFonts.prompt(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'ปิด / ไว้ทีหลัง',
                    style: GoogleFonts.prompt(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeModeSegmentedToggle extends StatelessWidget {
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  const _ThemeModeSegmentedToggle({
    required this.currentMode,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerBg =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

    final items = [
      (ThemeMode.light, Icons.light_mode_rounded, 'สว่าง'),
      (ThemeMode.dark, Icons.dark_mode_rounded, 'มืด'),
      (ThemeMode.system, Icons.brightness_auto_rounded, 'ระบบ'),
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: items.map((item) {
          final mode = item.$1;
          final icon = item.$2;
          final label = item.$3;
          final isSelected = currentMode == mode;

          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onThemeChanged(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? const Color(0xFF334155) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.25 : 0.08,
                            ),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 14,
                      color: isSelected
                          ? AppColors.primaryOrange
                          : (isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: GoogleFonts.prompt(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? (isDark ? Colors.white : const Color(0xFF0F172A))
                            : (isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

