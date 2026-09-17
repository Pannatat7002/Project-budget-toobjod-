import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../domain/entities/transaction_entity.dart';
import '../state/transaction_cubit.dart';
import '../state/transaction_state.dart';
import '../widgets/transaction_filter_bar.dart';
import '../widgets/month_selector_bar.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_sheet.dart';

class TransactionsView extends StatefulWidget {
  const TransactionsView({super.key});

  @override
  State<TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<TransactionsView> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    // Ensure search query is cleared since search bar is replaced with month selector
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TransactionCubit>().setSearchQuery('');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการทั้งหมด'),
      ),
          body: BlocBuilder<TransactionCubit, TransactionState>(
            // Rebuild only when transactions or filter/status change
            buildWhen: (prev, curr) =>
                prev.transactions != curr.transactions ||
                prev.status != curr.status ||
                prev.filterType != curr.filterType ||
                prev.selectedCategoryId != curr.selectedCategoryId ||
                prev.selectedBankId != curr.selectedBankId ||
                prev.searchQuery != curr.searchQuery,
            builder: (context, state) {
              if (state.status == TransactionStatus.loading && state.transactions.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              // Compute distinct available months and transaction counts from all recorded transactions
              final Map<String, DateTime> monthMap = {};
              final Map<DateTime, int> countMap = {};

              for (final tx in state.transactions) {
                final monthKey = '${tx.date.year}-${tx.date.month}';
                final monthDate = DateTime(tx.date.year, tx.date.month);
                monthMap.putIfAbsent(monthKey, () => monthDate);
                countMap[monthDate] = (countMap[monthDate] ?? 0) + 1;
              }

              final availableMonths = monthMap.values.toList()..sort((a, b) => a.compareTo(b));

              // Ensure the active month is strictly one that has recorded transactions
              final DateTime activeMonth;
              if (availableMonths.isNotEmpty) {
                final isCurrentSelectedValid = availableMonths.any(
                  (m) => m.year == _selectedMonth.year && m.month == _selectedMonth.month,
                );
                activeMonth = isCurrentSelectedValid ? _selectedMonth : availableMonths.last;
              } else {
                activeMonth = _selectedMonth;
              }

              // Filter transactions by the active selected month
              final transactions = state.filteredTransactions.where((item) {
                return item.date.year == activeMonth.year &&
                    item.date.month == activeMonth.month;
              }).toList();
              final groupedTransactions = _groupTransactionsByDate(transactions);

              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity == null) return;
                  final sorted = availableMonths.isNotEmpty
                      ? availableMonths
                      : [DateTime(DateTime.now().year, DateTime.now().month)];
                  final idx = sorted.indexWhere(
                    (m) => m.year == activeMonth.year && m.month == activeMonth.month,
                  );
                  final currentIdx = idx != -1 ? idx : sorted.length - 1;

                  if (details.primaryVelocity! < -180) {
                    // Swiped Left -> Next Month with transactions
                    if (currentIdx < sorted.length - 1) {
                      setState(() {
                        _selectedMonth = sorted[currentIdx + 1];
                      });
                    }
                  } else if (details.primaryVelocity! > 180) {
                    // Swiped Right -> Previous Month with transactions
                    if (currentIdx > 0) {
                      setState(() {
                        _selectedMonth = sorted[currentIdx - 1];
                      });
                    }
                  }
                },
                child: RefreshIndicator(
                  onRefresh: () => context.read<TransactionCubit>().loadTransactions(),
                  child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),

                            // 1. Month Selector Bar (<  เดือน : XXX  >)
                            MonthSelectorBar(
                              selectedMonth: activeMonth,
                              availableMonths: availableMonths,
                              transactionCounts: countMap,
                              onMonthChanged: (newMonth) {
                                setState(() {
                                  _selectedMonth = newMonth;
                                });
                              },
                            ),
                            const SizedBox(height: 10),

                            // 2. Filter Bar (All / Income / Expense)
                            TransactionFilterBar(
                              currentFilter: state.filterType,
                              onFilterChanged: (filter) => context.read<TransactionCubit>().setFilterType(filter),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),

                    // 4. Grouped List of Transactions or Empty State for the Selected Month
                    if (transactions.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                          child: EmptyStateWidget(
                            imageAsset: 'assets/images/mascot_celebrate.jpg',
                            title: 'ยังไม่พบรายการนะโฮ่ง!',
                            message: 'ยังไม่มีรายการใน ${DateFormatter.formatMonthYear(activeMonth)} แตะปุ่มด้านล่างเพื่อบันทึกรายการได้เลย!',
                            actionText: 'จดรายการใหม่',
                            onAction: () => AddTransactionSheet.show(
                              context,
                              initialBankId: state.selectedBankId,
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, groupIndex) {
                              final group = groupedTransactions[groupIndex];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Date Header with day total and ToobJod accent
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4, right: 4, top: 16, bottom: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.12),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Icon(
                                                Icons.event_note_rounded,
                                                size: 13,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              group.dateTitle,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: group.dailyNet >= 0
                                                ? AppColors.income.withValues(alpha: isDark ? 0.2 : 0.08)
                                                : AppColors.expense.withValues(alpha: isDark ? 0.2 : 0.08),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: group.dailyNet >= 0
                                                  ? AppColors.income.withValues(alpha: 0.25)
                                                  : AppColors.expense.withValues(alpha: 0.25),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Text(
                                            group.dailyNet >= 0
                                                ? '+${CurrencyFormatter.format(group.dailyNet)}'
                                                : '-${CurrencyFormatter.format(group.dailyNet.abs())}',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                              color: group.dailyNet >= 0 ? AppColors.income : AppColors.expense,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Items under this date
                                  ...group.items.map((item) {
                                    return TransactionTile(
                                      transaction: item,
                                      onTap: () => AddTransactionSheet.show(context, existingTransaction: item),
                                      onDelete: () {
                                        context.read<TransactionCubit>().deleteTransaction(item.id);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('ลบ "${item.title}" แล้ว'),
                                            behavior: SnackBarBehavior.floating,
                                            action: SnackBarAction(
                                              label: 'เลิกทำ',
                                              onPressed: () {
                                                context.read<TransactionCubit>().addTransaction(item);
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }),
                                ],
                              );
                            },
                            childCount: groupedTransactions.length,
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 80),
                    ),
                  ],
                ),
              ),
            );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => AddTransactionSheet.show(context),
            child: const Icon(Icons.add, size: 26),
          ),
        );
      }

  List<_TransactionGroup> _groupTransactionsByDate(List<TransactionEntity> list) {
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
      final dailyNet = items.fold(0.0, (sum, t) => sum + (t.isIncome ? t.amount : -t.amount));

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
