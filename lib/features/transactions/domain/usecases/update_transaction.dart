import '../../../../core/usecases/usecase.dart';
import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

class UpdateTransactionUseCase implements UseCase<void, TransactionEntity> {
  final TransactionRepository repository;

  UpdateTransactionUseCase(this.repository);

  @override
  Future<void> call(TransactionEntity transaction) async {
    return await repository.updateTransaction(transaction);
  }
}
