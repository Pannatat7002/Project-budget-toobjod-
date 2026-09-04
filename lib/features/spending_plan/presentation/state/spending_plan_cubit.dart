import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/spending_plan_entity.dart';
import '../../domain/entities/spending_plan_group.dart';
import '../../domain/entities/spending_plan_item.dart';
import '../../domain/usecases/get_spending_plan.dart';
import '../../domain/usecases/save_spending_plan.dart';
import 'spending_plan_state.dart';

class SpendingPlanCubit extends Cubit<SpendingPlanState> {
  final GetSpendingPlanUseCase getSpendingPlanUseCase;
  final SaveSpendingPlanUseCase saveSpendingPlanUseCase;

  SpendingPlanCubit({
    required this.getSpendingPlanUseCase,
    required this.saveSpendingPlanUseCase,
  }) : super(const SpendingPlanState());

  Future<void> loadPlan() async {
    emit(state.copyWith(status: SpendingPlanStatus.loading));
    try {
      final plan = await getSpendingPlanUseCase(const NoParams());
      emit(state.copyWith(
        status: SpendingPlanStatus.success,
        plan: plan,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SpendingPlanStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void updateMonthlyIncome(double income) {
    if (state.plan == null) return;
    final updated = state.plan!.copyWith(monthlyIncome: income);
    emit(state.copyWith(plan: updated));
    _autoSave(updated);
  }

  void updateItemAmount(String groupId, String itemId, double amount) {
    if (state.plan == null) return;

    final updatedGroups = state.plan!.groups.map((group) {
      if (group.id == groupId) {
        final updatedItems = group.items.map((item) {
          if (item.id == itemId) {
            return item.copyWith(amount: amount);
          }
          return item;
        }).toList();
        return group.copyWith(items: updatedItems);
      }
      return group;
    }).toList();

    final updatedPlan = state.plan!.copyWith(groups: updatedGroups);
    emit(state.copyWith(plan: updatedPlan));
    _autoSave(updatedPlan);
  }

  void toggleGroupExpansion(String groupId) {
    if (state.plan == null) return;

    final updatedGroups = state.plan!.groups.map((group) {
      if (group.id == groupId) {
        return group.copyWith(isExpanded: !group.isExpanded);
      }
      return group;
    }).toList();

    final updatedPlan = state.plan!.copyWith(groups: updatedGroups);
    emit(state.copyWith(plan: updatedPlan));
    _autoSave(updatedPlan);
  }

  void addItem(String groupId, String itemName, double amount, double maxAmount) {
    if (state.plan == null) return;

    final actualMax = maxAmount > amount ? maxAmount : (amount > 0 ? amount * 2 : 10000.0);
    final newItem = SpendingPlanItem(
      id: 'item-${DateTime.now().millisecondsSinceEpoch}',
      name: itemName,
      amount: amount,
      maxAmount: actualMax,
    );

    final updatedGroups = state.plan!.groups.map((group) {
      if (group.id == groupId) {
        final newItems = List<SpendingPlanItem>.from(group.items)..add(newItem);
        return group.copyWith(items: newItems, isExpanded: true);
      }
      return group;
    }).toList();

    final updatedPlan = state.plan!.copyWith(groups: updatedGroups);
    emit(state.copyWith(plan: updatedPlan));
    _autoSave(updatedPlan);
  }

  void addGroup(String title, int colorValue) {
    if (state.plan == null) return;

    final newGroup = SpendingPlanGroup(
      id: 'grp-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      colorValue: colorValue,
      isExpanded: true,
      items: [],
    );

    final updatedGroups = List<SpendingPlanGroup>.from(state.plan!.groups)..add(newGroup);
    final updatedPlan = state.plan!.copyWith(groups: updatedGroups);
    emit(state.copyWith(plan: updatedPlan));
    _autoSave(updatedPlan);
  }

  void deleteGroup(String groupId) {
    if (state.plan == null) return;

    final updatedGroups = state.plan!.groups.where((g) => g.id != groupId).toList();
    final updatedPlan = state.plan!.copyWith(groups: updatedGroups);
    emit(state.copyWith(plan: updatedPlan));
    _autoSave(updatedPlan);
  }

  void deleteItem(String groupId, String itemId) {
    if (state.plan == null) return;

    final updatedGroups = state.plan!.groups.map((group) {
      if (group.id == groupId) {
        final newItems = group.items.where((item) => item.id != itemId).toList();
        return group.copyWith(items: newItems);
      }
      return group;
    }).toList();

    final updatedPlan = state.plan!.copyWith(groups: updatedGroups);
    emit(state.copyWith(plan: updatedPlan));
    _autoSave(updatedPlan);
  }

  Future<void> _autoSave(SpendingPlanEntity plan) async {
    try {
      await saveSpendingPlanUseCase(plan);
    } catch (_) {}
  }
}
