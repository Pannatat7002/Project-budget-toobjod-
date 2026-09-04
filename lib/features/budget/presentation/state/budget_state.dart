import 'package:equatable/equatable.dart';
import '../../domain/entities/budget_entity.dart';

enum BudgetStatus { initial, loading, success, failure }

class BudgetState extends Equatable {
  final BudgetStatus status;
  final List<BudgetEntity> budgets;
  final String? errorMessage;

  const BudgetState({
    this.status = BudgetStatus.initial,
    this.budgets = const [],
    this.errorMessage,
  });

  double get totalBudgetLimit => budgets.fold(0.0, (sum, b) => sum + b.limitAmount);
  double get totalBudgetSpent => budgets.fold(0.0, (sum, b) => sum + b.spentAmount);
  double get totalBudgetRemaining => (totalBudgetLimit - totalBudgetSpent).clamp(0.0, double.infinity);
  double get totalProgressPercentage =>
      totalBudgetLimit > 0 ? (totalBudgetSpent / totalBudgetLimit).clamp(0.0, 1.5) : 0.0;

  BudgetState copyWith({
    BudgetStatus? status,
    List<BudgetEntity>? budgets,
    String? errorMessage,
  }) {
    return BudgetState(
      status: status ?? this.status,
      budgets: budgets ?? this.budgets,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, budgets, errorMessage];
}
