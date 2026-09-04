import '../../domain/entities/spending_plan_entity.dart';
import '../../domain/repositories/spending_plan_repository.dart';
import '../datasources/spending_plan_local_data_source.dart';
import '../models/spending_plan_model.dart';

class SpendingPlanRepositoryImpl implements SpendingPlanRepository {
  final SpendingPlanLocalDataSource localDataSource;

  SpendingPlanRepositoryImpl({required this.localDataSource});

  @override
  Future<SpendingPlanEntity> getSpendingPlan() async {
    return await localDataSource.getSpendingPlan();
  }

  @override
  Future<void> saveSpendingPlan(SpendingPlanEntity plan) async {
    final model = SpendingPlanModel.fromEntity(plan);
    await localDataSource.saveSpendingPlan(model);
  }
}
