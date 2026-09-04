import '../../../../core/usecases/usecase.dart';
import '../entities/budget_entity.dart';
import '../repositories/budget_repository.dart';

class SetBudgetUseCase implements UseCase<void, BudgetEntity> {
  final BudgetRepository repository;

  SetBudgetUseCase(this.repository);

  @override
  Future<void> call(BudgetEntity budget) async {
    return await repository.setBudget(budget);
  }
}
