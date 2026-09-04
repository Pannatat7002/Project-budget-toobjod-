import '../../domain/entities/budget_entity.dart';

class BudgetModel extends BudgetEntity {
  const BudgetModel({
    required super.id,
    required super.categoryId,
    required super.categoryName,
    required super.categoryIconCode,
    required super.categoryColorValue,
    required super.limitAmount,
    super.spentAmount,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      categoryIconCode: json['categoryIconCode'] as int,
      categoryColorValue: json['categoryColorValue'] as int,
      limitAmount: (json['limitAmount'] as num).toDouble(),
      spentAmount: (json['spentAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryIconCode': categoryIconCode,
      'categoryColorValue': categoryColorValue,
      'limitAmount': limitAmount,
      'spentAmount': spentAmount,
    };
  }

  factory BudgetModel.fromEntity(BudgetEntity entity) {
    return BudgetModel(
      id: entity.id,
      categoryId: entity.categoryId,
      categoryName: entity.categoryName,
      categoryIconCode: entity.categoryIconCode,
      categoryColorValue: entity.categoryColorValue,
      limitAmount: entity.limitAmount,
      spentAmount: entity.spentAmount,
    );
  }
}
