import 'package:flutter_test/flutter_test.dart';
import 'package:budget_planner/features/transactions/domain/entities/transaction_entity.dart';
import 'package:budget_planner/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:budget_planner/features/transactions/domain/usecases/add_transaction.dart';
import 'package:budget_planner/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:budget_planner/features/transactions/domain/usecases/get_transactions.dart';
import 'package:budget_planner/features/transactions/domain/usecases/update_transaction.dart';
import 'package:budget_planner/features/transactions/presentation/state/transaction_cubit.dart';
import 'package:budget_planner/features/transactions/presentation/state/transaction_state.dart';

class FakeTransactionRepository implements TransactionRepository {
  final List<TransactionEntity> _items = [];

  @override
  Future<List<TransactionEntity>> getTransactions() async => List.unmodifiable(_items);

  @override
  Future<void> addTransaction(TransactionEntity transaction) async {
    _items.add(transaction);
  }

  @override
  Future<void> updateTransaction(TransactionEntity transaction) async {
    final idx = _items.indexWhere((t) => t.id == transaction.id);
    if (idx != -1) _items[idx] = transaction;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _items.removeWhere((t) => t.id == id);
  }
}

void main() {
  group('TransactionCubit Tests', () {
    late FakeTransactionRepository fakeRepo;
    late TransactionCubit cubit;

    setUp(() {
      fakeRepo = FakeTransactionRepository();
      cubit = TransactionCubit(
        getTransactionsUseCase: GetTransactionsUseCase(fakeRepo),
        addTransactionUseCase: AddTransactionUseCase(fakeRepo),
        deleteTransactionUseCase: DeleteTransactionUseCase(fakeRepo),
        updateTransactionUseCase: UpdateTransactionUseCase(fakeRepo),
      );
    });

    tearDown(() {
      cubit.close();
    });

    final testIncome = TransactionEntity(
      id: 'tx-1',
      title: 'เงินเดือน',
      amount: 25000.0,
      type: TransactionType.income,
      categoryId: 'salary',
      categoryName: 'เงินเดือน',
      categoryIconCode: 0xe040,
      categoryColorValue: 0xFF10B981,
      date: DateTime.now(),
    );

    final testExpense = TransactionEntity(
      id: 'tx-2',
      title: 'อาหารกลางวัน',
      amount: 150.0,
      type: TransactionType.expense,
      categoryId: 'food',
      categoryName: 'อาหาร',
      categoryIconCode: 0xe532,
      categoryColorValue: 0xFFEF4444,
      date: DateTime.now(),
    );

    test('initial state is empty', () {
      expect(cubit.state.status, equals(TransactionStatus.initial));
      expect(cubit.state.transactions, isEmpty);
      expect(cubit.state.totalBalance, equals(0.0));
    });

    test('addTransaction adds item and computes balance correctly', () async {
      await cubit.addTransaction(testIncome);
      await cubit.addTransaction(testExpense);

      expect(cubit.state.transactions.length, equals(2));
      expect(cubit.state.totalIncome, equals(25000.0));
      expect(cubit.state.totalExpense, equals(150.0));
      expect(cubit.state.totalBalance, equals(24850.0));
    });

    test('filter by income / expense works correctly', () async {
      await cubit.addTransaction(testIncome);
      await cubit.addTransaction(testExpense);

      cubit.setFilterType(TransactionFilterType.income);
      expect(cubit.state.filteredTransactions.length, equals(1));
      expect(cubit.state.filteredTransactions.first.isIncome, isTrue);

      cubit.setFilterType(TransactionFilterType.expense);
      expect(cubit.state.filteredTransactions.length, equals(1));
      expect(cubit.state.filteredTransactions.first.isExpense, isTrue);
    });

    test('deleteTransaction removes item and recalculates balance', () async {
      await cubit.addTransaction(testIncome);
      await cubit.addTransaction(testExpense);
      await cubit.deleteTransaction('tx-2');

      expect(cubit.state.transactions.length, equals(1));
      expect(cubit.state.totalExpense, equals(0.0));
      expect(cubit.state.totalBalance, equals(25000.0));
    });
  });
}
