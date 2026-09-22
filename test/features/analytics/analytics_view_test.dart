import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budget_planner/features/analytics/presentation/views/analytics_view.dart';
import 'package:budget_planner/features/analytics/presentation/widgets/category_pie_chart.dart';
import 'package:budget_planner/features/transactions/domain/entities/transaction_entity.dart';
import 'package:budget_planner/features/transactions/presentation/state/transaction_cubit.dart';
import 'package:budget_planner/features/transactions/presentation/state/transaction_state.dart';

class MockTransactionCubit extends Cubit<TransactionState> implements TransactionCubit {
  MockTransactionCubit(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('AnalyticsView renders category breakdown at top and key sections', (tester) async {
    final transactions = [
      TransactionEntity(
        id: '1',
        title: 'ข้าวผัดกะเพรา',
        amount: 60.0,
        type: TransactionType.expense,
        categoryId: 'food',
        categoryName: 'อาหารและเครื่องดื่ม',
        categoryColorValue: 0xFFFF7A00,
        categoryIconCode: 0xe040,
        date: DateTime.now(),
      ),
      TransactionEntity(
        id: '2',
        title: 'เงินเดือน',
        amount: 25000.0,
        type: TransactionType.income,
        categoryId: 'salary',
        categoryName: 'เงินเดือน',
        categoryColorValue: 0xFF2563EB,
        categoryIconCode: 0xe040,
        date: DateTime.now(),
      ),
    ];

    final state = TransactionState(
      status: TransactionStatus.success,
      transactions: transactions,
    );
    final cubit = MockTransactionCubit(state);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<TransactionCubit>.value(
          value: cubit,
          child: const AnalyticsView(),
        ),
      ),
    );
    await tester.pump();

    // Verify Title & AppBar Action
    expect(find.text('วิเคราะห์ & รายงาน'), findsOneWidget);
    expect(find.text('ส่งออก'), findsOneWidget);

    // Verify Period Selector
    expect(find.text('เดือนนี้'), findsOneWidget);
    expect(find.text('เดือนที่แล้ว'), findsOneWidget);

    // Verify Hero Section: สัดส่วนรายจ่าย is rendered
    expect(find.text('สัดส่วนรายจ่าย'), findsOneWidget);
    expect(find.byType(CategoryPieChart), findsOneWidget);

    // Verify Cash Flow Summary Section
    expect(find.text('สรุปกระแสเงินสด'), findsOneWidget);

    // Verify Key Financial Metrics Section
    expect(find.text('อัตราการออมสุทธิ'), findsOneWidget);
    expect(find.text('สัดส่วนรายจ่าย/รายรับ'), findsOneWidget);
    expect(find.text('ค่าใช้จ่ายเฉลี่ยต่อวัน'), findsOneWidget);
    expect(find.text('ธุรกรรมทั้งหมด'), findsOneWidget);
  });
}
