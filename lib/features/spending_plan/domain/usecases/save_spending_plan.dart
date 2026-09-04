import '../../../../core/usecases/usecase.dart';
import '../entities/spending_plan_entity.dart';
import '../repositories/spending_plan_repository.dart';

class SaveSpendingPlanUseCase implements UseCase<void, SpendingPlanEntity> {
  final SpendingPlanRepository repository;

  SaveSpendingPlanUseCase(this.repository);

  @override
  Future<void> call(SpendingPlanEntity plan) async {
    return await repository.saveSpendingPlan(plan);
  }
}
