import 'package:flutter_test/flutter_test.dart';
import 'package:budget_planner/features/spending_plan/domain/entities/spending_plan_entity.dart';
import 'package:budget_planner/features/spending_plan/domain/entities/spending_plan_group.dart';
import 'package:budget_planner/features/spending_plan/domain/entities/spending_plan_item.dart';
import 'package:budget_planner/features/spending_plan/domain/repositories/spending_plan_repository.dart';
import 'package:budget_planner/features/spending_plan/domain/usecases/get_spending_plan.dart';
import 'package:budget_planner/features/spending_plan/domain/usecases/save_spending_plan.dart';
import 'package:budget_planner/features/spending_plan/presentation/state/spending_plan_cubit.dart';
import 'package:budget_planner/features/spending_plan/presentation/state/spending_plan_state.dart';

class FakeSpendingPlanRepository implements SpendingPlanRepository {
  SpendingPlanEntity _plan = const SpendingPlanEntity(
    monthlyIncome: 25000.0,
    groups: [
      SpendingPlanGroup(
        id: 'food',
        title: 'อาหาร & เครื่องดื่ม',
        colorValue: 0xFFEF4444,
        isExpanded: true,
        items: [
          SpendingPlanItem(
            id: 'item-food',
            name: 'อาหาร & เครื่องดื่ม',
            amount: 6000.0,
            maxAmount: 30000.0,
          ),
        ],
      ),
      SpendingPlanGroup(
        id: 'transport',
        title: 'การเดินทาง & ค่าน้ำมัน',
        colorValue: 0xFFF59E0B,
        isExpanded: true,
        items: [
          SpendingPlanItem(
            id: 'item-transport',
            name: 'การเดินทาง & ค่าน้ำมัน',
            amount: 2000.0,
            maxAmount: 20000.0,
          ),
        ],
      ),
    ],
  );

  @override
  Future<SpendingPlanEntity> getSpendingPlan() async => _plan;

  @override
  Future<void> saveSpendingPlan(SpendingPlanEntity plan) async {
    _plan = plan;
  }
}

void main() {
  group('SpendingPlanCubit Tests', () {
    late FakeSpendingPlanRepository fakeRepo;
    late SpendingPlanCubit cubit;

    setUp(() {
      fakeRepo = FakeSpendingPlanRepository();
      cubit = SpendingPlanCubit(
        getSpendingPlanUseCase: GetSpendingPlanUseCase(fakeRepo),
        saveSpendingPlanUseCase: SaveSpendingPlanUseCase(fakeRepo),
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state has initial status', () {
      expect(cubit.state.status, equals(SpendingPlanStatus.initial));
    });

    test('loadPlan updates state with plan data', () async {
      await cubit.loadPlan();
      expect(cubit.state.status, equals(SpendingPlanStatus.success));
      expect(cubit.state.plan?.monthlyIncome, equals(25000.0));
      expect(cubit.state.plan?.totalExpenses, equals(8000.0));
      expect(cubit.state.plan?.remainingSavings, equals(17000.0));
    });

    test('updateMonthlyIncome correctly recalculates remaining savings', () async {
      await cubit.loadPlan();
      cubit.updateMonthlyIncome(30000.0);
      expect(cubit.state.plan?.monthlyIncome, equals(30000.0));
      expect(cubit.state.plan?.remainingSavings, equals(22000.0));
    });

    test('updateItemAmount updates spending plan item value', () async {
      await cubit.loadPlan();
      cubit.updateItemAmount('food', 'item-food', 7000.0);
      expect(cubit.state.plan?.totalExpenses, equals(9000.0));
      expect(cubit.state.plan?.remainingSavings, equals(16000.0));
    });
  });
}
