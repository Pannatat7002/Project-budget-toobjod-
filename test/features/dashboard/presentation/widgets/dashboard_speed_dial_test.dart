import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budget_planner/features/dashboard/presentation/widgets/dashboard_speed_dial.dart';

void main() {
  testWidgets('DashboardSpeedDial toggles and triggers actions', (tester) async {
    bool incomeClicked = false;
    bool expenseClicked = false;
    bool transferClicked = false;
    bool? isOpenState;

    final key = GlobalKey<DashboardSpeedDialState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          floatingActionButton: DashboardSpeedDial(
            key: key,
            onOpenChanged: (val) => isOpenState = val,
            onAddIncome: () => incomeClicked = true,
            onAddExpense: () => expenseClicked = true,
            onTransfer: () => transferClicked = true,
          ),
        ),
      ),
    );

    // Initial state: FAB is present and closed
    expect(find.byKey(const Key('dashboard_speed_dial_main_fab')), findsOneWidget);
    expect(key.currentState?.isOpen, isFalse);

    // Tap main FAB to open speed dial
    await tester.tap(find.byKey(const Key('dashboard_speed_dial_main_fab')));
    await tester.pumpAndSettle();

    expect(isOpenState, isTrue);
    expect(key.currentState?.isOpen, isTrue);

    // Verify 3 items exist
    expect(find.text('รับเงิน'), findsOneWidget);
    expect(find.text('จ่ายเงิน'), findsOneWidget);
    expect(find.text('โอนย้าย'), findsOneWidget);

    // Test programmatically closing from outside
    key.currentState?.close();
    await tester.pumpAndSettle();
    expect(isOpenState, isFalse);
    expect(key.currentState?.isOpen, isFalse);

    // Re-open and tap 'รับเงิน'
    await tester.tap(find.byKey(const Key('dashboard_speed_dial_main_fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('รับเงิน'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(incomeClicked, isTrue);

    // Re-open and tap 'จ่ายเงิน'
    await tester.tap(find.byKey(const Key('dashboard_speed_dial_main_fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('จ่ายเงิน'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(expenseClicked, isTrue);

    // Re-open and tap 'โอนย้าย'
    await tester.tap(find.byKey(const Key('dashboard_speed_dial_main_fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('โอนย้าย'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(transferClicked, isTrue);
  });
}

