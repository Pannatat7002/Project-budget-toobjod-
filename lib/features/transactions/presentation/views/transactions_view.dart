import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../accounts/presentation/state/account_cubit.dart';
import '../../../accounts/presentation/state/account_state.dart';
import '../../../accounts/presentation/widgets/bank_quick_jump_bar.dart';
import '../../domain/entities/transaction_entity.dart';
import '../state/transaction_cubit.dart';
import '../state/transaction_state.dart';
import '../widgets/transaction_filter_bar.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_sheet.dart';

class TransactionsView extends StatefulWidget {
  const TransactionsView({super.key});

  @override
  State<TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<TransactionsView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AccountCubit, AccountState>(
      builder: (context, accState) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('รายการทั้งหมด'),
            actions: [
              IconButton(
                icon: Icon(
                  accState.isEyeViewHidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                tooltip: accState.isEyeViewHidden ? 'แสดงยอดเงินและรายรับ' : 'ซ่อนยอดเงินและรายรับ',
                onPressed: () => context.read<AccountCubit>().toggleEyeView(),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: BlocBuilder<TransactionCubit, TransactionState>(
            builder: (context, state) {
              if (state.status == TransactionStatus.loading && state.transactions.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final transactions = state.filteredTransactions;
              final groupedTransactions = _groupTransactionsByDate(transactions);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 6),
                    // Modern Clean Search Bar
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder,
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
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => context.read<TransactionCubit>().setSearchQuery(val),
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'ค้นหารายการ, หมวดหมู่ หรือโน้ต...',
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.darkTextMuted),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 16, color: AppColors.darkTextMuted),
                                  onPressed: () {
                                    _searchController.clear();
                                    context.read<TransactionCubit>().setSearchQuery('');
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Bank Filter Bar (Pills)
                    BankQuickJumpBar(
                      accounts: accState.accounts,
                      selectedBankId: state.selectedBankId,
                      onSelectBank: (bankId) {
                        context.read<TransactionCubit>().setSelectedBankId(bankId);
                        context.read<AccountCubit>().selectBank(bankId);
                      },
                    ),
                    const SizedBox(height: 10),

                    // Filter Bar (All / Income / Expense)
                    TransactionFilterBar(
                      currentFilter: state.filterType,
                      onFilterChanged: (filter) => context.read<TransactionCubit>().setFilterType(filter),
                    ),
                    const SizedBox(height: 14),

                    // Grouped List of Transactions
                    Expanded(
                      child: transactions.isEmpty
                          ? EmptyStateWidget(
                              imageAsset: 'assets/images/mascot_celebrate.jpg',
                              title: 'ยังไม่พบรายการนะโฮ่ง!',
                              message: state.searchQuery.isNotEmpty
                                  ? 'ลองเปลี่ยนคำค้นหา หรือเคลียร์ตัวกรองดูนะครับ'
                                  : 'คุณยังไม่มีรายการในช่วงนี้ แตะปุ่มด้านล่างเพื่อบันทึกรายการแรกได้เลย!',
                              actionText: 'จดรายการใหม่',
                              onAction: () => AddTransactionSheet.show(context),
                            )
                          : RefreshIndicator(
                              onRefresh: () => context.read<TransactionCubit>().loadTransactions(),
                              child: ListView.builder(
                                itemCount: groupedTransactions.length,
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemBuilder: (context, groupIndex) {
                                  final group = groupedTransactions[groupIndex];
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Date Header with day total
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4, right: 4, top: 12, bottom: 6),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              group.dateTitle,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                            Text(
                                              (group.dailyNet >= 0 && accState.isEyeViewHidden)
                                                  ? '+฿ •••••'
                                                  : (group.dailyNet >= 0
                                                      ? '+${CurrencyFormatter.format(group.dailyNet)}'
                                                      : '-${CurrencyFormatter.format(group.dailyNet.abs())}'),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: group.dailyNet >= 0 ? AppColors.income : AppColors.expense,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Items under this date
                                      ...group.items.map((item) {
                                        return TransactionTile(
                                          transaction: item,
                                          isEyeViewHidden: accState.isEyeViewHidden,
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
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => AddTransactionSheet.show(context),
            child: const Icon(Icons.add, size: 26),
          ),
        );
      },
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
