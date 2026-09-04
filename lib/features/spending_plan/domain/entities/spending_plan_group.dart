import 'package:equatable/equatable.dart';
import 'spending_plan_item.dart';

class SpendingPlanGroup extends Equatable {
  final String id;
  final String title;
  final int colorValue;
  final bool isExpanded;
  final List<SpendingPlanItem> items;

  const SpendingPlanGroup({
    required this.id,
    required this.title,
    required this.colorValue,
    this.isExpanded = true,
    required this.items,
  });

  double get totalAmount => items.fold(0.0, (sum, item) => sum + item.amount);

  SpendingPlanGroup copyWith({
    String? id,
    String? title,
    int? colorValue,
    bool? isExpanded,
    List<SpendingPlanItem>? items,
  }) {
    return SpendingPlanGroup(
      id: id ?? this.id,
      title: title ?? this.title,
      colorValue: colorValue ?? this.colorValue,
      isExpanded: isExpanded ?? this.isExpanded,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [id, title, colorValue, isExpanded, items];
}
