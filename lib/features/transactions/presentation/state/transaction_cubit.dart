import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/recurring_transaction_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/services/recurring_scheduler_service.dart';
import '../../domain/usecases/add_transaction.dart';
import '../../domain/usecases/delete_transaction.dart';
import '../../domain/usecases/get_transactions.dart';
import '../../domain/usecases/update_transaction.dart';
import 'transaction_state.dart';

class TransactionCubit extends Cubit<TransactionState> {
  final GetTransactionsUseCase getTransactionsUseCase;
  final AddTransactionUseCase addTransactionUseCase;
  final DeleteTransactionUseCase deleteTransactionUseCase;
  final UpdateTransactionUseCase updateTransactionUseCase;
  final RecurringSchedulerService? schedulerService;

  TransactionCubit({
    required this.getTransactionsUseCase,
    required this.addTransactionUseCase,
    required this.deleteTransactionUseCase,
    required this.updateTransactionUseCase,
    this.schedulerService,
  }) : super(const TransactionState());

  Future<void> loadTransactions() async {
    if (state.transactions.isEmpty) {
      emit(state.copyWith(status: TransactionStatus.loading));
    }
    try {
      final transactions = await getTransactionsUseCase(const NoParams());

      // Check and process recurring transactions if schedulerService is provided
      List<RecurringTransactionEntity> rules = state.recurringRules;
      int newAutoPosted = 0;
      if (schedulerService != null) {
        rules = schedulerService!.loadRules();
        final result = schedulerService!.processDueRules(rules);
        if (result.hasAutoPosted) {
          for (final tx in result.autoPostedTransactions) {
            await addTransactionUseCase(tx);
          }
          await schedulerService!.saveRules(result.updatedRules);
          rules = result.updatedRules;
          newAutoPosted = result.autoPostedTransactions.length;
          final refreshed = await getTransactionsUseCase(const NoParams());
          emit(state.copyWith(
            status: TransactionStatus.success,
            transactions: refreshed,
            recurringRules: rules,
            newlyAutoPostedCount: newAutoPosted,
          ));
          return;
        }
      }

      emit(state.copyWith(
        status: TransactionStatus.success,
        transactions: transactions,
        recurringRules: rules,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TransactionStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> addTransaction(TransactionEntity transaction) async {
    try {
      await addTransactionUseCase(transaction);
      // Optimistic: add locally first for zero-flicker UI
      final optimistic = List<TransactionEntity>.from(state.transactions)
        ..insert(0, transaction);
      emit(state.copyWith(
        status: TransactionStatus.success,
        transactions: optimistic,
      ));
      // Then reload from source of truth
      await loadTransactions();
    } catch (e) {
      emit(state.copyWith(
        status: TransactionStatus.failure,
        errorMessage: 'ไม่สามารถบันทึกรายการได้: $e',
      ));
    }
  }

  Future<void> updateTransaction(TransactionEntity transaction) async {
    try {
      await updateTransactionUseCase(transaction);
      await loadTransactions();
    } catch (e) {
      emit(state.copyWith(
        status: TransactionStatus.failure,
        errorMessage: 'ไม่สามารถแก้ไขรายการได้: $e',
      ));
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    try {
      // Optimistic: remove locally first for zero-flicker UI
      final optimistic = state.transactions
          .where((t) => t.id != transactionId)
          .toList();
      emit(state.copyWith(
        status: TransactionStatus.success,
        transactions: optimistic,
      ));
      await deleteTransactionUseCase(transactionId);
      await loadTransactions();
    } catch (e) {
      emit(state.copyWith(
        status: TransactionStatus.failure,
        errorMessage: 'ไม่สามารถลบรายการได้: $e',
      ));
    }
  }

  void setFilterType(TransactionFilterType filterType) {
    emit(state.copyWith(filterType: filterType));
  }

  void setSelectedCategory(String? categoryId) {
    if (categoryId == null) {
      emit(state.copyWith(clearCategory: true));
    } else {
      emit(state.copyWith(selectedCategoryId: categoryId));
    }
  }

  void setSelectedBankId(String? bankId) {
    if (bankId == null) {
      emit(state.copyWith(clearBank: true));
    } else {
      emit(state.copyWith(selectedBankId: bankId));
    }
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  Future<void> saveRecurringRule(RecurringTransactionEntity rule) async {
    if (schedulerService == null) return;
    final rules = List<RecurringTransactionEntity>.from(state.recurringRules);
    final index = rules.indexWhere((r) => r.id == rule.id);
    if (index >= 0) {
      rules[index] = rule;
    } else {
      rules.add(rule);
    }
    await schedulerService!.saveRules(rules);
    emit(state.copyWith(recurringRules: rules));
    await checkAndProcessRecurring();
  }

  Future<void> deleteRecurringRule(String ruleId) async {
    if (schedulerService == null) return;
    final rules = state.recurringRules.where((r) => r.id != ruleId).toList();
    await schedulerService!.saveRules(rules);
    emit(state.copyWith(recurringRules: rules));
  }

  Future<void> toggleRecurringRule(String ruleId) async {
    if (schedulerService == null) return;
    final rules = state.recurringRules.map((r) {
      if (r.id == ruleId) {
        return r.copyWith(isActive: !r.isActive);
      }
      return r;
    }).toList();
    await schedulerService!.saveRules(rules);
    emit(state.copyWith(recurringRules: rules));
  }

  Future<void> triggerRecurringRuleNow(RecurringTransactionEntity rule) async {
    final now = DateTime.now();
    final autoNote = rule.note != null && rule.note!.isNotEmpty
        ? '${rule.note} (บันทึกทันใจ 🐾)'
        : 'รายการประจำ (บันทึกทันใจ 🐾)';

    final tx = TransactionEntity(
      id: const Uuid().v4(),
      title: rule.title,
      amount: rule.amount,
      type: rule.type,
      categoryId: rule.categoryId,
      categoryName: rule.categoryName,
      categoryIconCode: rule.categoryIconCode,
      categoryColorValue: rule.categoryColorValue,
      date: now,
      note: autoNote,
      bankId: rule.bankId,
      bankAccountId: rule.bankAccountId,
      bankShortName: rule.bankShortName,
      accountMask: rule.accountMask,
      targetAccountId: rule.targetAccountId,
      tags: {...rule.tags, '#รายการประจำ'}.toList(),
    );

    await addTransaction(tx);
    final updatedRule = rule.copyWith(lastExecutedDate: now);
    await saveRecurringRule(updatedRule);
  }

  Future<void> checkAndProcessRecurring() async {
    if (schedulerService == null) return;
    final rules = schedulerService!.loadRules();
    final result = schedulerService!.processDueRules(rules);
    if (result.hasAutoPosted) {
      for (final tx in result.autoPostedTransactions) {
        await addTransactionUseCase(tx);
      }
      await schedulerService!.saveRules(result.updatedRules);
      await loadTransactions();
    }
  }

  void clearNewlyAutoPostedCount() {
    emit(state.copyWith(newlyAutoPostedCount: 0));
  }
}
