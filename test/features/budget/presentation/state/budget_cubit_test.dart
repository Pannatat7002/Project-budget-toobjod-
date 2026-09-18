import 'package:flutter_test/flutter_test.dart';
import 'package:budget_planner/features/budget/domain/entities/budget_entity.dart';
import 'package:budget_planner/features/budget/domain/repositories/budget_repository.dart';
import 'package:budget_planner/features/budget/domain/usecases/delete_budget.dart';
import 'package:budget_planner/features/budget/domain/usecases/get_budgets.dart';
import 'package:budget_planner/features/budget/domain/usecases/set_budget.dart';
import 'package:budget_planner/features/budget/presentation/state/budget_cubit.dart';
import 'package:budget_planner/features/budget/presentation/state/budget_state.dart';
import 'package:budget_planner/features/transactions/domain/entities/transaction_entity.dart';

class FakeBudgetRepository implements BudgetRepository {
  final List<BudgetEntity> _budgets = [];

  @override
  Future<List<BudgetEntity>> getBudgets() async => List.unmodifiable(_budgets);

  @override
  Future<void> setBudget(BudgetEntity budget) async {
    final idx = _budgets.indexWhere((b) => b.categoryId == budget.categoryId);
    if (idx != -1) {
      _budgets[idx] = budget;
    } else {
      _budgets.add(budget);
    }
  }

  @override
  Future<void> deleteBudget(String budgetId) async {
    _budgets.removeWhere((b) => b.id == budgetId);
  }
}

void main() {
  group('BudgetCubit Tests', () {
    late FakeBudgetRepository fakeRepo;
    late BudgetCubit cubit;

    setUp(() {
      fakeRepo = FakeBudgetRepository();
      cubit = BudgetCubit(
        getBudgetsUseCase: GetBudgetsUseCase(fakeRepo),
        setBudgetUseCase: SetBudgetUseCase(fakeRepo),
        deleteBudgetUseCase: DeleteBudgetUseCase(fakeRepo),
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state has initial status and empty budgets', () {
      expect(cubit.state.status, BudgetStatus.initial);
      expect(cubit.state.budgets, isEmpty);
      expect(cubit.state.totalBudgetLimit, 0.0);
      expect(cubit.state.totalBudgetSpent, 0.0);
    });

    test('loadBudgets and setBudget work as expected', () async {
      final b1 = const BudgetEntity(
        id: 'b-1',
        categoryId: 'food',
        categoryName: 'อาหาร',
        categoryIconCode: 0xe040,
        categoryColorValue: 0xFFF59E0B,
        limitAmount: 5000.0,
      );

      await cubit.setBudget(b1);

      expect(cubit.state.status, BudgetStatus.success);
      expect(cubit.state.budgets.length, 1);
      expect(cubit.state.totalBudgetLimit, 5000.0);
    });

    test('updateWithTransactions calculates spent amounts for current month only', () async {
      final b1 = const BudgetEntity(
        id: 'b-1',
        categoryId: 'food',
        categoryName: 'อาหาร',
        categoryIconCode: 0xe040,
        categoryColorValue: 0xFFF59E0B,
        limitAmount: 6000.0,
      );
      await cubit.setBudget(b1);

      final now = DateTime.now();
      final currentMonthTx = TransactionEntity(
        id: 'tx-1',
        title: 'มื้อเที่ยง',
        amount: 350.0,
        type: TransactionType.expense,
        categoryId: 'food',
        categoryName: 'อาหาร',
        categoryIconCode: 0xe040,
        categoryColorValue: 0xFFF59E0B,
        date: now,
      );

      final prevMonthTx = TransactionEntity(
        id: 'tx-old',
        title: 'มื้อเดือนที่แล้ว',
        amount: 1000.0,
        type: TransactionType.expense,
        categoryId: 'food',
        categoryName: 'อาหาร',
        categoryIconCode: 0xe040,
        categoryColorValue: 0xFFF59E0B,
        date: DateTime(now.year, now.month == 1 ? 12 : now.month - 1, 15),
      );

      final incomeTx = TransactionEntity(
        id: 'tx-inc',
        title: 'เงินเข้า',
        amount: 5000.0,
        type: TransactionType.income,
        categoryId: 'food',
        categoryName: 'อาหาร',
        categoryIconCode: 0xe040,
        categoryColorValue: 0xFF10B981,
        date: now,
      );

      cubit.updateWithTransactions([currentMonthTx, prevMonthTx, incomeTx]);

      expect(cubit.state.totalBudgetSpent, 350.0);
      expect(cubit.state.totalBudgetRemaining, 6000.0 - 350.0);
      expect(cubit.state.budgets.first.spentAmount, 350.0);
    });

    test('deleteBudget removes budget correctly', () async {
      final b1 = const BudgetEntity(
        id: 'b-1',
        categoryId: 'transport',
        categoryName: 'เดินทาง',
        categoryIconCode: 0xe040,
        categoryColorValue: 0xFF3B82F6,
        limitAmount: 2000.0,
      );
      await cubit.setBudget(b1);
      expect(cubit.state.budgets.length, 1);

      await cubit.deleteBudget('b-1');
      expect(cubit.state.budgets, isEmpty);
      expect(cubit.state.totalBudgetLimit, 0.0);
    });
  });
}
