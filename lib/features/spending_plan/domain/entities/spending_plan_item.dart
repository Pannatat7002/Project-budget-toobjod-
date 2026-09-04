import 'package:equatable/equatable.dart';

class SpendingPlanItem extends Equatable {
  final String id;
  final String name;
  final double amount;
  final double maxAmount;

  const SpendingPlanItem({
    required this.id,
    required this.name,
    required this.amount,
    this.maxAmount = 20000.0,
  });

  SpendingPlanItem copyWith({
    String? id,
    String? name,
    double? amount,
    double? maxAmount,
  }) {
    return SpendingPlanItem(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      maxAmount: maxAmount ?? this.maxAmount,
    );
  }

  @override
  List<Object?> get props => [id, name, amount, maxAmount];
}
