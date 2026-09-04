import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../domain/entities/budget_entity.dart';
import '../../domain/usecases/delete_budget.dart';
import '../../domain/usecases/get_budgets.dart';
import '../../domain/usecases/set_budget.dart';
import 'budget_state.dart';

class BudgetCubit extends Cubit<BudgetState> {
  final GetBudgetsUseCase getBudgetsUseCase;
  final SetBudgetUseCase setBudgetUseCase;
  final DeleteBudgetUseCase deleteBudgetUseCase;

  List<TransactionEntity> _latestTransactions = [];

  BudgetCubit({
    required this.getBudgetsUseCase,
    required this.setBudgetUseCase,
    required this.deleteBudgetUseCase,
  }) : super(const BudgetState());

  Future<void> loadBudgets() async {
    emit(state.copyWith(status: BudgetStatus.loading));
    try {
      final budgets = await getBudgetsUseCase(const NoParams());
      final calculatedBudgets = _calculateSpentAmounts(budgets, _latestTransactions);
      emit(state.copyWith(
        status: BudgetStatus.success,
        budgets: calculatedBudgets,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: BudgetStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void updateWithTransactions(List<TransactionEntity> transactions) {
    _latestTransactions = transactions;
    if (state.budgets.isNotEmpty) {
      final recalculated = _calculateSpentAmounts(state.budgets, transactions);
      emit(state.copyWith(budgets: recalculated));
    }
  }

  List<BudgetEntity> _calculateSpentAmounts(
    List<BudgetEntity> budgets,
    List<TransactionEntity> transactions,
  ) {
    final now = DateTime.now();
    // Filter expense transactions for current month
    final currentMonthExpenses = transactions.where((t) {
      return t.isExpense && t.date.year == now.year && t.date.month == now.month;
    }).toList();

    return budgets.map((b) {
      final spent = currentMonthExpenses
          .where((t) => t.categoryId == b.categoryId)
          .fold(0.0, (sum, t) => sum + t.amount);
      return b.copyWith(spentAmount: spent);
    }).toList();
  }

  Future<void> setBudget(BudgetEntity budget) async {
    try {
      await setBudgetUseCase(budget);
      await loadBudgets();
    } catch (e) {
      emit(state.copyWith(
        status: BudgetStatus.failure,
        errorMessage: 'ไม่สามารถบันทึกงบประมาณได้: $e',
      ));
    }
  }

  Future<void> deleteBudget(String budgetId) async {
    try {
      await deleteBudgetUseCase(budgetId);
      await loadBudgets();
    } catch (e) {
      emit(state.copyWith(
        status: BudgetStatus.failure,
        errorMessage: 'ไม่สามารถลบงบประมาณได้: $e',
      ));
    }
  }
}
