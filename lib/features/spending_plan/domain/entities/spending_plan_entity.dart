import 'package:equatable/equatable.dart';
import 'spending_plan_group.dart';

class SpendingPlanEntity extends Equatable {
  final double monthlyIncome;
  final List<SpendingPlanGroup> groups;

  const SpendingPlanEntity({
    required this.monthlyIncome,
    required this.groups,
  });

  double get totalExpenses => groups.fold(0.0, (sum, g) => sum + g.totalAmount);
  double get remainingSavings => monthlyIncome - totalExpenses;
  double get savingsRatioPercentage =>
      monthlyIncome > 0 ? ((remainingSavings / monthlyIncome) * 100).clamp(0.0, 100.0) : 0.0;

  SpendingPlanEntity copyWith({
    double? monthlyIncome,
    List<SpendingPlanGroup>? groups,
  }) {
    return SpendingPlanEntity(
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      groups: groups ?? this.groups,
    );
  }

  @override
  List<Object?> get props => [monthlyIncome, groups];
}
