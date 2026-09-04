import 'package:equatable/equatable.dart';

class BudgetEntity extends Equatable {
  final String id;
  final String categoryId;
  final String categoryName;
  final int categoryIconCode;
  final int categoryColorValue;
  final double limitAmount;
  final double spentAmount; // Calculated dynamically from transactions in the current month

  const BudgetEntity({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIconCode,
    required this.categoryColorValue,
    required this.limitAmount,
    this.spentAmount = 0.0,
  });

  double get remainingAmount => (limitAmount - spentAmount).clamp(0.0, double.infinity);
  double get progressPercentage => limitAmount > 0 ? (spentAmount / limitAmount).clamp(0.0, 1.5) : 0.0;
  bool get isExceeded => spentAmount > limitAmount;
  bool get isWarning => !isExceeded && progressPercentage >= 0.8;

  BudgetEntity copyWith({
    String? id,
    String? categoryId,
    String? categoryName,
    int? categoryIconCode,
    int? categoryColorValue,
    double? limitAmount,
    double? spentAmount,
  }) {
    return BudgetEntity(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIconCode: categoryIconCode ?? this.categoryIconCode,
      categoryColorValue: categoryColorValue ?? this.categoryColorValue,
      limitAmount: limitAmount ?? this.limitAmount,
      spentAmount: spentAmount ?? this.spentAmount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        categoryId,
        categoryName,
        categoryIconCode,
        categoryColorValue,
        limitAmount,
        spentAmount,
      ];
}
