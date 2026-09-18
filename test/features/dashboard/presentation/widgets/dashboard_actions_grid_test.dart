import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budget_planner/features/dashboard/presentation/widgets/dashboard_actions_grid.dart';

void main() {
  testWidgets('DashboardActionsGrid renders Analytics, Income, and Expense without top budget', (tester) async {
    bool incomeClicked = false;
    bool expenseClicked = false;
    bool analyticsClicked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardActionsGrid(
            onAddIncome: () => incomeClicked = true,
            onAddExpense: () => expenseClicked = true,
            onAnalytics: () => analyticsClicked = true,
          ),
        ),
      ),
    );

    // Verify 'วิเคราะห์', 'รับเงิน', 'จ่ายเงิน' exist
    expect(find.text('วิเคราะห์'), findsOneWidget);
    expect(find.text('สถิติ & กราฟสรุป'), findsOneWidget);
    expect(find.text('รับเงิน'), findsOneWidget);
    expect(find.text('จ่ายเงิน'), findsOneWidget);

    // Verify 'ตั้งงบประมาณ' does NOT exist in DashboardActionsGrid
    expect(find.text('ตั้งงบประมาณ'), findsNothing);

    // Test tap on 'วิเคราะห์'
    await tester.tap(find.text('วิเคราะห์'));
    await tester.pump();
    expect(analyticsClicked, isTrue);

    // Test tap on 'รับเงิน'
    await tester.tap(find.text('รับเงิน'));
    await tester.pump();
    expect(incomeClicked, isTrue);

    // Test tap on 'จ่ายเงิน'
    await tester.tap(find.text('จ่ายเงิน'));
    await tester.pump();
    expect(expenseClicked, isTrue);
  });
}
