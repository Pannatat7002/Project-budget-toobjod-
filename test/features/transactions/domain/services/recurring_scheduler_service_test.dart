import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budget_planner/core/constants/app_constants.dart';
import 'package:budget_planner/features/transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:budget_planner/features/transactions/domain/entities/transaction_entity.dart';
import 'package:budget_planner/features/transactions/domain/services/recurring_scheduler_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late RecurringSchedulerService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    service = RecurringSchedulerService(prefs);
  });

  group('RecurringSchedulerService Tests', () {
    test('saveRules and loadRules persists rules to SharedPreferences', () async {
      final rule = RecurringTransactionEntity(
        id: 'rec_1',
        title: 'Netflix Premium',
        amount: 419.0,
        type: TransactionType.expense,
        categoryId: 'ent',
        categoryName: 'บันเทิง',
        categoryIconCode: 0xe574,
        categoryColorValue: 0xFF9333EA,
        bankId: 'kbank',
        frequency: RecurringFrequency.monthly,
        scheduledDay: 15,
        startDate: DateTime(2026, 1, 1),
        tags: const ['subscriptions', 'entertainment'],
      );

      await service.saveRules([rule]);
      final loaded = service.loadRules();

      expect(loaded.length, 1);
      expect(loaded.first.id, 'rec_1');
      expect(loaded.first.title, 'Netflix Premium');
      expect(loaded.first.amount, 419.0);
      expect(loaded.first.tags, ['subscriptions', 'entertainment']);
      expect(loaded.first.isActive, true);
    });

    test('isDueToday correctly detects due date for monthly rule', () {
      final today = DateTime(2026, 9, 25);

      final dueRule = RecurringTransactionEntity(
        id: 'rec_due',
        title: 'Salary Deposit',
        amount: 50000.0,
        type: TransactionType.income,
        categoryId: 'salary',
        categoryName: 'เงินเดือน',
        categoryIconCode: 0xe040,
        categoryColorValue: 0xFF10B981,
        frequency: RecurringFrequency.monthly,
        scheduledDay: 25,
        startDate: DateTime(2026, 1, 1),
      );

      final notDueRule = RecurringTransactionEntity(
        id: 'rec_not_due',
        title: 'Rent',
        amount: 8000.0,
        type: TransactionType.expense,
        categoryId: 'housing',
        categoryName: 'ที่พักอาศัย',
        categoryIconCode: 0xe040,
        categoryColorValue: 0xFF3B82F6,
        frequency: RecurringFrequency.monthly,
        scheduledDay: 28,
        startDate: DateTime(2026, 1, 1),
      );

      expect(dueRule.isDueToday(today), isTrue);
      expect(notDueRule.isDueToday(today), isFalse);
    });

    test('isDueToday returns false if already executed today', () {
      final today = DateTime(2026, 9, 25);

      final rule = RecurringTransactionEntity(
        id: 'rec_due',
        title: 'Internet',
        amount: 599.0,
        type: TransactionType.expense,
        categoryId: 'bills',
        categoryName: 'บิลและสาธารณูปโภค',
        categoryIconCode: 0xe040,
        categoryColorValue: 0xFFF59E0B,
        frequency: RecurringFrequency.monthly,
        scheduledDay: 25,
        startDate: DateTime(2026, 1, 1),
        lastExecutedDate: DateTime(2026, 9, 25, 8, 30),
      );

      expect(rule.isDueToday(today), isFalse);
    });

    test('processDueRules creates TransactionEntity and updates lastExecutedDate', () async {
      final today = DateTime(2026, 9, 25);

      final rule = RecurringTransactionEntity(
        id: 'rule_auto',
        title: 'Auto Saving Fund',
        amount: 3000.0,
        type: TransactionType.transfer,
        categoryId: 'transfer',
        categoryName: 'โอนเงิน',
        categoryIconCode: 0xe040,
        categoryColorValue: 0xFF06B6D4,
        frequency: RecurringFrequency.monthly,
        scheduledDay: 25,
        startDate: DateTime(2026, 1, 1),
        tags: const ['savings', 'invest'],
      );

      final result = service.processDueRules([rule], now: today);

      expect(result.autoPostedTransactions.length, 1);
      final tx = result.autoPostedTransactions.first;
      expect(tx.title, 'Auto Saving Fund');
      expect(tx.amount, 3000.0);
      expect(tx.type, TransactionType.transfer);
      expect(tx.tags, containsAll(['savings', 'invest', '#รายการประจำ']));

      // Check that rule lastExecutedDate was updated
      expect(result.updatedRules.first.lastExecutedDate, isNotNull);
      expect(result.updatedRules.first.lastExecutedDate!.day, 25);
    });
  });
}
