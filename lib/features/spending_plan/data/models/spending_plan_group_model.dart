import '../../domain/entities/spending_plan_group.dart';
import 'spending_plan_item_model.dart';

class SpendingPlanGroupModel extends SpendingPlanGroup {
  const SpendingPlanGroupModel({
    required super.id,
    required super.title,
    required super.colorValue,
    super.isExpanded,
    required super.items,
  });

  factory SpendingPlanGroupModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return SpendingPlanGroupModel(
      id: json['id'] as String,
      title: json['title'] as String,
      colorValue: json['colorValue'] as int,
      isExpanded: json['isExpanded'] as bool? ?? true,
      items: rawItems
          .map((item) => SpendingPlanItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'colorValue': colorValue,
      'isExpanded': isExpanded,
      'items': items.map((item) => SpendingPlanItemModel.fromEntity(item).toJson()).toList(),
    };
  }

  factory SpendingPlanGroupModel.fromEntity(SpendingPlanGroup entity) {
    return SpendingPlanGroupModel(
      id: entity.id,
      title: entity.title,
      colorValue: entity.colorValue,
      isExpanded: entity.isExpanded,
      items: entity.items,
    );
  }
}
