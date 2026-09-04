import 'package:flutter_test/flutter_test.dart';
import 'package:budget_planner/core/usecases/usecase.dart';
import 'package:budget_planner/features/transactions/domain/entities/transaction_entity.dart';
import 'package:budget_planner/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:budget_planner/features/transactions/domain/usecases/get_transactions.dart';

class MockTransactionRepository implements TransactionRepository {
  List<TransactionEntity> transactions = [];

  @override
  Future<List<TransactionEntity>> getTransactions() async {
    return transactions;
  }

  @override
  Future<void> addTransaction(TransactionEntity transaction) async {
    transactions.add(transaction);
  }

  @override
  Future<void> updateTransaction(TransactionEntity transaction) async {
    final index = transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) transactions[index] = transaction;
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    transactions.removeWhere((t) => t.id == transactionId);
  }
}

void main() {
  late GetTransactionsUseCase useCase;
  late MockTransactionRepository repository;

  setUp(() {
    repository = MockTransactionRepository();
    useCase = GetTransactionsUseCase(repository);
  });

  test('should return list of transactions from repository', () async {
    final testTransaction = TransactionEntity(
      id: 'tx-test',
      title: 'ค่ากาแฟ',
      amount: 65.0,
      type: TransactionType.expense,
      categoryId: 'food',
      categoryName: 'อาหาร & เครื่องดื่ม',
      categoryIconCode: 0xe532,
      categoryColorValue: 0xFFEF4444,
      date: DateTime(2026, 8, 31),
    );

    repository.transactions = [testTransaction];

    final result = await useCase(const NoParams());

    expect(result, equals([testTransaction]));
    expect(result.first.isExpense, isTrue);
    expect(result.first.amount, equals(65.0));
  });
}
