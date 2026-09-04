import 'package:flutter_test/flutter_test.dart';
import 'package:budget_planner/features/spending_plan/domain/entities/spending_plan_entity.dart';
import 'package:budget_planner/features/spending_plan/domain/entities/spending_plan_group.dart';
import 'package:budget_planner/features/spending_plan/domain/entities/spending_plan_item.dart';

void main() {
  group('SpendingPlanEntity Test', () {
    test('calculates total expenses, remaining savings, and savings ratio correctly', () {
      const plan = SpendingPlanEntity(
        monthlyIncome: 25000.0,
        groups: [
          SpendingPlanGroup(
            id: 'grp-1',
            title: 'กลุ่มที่ 1',
            colorValue: 0xFF2563EB,
            items: [
              SpendingPlanItem(id: 'i1', name: 'รายการ 1', amount: 0.0),
              SpendingPlanItem(id: 'i2', name: 'รายการ 2', amount: 5000.0),
              SpendingPlanItem(id: 'i3', name: 'รายการ 3', amount: 1000.0),
            ],
          ),
          SpendingPlanGroup(
            id: 'grp-2',
            title: 'กลุ่มที่ 2',
            colorValue: 0xFF22C55E,
            items: [
              SpendingPlanItem(id: 'i4', name: 'รายการ 4', amount: 1350.0),
              SpendingPlanItem(id: 'i5', name: 'รายการ 5', amount: 500.0),
              SpendingPlanItem(id: 'i6', name: 'รายการ 6', amount: 450.0),
              SpendingPlanItem(id: 'i7', name: 'รายการ 7', amount: 200.0),
            ],
          ),
        ],
      );

      expect(plan.totalExpenses, equals(8500.0));
      expect(plan.remainingSavings, equals(16500.0));
      expect(plan.savingsRatioPercentage, equals(66.0));
    });
  });
}
