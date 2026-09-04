import '../entities/spending_plan_entity.dart';

abstract class SpendingPlanRepository {
  Future<SpendingPlanEntity> getSpendingPlan();
  Future<void> saveSpendingPlan(SpendingPlanEntity plan);
}
