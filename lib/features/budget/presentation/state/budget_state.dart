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

  int get daysInCurrentMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0).day;
  }

  int get daysRemainingInMonth {
    final now = DateTime.now();
    final totalDays = daysInCurrentMonth;
    return (totalDays - now.day + 1).clamp(1, totalDays);
  }

  /// Base daily budget allowance based on remaining monthly budget divided by remaining days
  double get dailyBaseAllowance {
    if (totalBudgetLimit <= 0) return 0.0;
    return totalBudgetRemaining / daysRemainingInMonth;
  }

  /// Calculate safe to spend for today given today's spent amount and optional real cash account balance.
  /// Uses Budget as primary driver (to protect savings), but caps at actual balance if cash runs low.
  double getSafeToSpendToday(double todaySpent, [double? actualAccountBalance]) {
    if (totalBudgetLimit <= 0) return 0.0;
    final days = daysRemainingInMonth > 0 ? daysRemainingInMonth : 1;
    final budgetDaily = totalBudgetRemaining / days;

    // Hybrid Safe-Guard: If actual cash is less than remaining budget, cap with cash
    double effectiveDaily = budgetDaily;
    if (actualAccountBalance != null && actualAccountBalance < totalBudgetRemaining) {
      final cashDaily = (actualAccountBalance / days).clamp(0.0, budgetDaily);
      effectiveDaily = cashDaily;
    }

    return effectiveDaily - todaySpent;
  }

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
