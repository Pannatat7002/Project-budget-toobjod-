import 'package:equatable/equatable.dart';
import '../../domain/entities/spending_plan_entity.dart';

enum SpendingPlanStatus { initial, loading, success, failure }

class SpendingPlanState extends Equatable {
  final SpendingPlanStatus status;
  final SpendingPlanEntity? plan;
  final String? errorMessage;

  const SpendingPlanState({
    this.status = SpendingPlanStatus.initial,
    this.plan,
    this.errorMessage,
  });

  SpendingPlanState copyWith({
    SpendingPlanStatus? status,
    SpendingPlanEntity? plan,
    String? errorMessage,
  }) {
    return SpendingPlanState(
      status: status ?? this.status,
      plan: plan ?? this.plan,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, plan, errorMessage];
}
