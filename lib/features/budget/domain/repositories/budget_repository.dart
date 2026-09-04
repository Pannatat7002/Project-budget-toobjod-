import '../entities/budget_entity.dart';

abstract class BudgetRepository {
  Future<List<BudgetEntity>> getBudgets();
  Future<void> setBudget(BudgetEntity budget);
  Future<void> deleteBudget(String budgetId);
}
