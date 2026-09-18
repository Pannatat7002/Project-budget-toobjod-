import 'package:flutter_test/flutter_test.dart';
import 'package:budget_planner/features/accounts/domain/entities/bank_account_entity.dart';
import 'package:budget_planner/features/accounts/domain/repositories/account_repository.dart';
import 'package:budget_planner/features/accounts/presentation/state/account_cubit.dart';
import 'package:budget_planner/features/transactions/domain/entities/transaction_entity.dart';

class FakeAccountRepository implements AccountRepository {
  final List<BankAccountEntity> _accounts = [];
  bool _isEyeHidden = false;

  @override
  Future<List<BankAccountEntity>> getAccounts() async => List.unmodifiable(_accounts);

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
  group('AccountCubit Tests', () {
    late FakeAccountRepository fakeRepo;
    late AccountCubit cubit;

    setUp(() {
      fakeRepo = FakeAccountRepository();
      cubit = AccountCubit(repository: fakeRepo);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state has empty accounts and eye view visible', () {
      expect(cubit.state.accounts, isEmpty);
      expect(cubit.state.isEyeViewHidden, isFalse);
      expect(cubit.state.selectedBankId, isNull);
    });

    test('loadAccounts populates state correctly', () async {
      final acc = BankAccountEntity(
        id: 'acc_1',
        bankId: 'kbank',
        bankName: 'ธนาคารกสิกรไทย',
        accountName: 'K PLUS',
        accountMask: '1234',
        brandColor: 0xFF138F2D,
        createdAt: DateTime.now(),
      );
      await fakeRepo.addOrUpdateAccount(acc);

      await cubit.loadAccounts();

      expect(cubit.state.accounts.length, 1);
      expect(cubit.state.accounts.first.id, 'acc_1');
    });

    test('selectBank updates selectedBankId', () {
      cubit.selectBank('scb');
      expect(cubit.state.selectedBankId, 'scb');

      cubit.selectBank(null);
      expect(cubit.state.selectedBankId, isNull);
    });

    test('toggleEyeView toggles privacy setting', () async {
      expect(cubit.state.isEyeViewHidden, isFalse);

      await cubit.toggleEyeView();
      expect(cubit.state.isEyeViewHidden, isTrue);

      await cubit.toggleEyeView();
      expect(cubit.state.isEyeViewHidden, isFalse);
    });

    test('refreshBalancesFromTransactions calculates balances accurately per account', () async {
      final acc1 = BankAccountEntity(
        id: 'acc_kbank_main',
        bankId: 'kbank',
        bankName: 'กสิกร บัญชี 1',
        accountName: 'เงินเดือน KBank',
        brandColor: 0xFF138F2D,
        createdAt: DateTime.now(),
      );
      final acc2 = BankAccountEntity(
        id: 'acc_kbank_savings',
        bankId: 'kbank',
        bankName: 'กสิกร บัญชี 2',
        accountName: 'เงินออม KBank',
        brandColor: 0xFF138F2D,
        createdAt: DateTime.now(),
      );
      await fakeRepo.addOrUpdateAccount(acc1);
      await fakeRepo.addOrUpdateAccount(acc2);
      await cubit.loadAccounts();

      final tx1 = TransactionEntity(
        id: 'tx-1',
        title: 'เงินเดือนเข้าบัญชี 1',
        amount: 30000,
        type: TransactionType.income,
        categoryId: 'salary',
        categoryName: 'เงินเดือน',
        categoryIconCode: 0xe040,
        categoryColorValue: 0xFF10B981,
        date: DateTime.now(),
        bankId: 'kbank',
        bankAccountId: 'acc_kbank_main',
      );

      final tx2 = TransactionEntity(
        id: 'tx-2',
        title: 'ค่ากาแฟจากบัญชี 1',
        amount: 120,
        type: TransactionType.expense,
        categoryId: 'food',
        categoryName: 'อาหาร',
        categoryIconCode: 0xe040,
        categoryColorValue: 0xFFF59E0B,
        date: DateTime.now(),
        bankId: 'kbank',
        bankAccountId: 'acc_kbank_main',
      );

      final tx3 = TransactionEntity(
        id: 'tx-3',
        title: 'เงินออมเข้าบัญชี 2',
        amount: 5000,
        type: TransactionType.income,
        categoryId: 'savings',
        categoryName: 'เงินออม',
        categoryIconCode: 0xe040,
        categoryColorValue: 0xFF10B981,
        date: DateTime.now(),
        bankId: 'kbank',
        bankAccountId: 'acc_kbank_savings',
      );

      cubit.refreshBalancesFromTransactions([tx1, tx2, tx3]);

      final updatedMain = cubit.state.accounts.firstWhere((a) => a.id == 'acc_kbank_main');
      final updatedSavings = cubit.state.accounts.firstWhere((a) => a.id == 'acc_kbank_savings');

      // Account 1: 30,000 - 120 = 29,880
      expect(updatedMain.currentBalance, 29880.0);
      // Account 2: 5,000
      expect(updatedSavings.currentBalance, 5000.0);
    });

    test('ensureAccountForBank creates new account when not found and reuses existing', () async {
      final created = await cubit.ensureAccountForBank('ttb', accountMask: '9876');
      expect(created.bankId, 'ttb');
      expect(created.accountMask, '9876');
      expect(cubit.state.accounts.length, 1);

      // Call again for same bank
      final reused = await cubit.ensureAccountForBank('ttb');
      expect(reused.id, created.id);
      expect(cubit.state.accounts.length, 1);
    });
  });
}
