import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/budget_model.dart';

abstract class BudgetLocalDataSource {
  Future<List<BudgetModel>> getBudgets();
  Future<void> saveBudgets(List<BudgetModel> budgets);
  Future<void> setBudget(BudgetModel budget);
  Future<void> deleteBudget(String budgetId);
}

class BudgetLocalDataSourceImpl implements BudgetLocalDataSource {
  final SharedPreferences sharedPreferences;

  BudgetLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<BudgetModel>> getBudgets() async {
    try {
      final jsonString = sharedPreferences.getString(AppConstants.budgetsStorageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.map((item) => BudgetModel.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        return [];
      }
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> saveBudgets(List<BudgetModel> budgets) async {
    try {
      final jsonList = budgets.map((b) => b.toJson()).toList();
      await sharedPreferences.setString(AppConstants.budgetsStorageKey, jsonEncode(jsonList));
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> setBudget(BudgetModel budget) async {
    final list = await getBudgets();
    final index = list.indexWhere((b) => b.categoryId == budget.categoryId);
    if (index != -1) {
      list[index] = budget;
    } else {
      list.add(budget);
    }
    await saveBudgets(list);
  }

  @override
  Future<void> deleteBudget(String budgetId) async {
    final list = await getBudgets();
    list.removeWhere((b) => b.id == budgetId);
    await saveBudgets(list);
  }
}
