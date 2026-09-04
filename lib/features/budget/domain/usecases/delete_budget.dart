import '../../../../core/usecases/usecase.dart';
import '../repositories/budget_repository.dart';

class DeleteBudgetUseCase implements UseCase<void, String> {
  final BudgetRepository repository;

  DeleteBudgetUseCase(this.repository);

  @override
  Future<void> call(String budgetId) async {
    return await repository.deleteBudget(budgetId);
  }
}
