import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../accounts/presentation/state/account_cubit.dart';
import '../../../accounts/presentation/state/account_state.dart';
import '../../../analytics/presentation/widgets/report_export_sheet.dart';
import '../../../analytics/utils/report_generator.dart';
import '../../../auto_sync/domain/entities/bank_profile.dart';
import '../../../auto_sync/presentation/widgets/bank_logo_badge.dart';
import '../../domain/entities/transaction_entity.dart';
import '../state/transaction_cubit.dart';
import '../state/transaction_state.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_sheet.dart';

class TransactionsView extends StatefulWidget {
  const TransactionsView({super.key});

  @override
  State<TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<TransactionsView> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TransactionCubit>().setSearchQuery('');
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openExportSheet(
    BuildContext context,
    List<TransactionEntity> monthTxs,
    DateTime month,
  ) {
    if (monthTxs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ไม่มีรายการของเดือนนี้ให้ส่งออก',
            style: GoogleFonts.prompt(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    final period = PeriodRange(
      type: AnalyticsPeriod.custom,
      startDate: start,
      endDate: end,
      label: DateFormatter.formatMonthYear(month),
    );
    final kpis = ReportGenerator.calculateKpis(monthTxs, period);
    final categoryShares = ReportGenerator.calculateCategoryShares(monthTxs);
    ReportExportSheet.show(
      context,
      transactions: monthTxs,
      period: period,
      kpis: kpis,
      categoryShares: categoryShares,
    );
  }

  void _toggleSearch() {
    HapticFeedback.lightImpact();
    setState(() {
      _isSearchOpen = !_isSearchOpen;
      if (_isSearchOpen) {
        _searchFocusNode.requestFocus();
      } else {
        _searchController.clear();
        _searchFocusNode.unfocus();
        context.read<TransactionCubit>().setSearchQuery('');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AccountCubit, AccountState>(
      builder: (context, accountState) {
        return BlocBuilder<TransactionCubit, TransactionState>(
          buildWhen: (prev, curr) =>
              prev.transactions != curr.transactions ||
              prev.status != curr.status ||
              prev.filterType != curr.filterType ||
              prev.selectedCategoryId != curr.selectedCategoryId ||
              prev.selectedBankId != curr.selectedBankId ||
              prev.searchQuery != curr.searchQuery,
          builder: (context, state) {
            if (state.status == TransactionStatus.loading &&
                state.transactions.isEmpty) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Compute distinct available months
            final Map<String, DateTime> monthMap = {};
            for (final tx in state.transactions) {
              final monthKey = '${tx.date.year}-${tx.date.month}';
              final monthDate = DateTime(tx.date.year, tx.date.month);
              monthMap.putIfAbsent(monthKey, () => monthDate);
            }

            final availableMonths = monthMap.values.toList()
              ..sort((a, b) => a.compareTo(b));

            // Ensure the active month is strictly one that has recorded transactions
            final DateTime activeMonth;
            if (availableMonths.isNotEmpty) {
              final isCurrentSelectedValid = availableMonths.any(
                (m) =>
                    m.year == _selectedMonth.year &&
                    m.month == _selectedMonth.month,
              );
              activeMonth = isCurrentSelectedValid
                  ? _selectedMonth
                  : availableMonths.last;
            } else {
              activeMonth = _selectedMonth;
            }

            final currentMonthIdx = availableMonths.isNotEmpty
                ? availableMonths.indexWhere(
                    (m) =>
                        m.year == activeMonth.year &&
                        m.month == activeMonth.month,
                  )
                : -1;
            final canPrev = currentMonthIdx > 0;
            final canNext =
                currentMonthIdx != -1 &&
                currentMonthIdx < availableMonths.length - 1;

            // Filter transactions by the active selected month
            final transactions = state.filteredTransactions.where((item) {
              return item.date.year == activeMonth.year &&
                  item.date.month == activeMonth.month;
            }).toList();
            final groupedTransactions = _groupTransactionsByDate(transactions);

            // Calculate monthly summary for the selected active month
            final monthAllTxs = state.transactions.where((item) {
              return item.date.year == activeMonth.year &&
                  item.date.month == activeMonth.month;
            }).toList();
            final monthIncome = monthAllTxs
                .where((t) => t.isIncome)
                .fold(0.0, (sum, t) => sum + t.amount);
            final monthExpense = monthAllTxs
                .where((t) => !t.isIncome)
                .fold(0.0, (sum, t) => sum + t.amount);
            final monthNet = monthIncome - monthExpense;

            return Scaffold(
              appBar: AppBar(
                elevation: 0,
                title: Text(
                  'รายการทั้งหมด',
                  style: GoogleFonts.prompt(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                actions: [
                  // Search
                  IconButton(
                    icon: const Icon(Icons.search_rounded),
                    tooltip: 'ค้นหา',
                    onPressed: _toggleSearch,
                  ),
                  // Export
                  IconButton(
                    icon: const Icon(Icons.ios_share_rounded),
                    tooltip: 'ส่งออกรายงาน',
                    onPressed: () => _openExportSheet(
                      context,
                      monthAllTxs,
                      activeMonth,
                    ),
                  ),
                ],
              ),
              body: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity == null) return;
                  if (details.primaryVelocity! < -180 && canNext) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedMonth = availableMonths[currentMonthIdx + 1];
                    });
                  } else if (details.primaryVelocity! > 180 && canPrev) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedMonth = availableMonths[currentMonthIdx - 1];
                    });
                  }
                },
                child: RefreshIndicator(
                  onRefresh: () =>
                      context.read<TransactionCubit>().loadTransactions(),
                  child: CustomScrollView(
                    slivers: [
                      // Search bar — pinned just below AppBar when active
                      if (_isSearchOpen)
                        SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.primary.withValues(
                                  alpha: 0.5,
                                ),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: isDark ? 0.15 : 0.08,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.search_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    focusNode: _searchFocusNode,
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      hintText: 'ค้นหาชื่อรายการ, ร้านค้า...',
                                      hintStyle: GoogleFonts.prompt(
                                        fontSize: 13,
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.black38,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        vertical: 7,
                                      ),
                                    ),
                                    style: GoogleFonts.prompt(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                    onChanged: (val) => context
                                        .read<TransactionCubit>()
                                        .setSearchQuery(val),
                                  ),
                                ),
                                if (_searchController.text.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      context
                                          .read<TransactionCubit>()
                                          .setSearchQuery('');
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.cancel,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                TextButton(
                                  onPressed: _toggleSearch,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 4,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'ปิด',
                                    style: GoogleFonts.prompt(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Monthly Financial Overview Card (with month nav + type filter)
                            _buildMinimalSummaryBar(
                              context: context,
                              isDark: isDark,
                              activeMonth: activeMonth,
                              onTapMonth: () => _showMonthPickerSheet(
                                context,
                                availableMonths,
                                activeMonth,
                              ),
                              onPrev: canPrev
                                  ? () => _changeMonth(availableMonths[currentMonthIdx - 1])
                                  : null,
                              onNext: canNext
                                  ? () => _changeMonth(availableMonths[currentMonthIdx + 1])
                                  : null,
                              canPrev: canPrev,
                              canNext: canNext,
                              income: monthIncome,
                              expense: monthExpense,
                              net: monthNet,
                              txCount: monthAllTxs.length,
                              filterType: state.filterType,
                              onFilterType: (t) {
                                HapticFeedback.selectionClick();
                                context.read<TransactionCubit>().setFilterType(t);
                              },
                            ),

                            // 2. Active Filter Chips (Only shown when filters are active!)
                            _buildActiveFiltersRow(
                              context: context,
                              state: state,
                              accState: accountState,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),

                      // 5. Grouped List of Transactions (Immediately visible)
                      if (transactions.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 24.0,
                            ),
                            child: _buildEmptyState(context, state),
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            groupIndex,
                          ) {
                            final group = groupedTransactions[groupIndex];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Day Header with relative date & daily net total
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    right: 16,
                                    top: 14,
                                    bottom: 6,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(3.5),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withValues(
                                                    alpha: isDark ? 0.22 : 0.12,
                                                  ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Icon(
                                              Icons.event_note_rounded,
                                              size: 12,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 7),
                                          Text(
                                            group.dateTitle,
                                            style: GoogleFonts.prompt(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w800,
                                              color: isDark
                                                  ? AppColors.darkTextPrimary
                                                  : const Color(0xFF1E293B),
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: group.dailyNet >= 0
                                              ? AppColors.income.withValues(
                                                  alpha: isDark ? 0.2 : 0.08,
                                                )
                                              : AppColors.expense.withValues(
                                                  alpha: isDark ? 0.2 : 0.08,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: group.dailyNet >= 0
                                                ? AppColors.income.withValues(
                                                    alpha: 0.25,
                                                  )
                                                : AppColors.expense.withValues(
                                                    alpha: 0.25,
                                                  ),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Text(
                                          group.dailyNet >= 0
                                              ? '+${CurrencyFormatter.format(group.dailyNet)}'
                                              : '-${CurrencyFormatter.format(group.dailyNet.abs())}',
                                          style: GoogleFonts.prompt(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: group.dailyNet >= 0
                                                ? AppColors.income
                                                : AppColors.expense,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Edge-to-Edge List (No Border, Flush to screen)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  color: isDark
                                      ? AppColors.darkSurface
                                      : Colors.white,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      for (
                                        int i = 0;
                                        i < group.items.length;
                                        i++
                                      )
                                        TransactionTile(
                                          transaction: group.items[i],
                                          isGrouped: true,
                                          showDivider:
                                              i < group.items.length - 1,
                                          onTap: () => AddTransactionSheet.show(
                                            context,
                                            existingTransaction: group.items[i],
                                          ),
                                          confirmDelete: () =>
                                              _confirmDelete(
                                                context,
                                                group.items[i],
                                              ),
                                          onDelete: () {
                                            context.read<TransactionCubit>().deleteTransaction(group.items[i].id);
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }, childCount: groupedTransactions.length),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ],
                  ),
                ),
              ),

            );
          },
        );
      },
    );
  }

  void _changeMonth(DateTime targetMonth) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedMonth = targetMonth;
    });
  }

  /// Confirmation dialog before deleting a transaction
  Future<bool> _confirmDelete(
    BuildContext context,
    TransactionEntity item,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: Color(0xFFEF4444),
            size: 28,
          ),
        ),
        title: Text(
          'ลบรายการ?',
          textAlign: TextAlign.center,
          style: GoogleFonts.prompt(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        content: Text(
          '"${item.title}"\nรายการนี้จะถูกลบออกถาวร ไม่สามารถกู้คืนได้',
          textAlign: TextAlign.center,
          style: GoogleFonts.prompt(
            fontSize: 13.5,
            color: isDark
                ? const Color(0xFF94A3B8)
                : const Color(0xFF64748B),
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding:
            const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          // Cancel
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                'ยกเลิก',
                style: GoogleFonts.prompt(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Confirm delete
          Expanded(
            child: FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'ลบเลย',
                style: GoogleFonts.prompt(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return confirmed == true;
  }

  /// Compact Monthly Financial Overview Card — includes month stepper + type filter
  Widget _buildMinimalSummaryBar({
    required BuildContext context,
    required bool isDark,
    required DateTime activeMonth,
    required VoidCallback? onTapMonth,
    required VoidCallback? onPrev,
    required VoidCallback? onNext,
    required bool canPrev,
    required bool canNext,
    required double income,
    required double expense,
    required double net,
    required int txCount,
    required TransactionFilterType filterType,
    required ValueChanged<TransactionFilterType> onFilterType,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorderSubtle : const Color(0xFFE2E8F0),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row 1: Month stepper (◀ เดือน ▶) + count badge + สถิติ
          Row(
            children: [
              // ◀ prev
              InkWell(
                onTap: onPrev,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 20,
                    color: canPrev
                        ? (isDark ? Colors.white : const Color(0xFF0F172A))
                        : (isDark ? Colors.white24 : Colors.black26),
                  ),
                ),
              ),
              // Month label (tappable → picker)
              Expanded(
                child: InkWell(
                  onTap: onTapMonth,
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(
                            alpha: isDark ? 0.22 : 0.12,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          size: 13,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormatter.formatMonthYear(activeMonth),
                        style: GoogleFonts.prompt(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 16,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),
              // count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$txCount รายการ',
                  style: GoogleFonts.prompt(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // สถิติ link
              InkWell(
                onTap: () => context.push('/analytics'),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'สถิติ',
                        style: GoogleFonts.prompt(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 13,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
              // ▶ next
              InkWell(
                onTap: onNext,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: canNext
                        ? (isDark ? Colors.white : const Color(0xFF0F172A))
                        : (isDark ? Colors.white24 : Colors.black26),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Row 2: Inflow / Outflow / Net in one clean line
          Row(
            children: [
              // Inflow
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.arrow_downward_rounded,
                      size: 12,
                      color: AppColors.income,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        '+${CurrencyFormatter.format(income)}',
                        style: GoogleFonts.prompt(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.income,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Outflow
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.arrow_upward_rounded,
                      size: 12,
                      color: AppColors.expense,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        '-${CurrencyFormatter.format(expense)}',
                        style: GoogleFonts.prompt(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.expense,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Net
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.savings_rounded,
                      size: 11,
                      color: net >= 0
                          ? const Color(0xFF10B981)
                          : AppColors.expense,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        net >= 0
                            ? '+${CurrencyFormatter.format(net)}'
                            : '-${CurrencyFormatter.format(net.abs())}',
                        style: GoogleFonts.prompt(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: net >= 0
                              ? const Color(0xFF10B981)
                              : AppColors.expense,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 6),

          // Row 3: Type filter tabs [ทั้งหมด | รายรับ | รายจ่าย]
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? AppColors.darkBorderSubtle
                    : const Color(0xFFE2E8F0),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildBottomTypeTab(
                    title: 'ทั้งหมด',
                    isSelected: filterType == TransactionFilterType.all,
                    onTap: () => onFilterType(TransactionFilterType.all),
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _buildBottomTypeTab(
                    title: 'รายรับ',
                    isSelected: filterType == TransactionFilterType.income,
                    activeColor: AppColors.income,
                    onTap: () => onFilterType(TransactionFilterType.income),
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _buildBottomTypeTab(
                    title: 'รายจ่าย',
                    isSelected: filterType == TransactionFilterType.expense,
                    activeColor: AppColors.expense,
                    onTap: () => onFilterType(TransactionFilterType.expense),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// One-Handed Command Dock floating right in the natural thumb zone
  Widget _buildOneHandedBottomDock({
    required BuildContext context,
    required bool isDark,
    required TransactionState state,
    required AccountState accState,
    required DateTime activeMonth,
    required bool canPrev,
    required bool canNext,
    required VoidCallback? onPrev,
    required VoidCallback? onNext,
    required List<DateTime> availableMonths,
    required List<TransactionEntity> monthAllTxs,
  }) {
    int activeFilterCount = 0;
    if (state.filterType != TransactionFilterType.all) activeFilterCount++;
    if (state.selectedBankId != null) activeFilterCount++;
    if (state.selectedCategoryId != null) activeFilterCount++;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B).withValues(alpha: 0.96)
              : Colors.white.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark
                ? AppColors.darkBorderSubtle
                : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _isSearchOpen
            ? Row(
                children: [
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'ค้นหาชื่อรายการ, ร้านค้า...',
                        hintStyle: GoogleFonts.prompt(
                          fontSize: 13,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      style: GoogleFonts.prompt(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      onChanged: (val) {
                        context.read<TransactionCubit>().setSearchQuery(val);
                      },
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        context.read<TransactionCubit>().setSearchQuery('');
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.cancel, size: 18, color: Colors.grey),
                      ),
                    ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: _toggleSearch,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'ปิด',
                      style: GoogleFonts.prompt(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1: Month Stepper + Quick Type Switcher (Thumb Zone 1)
                  Row(
                    children: [
                      // Month Stepper Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorderSubtle
                                : const Color(0xFFE2E8F0),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: onPrev,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(5),
                                child: Icon(
                                  Icons.chevron_left_rounded,
                                  size: 19,
                                  color: canPrev
                                      ? (isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A))
                                      : (isDark
                                            ? Colors.white24
                                            : Colors.black26),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => _showMonthPickerSheet(
                                context,
                                availableMonths,
                                activeMonth,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 3,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      DateFormatter.formatMonthYear(
                                        activeMonth,
                                      ),
                                      style: GoogleFonts.prompt(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(width: 1),
                                    Icon(
                                      Icons.arrow_drop_down_rounded,
                                      size: 15,
                                      color: isDark
                                          ? Colors.white70
                                          : const Color(0xFF64748B),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: onNext,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(5),
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  size: 19,
                                  color: canNext
                                      ? (isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A))
                                      : (isDark
                                            ? Colors.white24
                                            : Colors.black26),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Quick Type Segment: [ทั้งหมด | เข้า | ออก]
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCard
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorderSubtle
                                  : const Color(0xFFE2E8F0),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildBottomTypeTab(
                                  title: 'ทั้งหมด',
                                  isSelected:
                                      state.filterType ==
                                      TransactionFilterType.all,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    context
                                        .read<TransactionCubit>()
                                        .setFilterType(
                                          TransactionFilterType.all,
                                        );
                                  },
                                  isDark: isDark,
                                ),
                              ),
                              Expanded(
                                child: _buildBottomTypeTab(
                                  title: 'เข้า',
                                  isSelected:
                                      state.filterType ==
                                      TransactionFilterType.income,
                                  activeColor: AppColors.income,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    context
                                        .read<TransactionCubit>()
                                        .setFilterType(
                                          TransactionFilterType.income,
                                        );
                                  },
                                  isDark: isDark,
                                ),
                              ),
                              Expanded(
                                child: _buildBottomTypeTab(
                                  title: 'ออก',
                                  isSelected:
                                      state.filterType ==
                                      TransactionFilterType.expense,
                                  activeColor: AppColors.expense,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    context
                                        .read<TransactionCubit>()
                                        .setFilterType(
                                          TransactionFilterType.expense,
                                        );
                                  },
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),

                  // Row 2: Search, Filter Sheet & Add Transaction (Thumb Zone 2)
                  Row(
                    children: [
                      // Search Button
                      Expanded(
                        flex: 5,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _toggleSearch,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 7.5,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkCard
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkBorderSubtle
                                      : const Color(0xFFE2E8F0),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.search_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'ค้นหา',
                                    style: GoogleFonts.prompt(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white70
                                          : const Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Filter Sheet Button (with active filter badge)
                      Expanded(
                        flex: 6,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showAllFiltersSheet(
                              context: context,
                              txState: state,
                              accState: accState,
                              monthTxs: monthAllTxs,
                              activeMonth: activeMonth,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 7.5,
                              ),
                              decoration: BoxDecoration(
                                color: activeFilterCount > 0
                                    ? AppColors.primary.withValues(
                                        alpha: isDark ? 0.25 : 0.12,
                                      )
                                    : (isDark
                                          ? AppColors.darkCard
                                          : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: activeFilterCount > 0
                                      ? AppColors.primary
                                      : (isDark
                                            ? AppColors.darkBorderSubtle
                                            : const Color(0xFFE2E8F0)),
                                  width: activeFilterCount > 0 ? 1.2 : 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.tune_rounded,
                                    size: 15,
                                    color: activeFilterCount > 0
                                        ? AppColors.primary
                                        : (isDark
                                              ? Colors.white70
                                              : const Color(0xFF334155)),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    activeFilterCount > 0
                                        ? 'ตัวกรอง ($activeFilterCount)'
                                        : 'ตัวกรอง',
                                    style: GoogleFonts.prompt(
                                      fontSize: 11.5,
                                      fontWeight: activeFilterCount > 0
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: activeFilterCount > 0
                                          ? AppColors.primary
                                          : (isDark
                                                ? Colors.white70
                                                : const Color(0xFF334155)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Add Transaction Button
                      Expanded(
                        flex: 7,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => AddTransactionSheet.show(
                              context,
                              initialBankId: state.selectedBankId,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 7.5,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add_rounded,
                                    size: 17,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'จดรายการ',
                                    style: GoogleFonts.prompt(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBottomTypeTab({
    required String title,
    required bool isSelected,
    Color? activeColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (activeColor != null
                    ? activeColor.withValues(alpha: isDark ? 0.28 : 0.16)
                    : (isDark ? const Color(0xFF334155) : Colors.white))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected && activeColor == null
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.prompt(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: isSelected
                ? (activeColor ??
                      (isDark ? Colors.white : const Color(0xFF0F172A)))
                : (isDark ? AppColors.darkTextMuted : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  /// Month Picker Modal Sheet (Reachable by thumb)
  void _showMonthPickerSheet(
    BuildContext context,
    List<DateTime> availableMonths,
    DateTime activeMonth,
  ) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 14),
              Text(
                'เลือกเดือนที่ต้องการดู',
                style: GoogleFonts.prompt(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableMonths.map((m) {
                  final isSelected =
                      m.year == activeMonth.year &&
                      m.month == activeMonth.month;
                  return InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _changeMonth(m);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                  ? AppColors.darkCard
                                  : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        DateFormatter.formatMonthYear(m),
                        style: GoogleFonts.prompt(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// Comprehensive Filter & Export Bottom Sheet (Reachable by thumb)
  void _showAllFiltersSheet({
    required BuildContext context,
    required TransactionState txState,
    required AccountState accState,
    required List<TransactionEntity> monthTxs,
    required DateTime activeMonth,
  }) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allCategories = [
      ...AppConstants.defaultExpenseCategories,
      ...AppConstants.defaultIncomeCategories,
    ];

    final hasActiveFilter =
        txState.filterType != TransactionFilterType.all ||
        txState.selectedBankId != null ||
        txState.selectedCategoryId != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.80,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
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
                  const SizedBox(height: 14),

                  // Header with Reset
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.tune_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ตัวกรองและการส่งออก',
                            style: GoogleFonts.prompt(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      if (hasActiveFilter)
                        TextButton.icon(
                          onPressed: () {
                            context.read<TransactionCubit>().setFilterType(
                              TransactionFilterType.all,
                            );
                            context.read<TransactionCubit>().setSelectedBankId(
                              null,
                            );
                            context
                                .read<TransactionCubit>()
                                .setSelectedCategory(null);
                            context.read<AccountCubit>().selectBank(null);
                            Navigator.pop(ctx);
                          },
                          icon: const Icon(
                            Icons.refresh_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            'รีเซ็ตทั้งหมด',
                            style: GoogleFonts.prompt(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: ListView(
                      children: [
                        // Section 1: Transaction Type
                        Text(
                          'ประเภทรายการ',
                          style: GoogleFonts.prompt(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSheetFilterChip(
                                title: 'ทั้งหมด',
                                isSelected:
                                    txState.filterType ==
                                    TransactionFilterType.all,
                                onTap: () {
                                  context
                                      .read<TransactionCubit>()
                                      .setFilterType(TransactionFilterType.all);
                                  Navigator.pop(ctx);
                                },
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildSheetFilterChip(
                                title: '🟢 รายรับ (เข้า)',
                                isSelected:
                                    txState.filterType ==
                                    TransactionFilterType.income,
                                activeColor: AppColors.income,
                                onTap: () {
                                  context
                                      .read<TransactionCubit>()
                                      .setFilterType(
                                        TransactionFilterType.income,
                                      );
                                  Navigator.pop(ctx);
                                },
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildSheetFilterChip(
                                title: '🟠 รายจ่าย (ออก)',
                                isSelected:
                                    txState.filterType ==
                                    TransactionFilterType.expense,
                                activeColor: AppColors.expense,
                                onTap: () {
                                  context
                                      .read<TransactionCubit>()
                                      .setFilterType(
                                        TransactionFilterType.expense,
                                      );
                                  Navigator.pop(ctx);
                                },
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Section 2: Bank Accounts
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'บัญชีธนาคาร',
                              style: GoogleFonts.prompt(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            if (txState.selectedBankId != null)
                              GestureDetector(
                                onTap: () {
                                  context
                                      .read<TransactionCubit>()
                                      .setSelectedBankId(null);
                                  context.read<AccountCubit>().selectBank(null);
                                  Navigator.pop(ctx);
                                },
                                child: Text(
                                  'ล้างบัญชี',
                                  style: GoogleFonts.prompt(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildSheetPill(
                              label: 'ทุกบัญชี',
                              icon: Icons.account_balance_wallet_rounded,
                              isSelected: txState.selectedBankId == null,
                              onTap: () {
                                context
                                    .read<TransactionCubit>()
                                    .setSelectedBankId(null);
                                context.read<AccountCubit>().selectBank(null);
                                Navigator.pop(ctx);
                              },
                              isDark: isDark,
                            ),
                            ...accState.accounts.map((acc) {
                              final isSelected =
                                  txState.selectedBankId == acc.bankId;
                              return _buildSheetPill(
                                label: acc.shortName,
                                leadingWidget: BankLogoBadge(
                                  bankId: acc.bankId,
                                  size: 18,
                                ),
                                isSelected: isSelected,
                                onTap: () {
                                  context
                                      .read<TransactionCubit>()
                                      .setSelectedBankId(acc.bankId);
                                  context.read<AccountCubit>().selectBank(
                                    acc.bankId,
                                  );
                                  Navigator.pop(ctx);
                                },
                                isDark: isDark,
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Section 3: Categories
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'หมวดหมู่',
                              style: GoogleFonts.prompt(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            if (txState.selectedCategoryId != null)
                              GestureDetector(
                                onTap: () {
                                  context
                                      .read<TransactionCubit>()
                                      .setSelectedCategory(null);
                                  Navigator.pop(ctx);
                                },
                                child: Text(
                                  'ล้างหมวดหมู่',
                                  style: GoogleFonts.prompt(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildSheetPill(
                              label: 'ทุกหมวด',
                              icon: Icons.category_rounded,
                              isSelected: txState.selectedCategoryId == null,
                              onTap: () {
                                context
                                    .read<TransactionCubit>()
                                    .setSelectedCategory(null);
                                Navigator.pop(ctx);
                              },
                              isDark: isDark,
                            ),
                            ...allCategories.map((cat) {
                              final isSelected =
                                  txState.selectedCategoryId == cat.id;
                              return _buildSheetPill(
                                label: cat.name,
                                icon: cat.icon,
                                iconColor: cat.color,
                                isSelected: isSelected,
                                onTap: () {
                                  context
                                      .read<TransactionCubit>()
                                      .setSelectedCategory(cat.id);
                                  Navigator.pop(ctx);
                                },
                                isDark: isDark,
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 22),

                        // Section 4: Export report button
                        InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            _openExportSheet(context, monthTxs, activeMonth);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkCard
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorderSubtle
                                    : const Color(0xFFCBD5E1),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.ios_share_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ส่งออกรายงานเดือนนี้',
                                        style: GoogleFonts.prompt(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      Text(
                                        'ดาวน์โหลดไฟล์ Excel / PDF (${DateFormatter.formatMonthYear(activeMonth)})',
                                        style: GoogleFonts.prompt(
                                          fontSize: 11,
                                          color: isDark
                                              ? AppColors.darkTextMuted
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSheetFilterChip({
    required String title,
    required bool isSelected,
    Color? activeColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? (activeColor != null
                    ? activeColor.withValues(alpha: isDark ? 0.28 : 0.15)
                    : AppColors.primary)
              : (isDark ? AppColors.darkCard : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (activeColor ?? AppColors.primary)
                : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.prompt(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? (activeColor ?? Colors.white)
                : (isDark ? Colors.white70 : const Color(0xFF334155)),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetPill({
    required String label,
    IconData? icon,
    Widget? leadingWidget,
    Color? iconColor,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.12)
              : (isDark ? AppColors.darkCard : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark
                      ? AppColors.darkBorderSubtle
                      : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingWidget != null) ...[
              leadingWidget,
              const SizedBox(width: 5),
            ] else if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? AppColors.primary
                    : (iconColor ?? (isDark ? Colors.white60 : Colors.black45)),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.prompt(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? Colors.white : const Color(0xFF1E293B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Contextual Active Filter Chips (Only visible when user has applied filters/search)
  Widget _buildActiveFiltersRow({
    required BuildContext context,
    required TransactionState state,
    required AccountState accState,
    required bool isDark,
  }) {
    final hasSearch = state.searchQuery.isNotEmpty;
    final hasBank = state.selectedBankId != null;
    final hasCategory = state.selectedCategoryId != null;

    if (!hasSearch && !hasBank && !hasCategory) {
      return const SizedBox(height: 4);
    }

    String? bankName;
    if (hasBank) {
      final found = accState.accounts.where(
        (a) => a.bankId == state.selectedBankId,
      );
      bankName = found.isNotEmpty
          ? found.first.shortName
          : (BankProfile.findById(state.selectedBankId!)?.shortName ??
                state.selectedBankId);
    }

    String? catName;
    if (hasCategory) {
      final allCats = [
        ...AppConstants.defaultExpenseCategories,
        ...AppConstants.defaultIncomeCategories,
      ];
      final found = allCats.where((c) => c.id == state.selectedCategoryId);
      if (found.isNotEmpty) {
        catName = found.first.name;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            if (hasSearch) ...[
              _buildActiveChip(
                label: 'ค้นหา: "${state.searchQuery}"',
                icon: Icons.search_rounded,
                onClear: () {
                  _searchController.clear();
                  context.read<TransactionCubit>().setSearchQuery('');
                },
                isDark: isDark,
              ),
              const SizedBox(width: 6),
            ],
            if (bankName != null) ...[
              _buildActiveChip(
                label: 'บัญชี: $bankName',
                icon: Icons.account_balance_wallet_rounded,
                onClear: () {
                  context.read<TransactionCubit>().setSelectedBankId(null);
                  context.read<AccountCubit>().selectBank(null);
                },
                isDark: isDark,
              ),
              const SizedBox(width: 6),
            ],
            if (catName != null) ...[
              _buildActiveChip(
                label: 'หมวด: $catName',
                icon: Icons.category_rounded,
                onClear: () {
                  context.read<TransactionCubit>().setSelectedCategory(null);
                },
                isDark: isDark,
              ),
              const SizedBox(width: 6),
            ],
            GestureDetector(
              onTap: () {
                _searchController.clear();
                context.read<TransactionCubit>().setSearchQuery('');
                context.read<TransactionCubit>().setSelectedBankId(null);
                context.read<TransactionCubit>().setSelectedCategory(null);
                context.read<AccountCubit>().selectBank(null);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4.5,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ล้างทั้งหมด',
                  style: GoogleFonts.prompt(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveChip({
    required String label,
    required IconData icon,
    required VoidCallback onClear,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.prompt(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onClear,
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, TransactionState state) {
    if (state.searchQuery.isNotEmpty) {
      return EmptyStateWidget(
        imageAsset: 'assets/images/mascot_celebrate.jpg',
        title: 'ไม่พบรายการที่ตรงกับการค้นหา',
        onAction: () {
          _searchController.clear();
          context.read<TransactionCubit>().setSearchQuery('');
        },
      );
    }

    if (state.selectedCategoryId != null) {
      return EmptyStateWidget(
        imageAsset: 'assets/images/mascot_celebrate.jpg',
        title: 'ไม่มีรายการในหมวดที่เลือก',
        onAction: () {
          context.read<TransactionCubit>().setSelectedCategory(null);
        },
      );
    }

    if (state.selectedBankId != null) {
      return EmptyStateWidget(
        imageAsset: 'assets/images/mascot_celebrate.jpg',
        title: 'ยังไม่มีรายการของบัญชีนี้',
        onAction: () {
          context.read<TransactionCubit>().setSelectedBankId(null);
          context.read<AccountCubit>().selectBank(null);
        },
      );
    }

    return EmptyStateWidget(
      imageAsset: 'assets/images/mascot_celebrate.jpg',
      title: 'ยังไม่พบรายการนะโฮ่ง!',
      onAction: () => AddTransactionSheet.show(
        context,
        initialBankId: state.selectedBankId,
      ),
    );
  }

  List<_TransactionGroup> _groupTransactionsByDate(
    List<TransactionEntity> list,
  ) {
    final Map<String, List<TransactionEntity>> map = {};

    for (final tx in list) {
      final key = '${tx.date.year}-${tx.date.month}-${tx.date.day}';
      if (!map.containsKey(key)) {
        map[key] = [];
      }
      map[key]!.add(tx);
    }

    return map.entries.map((entry) {
      final items = entry.value;
      final date = items.first.date;
      final dailyNet = items.fold(
        0.0,
        (sum, t) => sum + (t.isIncome ? t.amount : -t.amount),
      );

      return _TransactionGroup(
        dateTitle: DateFormatter.formatRelative(date),
        dailyNet: dailyNet,
        items: items,
      );
    }).toList();
  }
}

class _TransactionGroup {
  final String dateTitle;
  final double dailyNet;
  final List<TransactionEntity> items;

  _TransactionGroup({
    required this.dateTitle,
    required this.dailyNet,
    required this.items,
  });
}
