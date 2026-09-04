import '../../../../core/usecases/usecase.dart';
import '../repositories/transaction_repository.dart';

class DeleteTransactionUseCase implements UseCase<void, String> {
  final TransactionRepository repository;

  DeleteTransactionUseCase(this.repository);

  @override
  Future<void> call(String transactionId) async {
    return await repository.deleteTransaction(transactionId);
  }
}
