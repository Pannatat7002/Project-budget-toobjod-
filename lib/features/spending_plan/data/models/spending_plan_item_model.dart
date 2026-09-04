import '../../domain/entities/spending_plan_item.dart';

class SpendingPlanItemModel extends SpendingPlanItem {
  const SpendingPlanItemModel({
    required super.id,
    required super.name,
    required super.amount,
    super.maxAmount,
  });

  factory SpendingPlanItemModel.fromJson(Map<String, dynamic> json) {
    return SpendingPlanItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      maxAmount: (json['maxAmount'] as num?)?.toDouble() ?? 20000.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'maxAmount': maxAmount,
    };
  }

  factory SpendingPlanItemModel.fromEntity(SpendingPlanItem entity) {
    return SpendingPlanItemModel(
      id: entity.id,
      name: entity.name,
      amount: entity.amount,
      maxAmount: entity.maxAmount,
    );
  }
}
