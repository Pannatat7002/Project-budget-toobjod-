import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/transaction_entity.dart';
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

  TransactionCubit({
    required this.getTransactionsUseCase,
    required this.addTransactionUseCase,
    required this.deleteTransactionUseCase,
    required this.updateTransactionUseCase,
  }) : super(TransactionState());

  Future<void> loadTransactions() async {
    emit(state.copyWith(status: TransactionStatus.loading));
    try {
      final transactions = await getTransactionsUseCase(const NoParams());
      emit(state.copyWith(
        status: TransactionStatus.success,
        transactions: transactions,
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
}
