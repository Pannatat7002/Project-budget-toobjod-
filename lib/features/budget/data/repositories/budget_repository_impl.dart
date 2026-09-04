import '../../domain/entities/budget_entity.dart';
import '../../domain/repositories/budget_repository.dart';
import '../datasources/budget_local_data_source.dart';
import '../models/budget_model.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetLocalDataSource localDataSource;

  BudgetRepositoryImpl({required this.localDataSource});

  @override
  Future<List<BudgetEntity>> getBudgets() async {
    return await localDataSource.getBudgets();
  }

  @override
  Future<void> setBudget(BudgetEntity budget) async {
    final model = BudgetModel.fromEntity(budget);
    await localDataSource.setBudget(model);
  }

  @override
  Future<void> deleteBudget(String budgetId) async {
    await localDataSource.deleteBudget(budgetId);
  }
}
