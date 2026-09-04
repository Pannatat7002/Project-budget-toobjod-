import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budget_planner/features/dashboard/presentation/widgets/toob_jod_hero_card.dart';

void main() {
  testWidgets('ToobJodHeroCard renders expense amount and triggers callback', (tester) async {
    bool summaryClicked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ToobJodHeroCard(
            totalExpense: 12650.0,
            totalIncome: 25000.0,
            totalBalance: 12350.0,
            onViewSummary: () {
              summaryClicked = true;
            },
          ),
        ),
      ),
    );

    // Verify expense text renders
    expect(find.text('ยอดใช้จ่าย'), findsOneWidget);
    expect(find.text('ยอดสรุปประจำเดือน'), findsOneWidget);
    expect(find.text('ดูสรุป'), findsOneWidget);

    // Tap summary button
    await tester.tap(find.text('ดูสรุป'));
    await tester.pump();

    expect(summaryClicked, isTrue);
  });
}
