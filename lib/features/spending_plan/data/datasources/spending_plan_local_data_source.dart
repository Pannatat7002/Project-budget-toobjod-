import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/spending_plan_group_model.dart';
import '../models/spending_plan_item_model.dart';
import '../models/spending_plan_model.dart';

abstract class SpendingPlanLocalDataSource {
  Future<SpendingPlanModel> getSpendingPlan();
  Future<void> saveSpendingPlan(SpendingPlanModel plan);
}

class SpendingPlanLocalDataSourceImpl implements SpendingPlanLocalDataSource {
  final SharedPreferences sharedPreferences;

  SpendingPlanLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<SpendingPlanModel> getSpendingPlan() async {
    try {
      final jsonString = sharedPreferences.getString(AppConstants.spendingPlanStorageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
        return SpendingPlanModel.fromJson(jsonMap);
      } else {
        final initialPlan = _generateDefaultPlan();
        await saveSpendingPlan(initialPlan);
        return initialPlan;
      }
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<SpendingPlanModel> saveSpendingPlan(SpendingPlanModel plan) async {
    try {
      await sharedPreferences.setString(AppConstants.spendingPlanStorageKey, jsonEncode(plan.toJson()));
      return plan;
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  SpendingPlanModel _generateDefaultPlan() {
    return SpendingPlanModel(
      monthlyIncome: 0.0,
      groups: AppConstants.defaultExpenseCategories.map((cat) {
        return SpendingPlanGroupModel(
          id: cat.id,
          title: cat.name,
          colorValue: cat.colorValue,
          isExpanded: true,
          items: [
            SpendingPlanItemModel(
              id: 'item-${cat.id}',
              name: cat.name,
              amount: 0.0,
              maxAmount: 30000.0,
            ),
          ],
        );
      }).toList(),
    );
  }
}
