import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budget_planner/features/spending_plan/presentation/widgets/spending_summary_header.dart';

void main() {
  testWidgets('SpendingSummaryHeader displays income, planned expenses and expected savings', (tester) async {
    bool editClicked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpendingSummaryHeader(
            monthlyIncome: 25000.0,
            totalExpenses: 12650.0,
            remainingSavings: 12350.0,
            savingsRatioPercentage: 49.0,
            onEditIncome: () {
              editClicked = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('รายรับประจำเดือน'), findsOneWidget);
    expect(find.text('แผนงบรายจ่ายรวม'), findsOneWidget);
    expect(find.text('คาดว่าจะเหลือเก็บ'), findsOneWidget);
    expect(find.text('แก้ไขรายรับ'), findsOneWidget);

    await tester.tap(find.text('แก้ไขรายรับ'));
    await tester.pump();

    expect(editClicked, isTrue);
  });
}
