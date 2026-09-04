import '../../domain/entities/spending_plan_entity.dart';
import 'spending_plan_group_model.dart';

class SpendingPlanModel extends SpendingPlanEntity {
  const SpendingPlanModel({
    required super.monthlyIncome,
    required super.groups,
  });

  factory SpendingPlanModel.fromJson(Map<String, dynamic> json) {
    final rawGroups = json['groups'] as List<dynamic>? ?? [];
    return SpendingPlanModel(
      monthlyIncome: (json['monthlyIncome'] as num?)?.toDouble() ?? 0.0,
      groups: rawGroups
          .map((g) => SpendingPlanGroupModel.fromJson(g as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monthlyIncome': monthlyIncome,
      'groups': groups.map((g) => SpendingPlanGroupModel.fromEntity(g).toJson()).toList(),
    };
  }

  factory SpendingPlanModel.fromEntity(SpendingPlanEntity entity) {
    return SpendingPlanModel(
      monthlyIncome: entity.monthlyIncome,
      groups: entity.groups,
    );
  }
}
