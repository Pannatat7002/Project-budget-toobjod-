import '../../../../core/usecases/usecase.dart';
import '../entities/spending_plan_entity.dart';
import '../repositories/spending_plan_repository.dart';

class GetSpendingPlanUseCase implements UseCase<SpendingPlanEntity, NoParams> {
  final SpendingPlanRepository repository;

  GetSpendingPlanUseCase(this.repository);

  @override
  Future<SpendingPlanEntity> call(NoParams params) async {
    return await repository.getSpendingPlan();
  }
}
