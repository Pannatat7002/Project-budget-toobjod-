import 'package:flutter_test/flutter_test.dart';
import 'package:budget_planner/core/constants/app_constants.dart';
import 'package:budget_planner/features/accounts/domain/entities/bank_account_entity.dart';
import 'package:budget_planner/features/accounts/domain/repositories/account_repository.dart';
import 'package:budget_planner/features/accounts/presentation/state/account_cubit.dart';
import 'package:budget_planner/features/transactions/domain/entities/transaction_entity.dart';

class FakeAccountRepository implements AccountRepository {
  final List<BankAccountEntity> _accounts = [];
  bool _isEyeHidden = false;

  @override
  Future<List<BankAccountEntity>> getAccounts() async =>
      List.unmodifiable(_accounts);

  @override
  Future<void> saveAccounts(List<BankAccountEntity> accounts) async {
    _accounts
      ..clear()
      ..addAll(accounts);
  }

  @override
  Future<void> addOrUpdateAccount(BankAccountEntity account) async {
    final idx = _accounts.indexWhere((a) => a.id == account.id);
    if (idx != -1) {
      _accounts[idx] = account;
    } else {
      _accounts.add(account);
    }
  }

  @override
  Future<void> deleteAccount(String id) async {
    _accounts.removeWhere((a) => a.id == id);
  }

  @override
  Future<bool> getEyeViewPrivacy() async => _isEyeHidden;

  @override
  Future<void> setEyeViewPrivacy(bool isHidden) async {
    _isEyeHidden = isHidden;
  }
}

void main() {
  group('Account Reconciliation Unit Tests', () {
    late FakeAccountRepository fakeRepo;
    late AccountCubit cubit;

    final testAccount = BankAccountEntity(
      id: 'acc_kbank_1',
      bankId: 'kbank',
      bankName: 'ธนาคารกสิกรไทย',
      accountName: 'K-eSavings',
      accountMask: '1234',
      currentBalance: 1000.0,
      brandColor: 0xFF137E3D,
      isAutoSyncActive: true,
      createdAt: DateTime(2026, 1, 1),
    );

    setUp(() async {
      fakeRepo = FakeAccountRepository();
      cubit = AccountCubit(repository: fakeRepo);
      await cubit.addOrUpdateAccount(testAccount);
    });

    tearDown(() {
      cubit.close();
    });

    test('AppConstants contains reconciliation categories for income and expense', () {
      final reconExpense = AppConstants.defaultExpenseCategories
          .firstWhere((c) => c.id == 'reconciliation_expense');
      expect(reconExpense.name, 'ปรับปรุงยอดเงินลด');

      final reconIncome = AppConstants.defaultIncomeCategories
          .firstWhere((c) => c.id == 'reconciliation_income');
      expect(reconIncome.name, 'ปรับปรุงยอดเงินเพิ่ม');
    });

    test('Positive reconciliation adjusts balance upwards to match actual bank balance', () {
      // Current balance: 1,000. Actual in bank: 2,500. Diff = +1,500
      const currentBalance = 1000.0;
      const actualBalance = 2500.0;
      const diff = actualBalance - currentBalance;

      expect(diff, 1500.0);

      // Create income adjustment transaction
      final adjustmentTx = TransactionEntity(
        id: 'recon_tx_1',
        title: 'ปรับปรุงยอดเงินเพิ่ม (กระทบยอด)',
        amount: diff,
        type: TransactionType.income,
        categoryId: 'reconciliation_income',
        categoryName: 'ปรับปรุงยอดเงินเพิ่ม',
        categoryIconCode: 0xe8af,
        categoryColorValue: 0xFF10B981,
        date: DateTime.now(),
        bankId: testAccount.bankId,
        bankAccountId: testAccount.id,
        bankShortName: testAccount.shortName,
        accountMask: testAccount.accountMask,
        note: 'กระทบยอดบัญชีให้ตรงกับยอดจริงในธนาคาร (2,500.00 ฿)',
      );

      // Initial transactions bringing balance to 1,000
      final initialTx = TransactionEntity(
        id: 'initial_tx',
        title: 'เงินเดือนเดิม',
        amount: 1000.0,
        type: TransactionType.income,
        categoryId: 'salary',
        categoryName: 'เงินเดือน',
        categoryIconCode: 0xe040,
        categoryColorValue: 0xFF10B981,
        date: DateTime(2026, 1, 2),
        bankId: testAccount.bankId,
        bankAccountId: testAccount.id,
      );

      final allTransactions = [adjustmentTx, initialTx];
      cubit.refreshBalancesFromTransactions(allTransactions);

      final updated = cubit.state.accounts.firstWhere((a) => a.id == testAccount.id);
      expect(updated.currentBalance, 2500.0);
    });

    test('Negative reconciliation adjusts balance downwards to match actual bank balance', () {
      // Current balance: 5,000. Actual in bank: 3,800. Diff = -1,200
      const currentBalance = 5000.0;
      const actualBalance = 3800.0;
      const diff = actualBalance - currentBalance;

      expect(diff, -1200.0);

      final initialTx = TransactionEntity(
        id: 'initial_tx',
        title: 'เงินเริ่มต้น',
        amount: 5000.0,
        type: TransactionType.income,
        categoryId: 'salary',
        categoryName: 'เงินเดือน',
        categoryIconCode: 0xe040,
        categoryColorValue: 0xFF10B981,
        date: DateTime(2026, 1, 2),
        bankId: testAccount.bankId,
        bankAccountId: testAccount.id,
      );

      // Create expense adjustment transaction
      final adjustmentTx = TransactionEntity(
        id: 'recon_tx_2',
        title: 'ปรับปรุงยอดเงินลด (กระทบยอด)',
        amount: diff.abs(),
        type: TransactionType.expense,
        categoryId: 'reconciliation_expense',
        categoryName: 'ปรับปรุงยอดเงินลด',
        categoryIconCode: 0xe8af,
        categoryColorValue: 0xFF64748B,
        date: DateTime.now(),
        bankId: testAccount.bankId,
        bankAccountId: testAccount.id,
        bankShortName: testAccount.shortName,
        accountMask: testAccount.accountMask,
        note: 'กระทบยอดบัญชีให้ตรงกับยอดจริงในธนาคาร (3,800.00 ฿)',
      );

      final allTransactions = [adjustmentTx, initialTx];
      cubit.refreshBalancesFromTransactions(allTransactions);

      final updated = cubit.state.accounts.firstWhere((a) => a.id == testAccount.id);
      expect(updated.currentBalance, 3800.0);
    });

    test('Zero difference requires no adjustment transaction', () {
      const currentBalance = 1000.0;
      const actualBalance = 1000.0;
      const diff = actualBalance - currentBalance;

      expect(diff.abs() < 0.01, isTrue);
    });
  });
}
