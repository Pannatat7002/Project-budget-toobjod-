import '../../../../core/usecases/usecase.dart';
import '../entities/budget_entity.dart';
import '../repositories/budget_repository.dart';

class GetBudgetsUseCase implements UseCase<List<BudgetEntity>, NoParams> {
  final BudgetRepository repository;

  GetBudgetsUseCase(this.repository);

  @override
  Future<List<BudgetEntity>> call(NoParams params) async {
    return await repository.getBudgets();
  }
}
