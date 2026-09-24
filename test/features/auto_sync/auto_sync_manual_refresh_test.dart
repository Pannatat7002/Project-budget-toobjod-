import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:budget_planner/features/auto_sync/domain/entities/detected_transaction.dart';
import 'package:budget_planner/features/auto_sync/domain/entities/swipe_history_record.dart';
import 'package:budget_planner/features/auto_sync/domain/repositories/auto_sync_repository.dart';
import 'package:budget_planner/features/auto_sync/presentation/state/auto_sync_cubit.dart';
import 'package:budget_planner/features/transactions/domain/entities/transaction_entity.dart';
import 'package:budget_planner/features/transactions/domain/usecases/add_transaction.dart';
import 'package:budget_planner/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:budget_planner/features/transactions/domain/usecases/get_transactions.dart';
import 'package:budget_planner/features/transactions/domain/usecases/update_transaction.dart';
import 'package:budget_planner/features/transactions/presentation/state/transaction_cubit.dart';
import 'package:budget_planner/features/transactions/presentation/state/transaction_state.dart';
import 'package:budget_planner/features/accounts/domain/entities/bank_account_entity.dart';
import 'package:budget_planner/features/accounts/presentation/state/account_cubit.dart';
import 'package:budget_planner/features/accounts/presentation/state/account_state.dart';
import 'package:budget_planner/features/accounts/domain/repositories/account_repository.dart';
import 'package:budget_planner/features/transactions/domain/repositories/transaction_repository.dart';

class FakeAutoSyncRepository implements AutoSyncRepository {
  bool permissionGranted = true;
  bool serviceConnected = true;
  List<DetectedTransaction> missedNotificationsToReturn = [];
  final List<DetectedTransaction> pendingStorage = [];

  @override
  Future<bool> isPermissionGranted() async => permissionGranted;

  @override
  Future<bool> isServiceConnected() async => serviceConnected;

  @override
  Future<bool> rebindService() async {
    serviceConnected = true;
    return true;
  }

  @override
  Future<bool> isBatteryOptimizationIgnored() async => true;

  @override
  Future<void> requestIgnoreBatteryOptimization() async {}

  @override
  Future<void> openNotificationSettings() async {}

  @override
  Future<void> openAppDetailsSettings() async {}

  @override
  Future<void> sendTestNotification({String? packageName, String? title, String? text}) async {}

  @override
  Stream<DetectedTransaction> get notificationStream => const Stream.empty();

  @override
  Future<List<DetectedTransaction>> syncPendingFromNativeBuffer() async => [];

  @override
  Future<List<DetectedTransaction>> syncMissedNotifications() async {
    final list = List<DetectedTransaction>.from(missedNotificationsToReturn);
    return list;
  }

  @override
  Future<List<DetectedTransaction>> getPendingTransactions() async => List.from(pendingStorage);

  @override
  Future<void> addPendingTransaction(DetectedTransaction transaction) async {
    pendingStorage.add(transaction);
  }

  @override
  Future<void> removePendingTransaction(String id) async {
    pendingStorage.removeWhere((t) => t.id == id);
  }

  @override
  Future<void> clearPendingTransactions() async {
    pendingStorage.clear();
  }

  @override
  Future<void> markAsSaved(DetectedTransaction transaction) async {
    pendingStorage.removeWhere((t) => t.id == transaction.id);
  }

  @override
  Future<void> markAsDiscarded(DetectedTransaction transaction) async {
    pendingStorage.removeWhere((t) => t.id == transaction.id);
  }

  @override
  Future<bool> isAutoSyncEnabled() async => true;

  @override
  Future<void> setAutoSyncEnabled(bool enabled) async {}

  @override
  Future<bool> isAutoSaveEnabled() async => true;

  @override
  Future<void> setAutoSaveEnabled(bool enabled) async {}

  @override
  Future<List<String>> getEnabledBankPackages() async => [];

  @override
  Future<void> setEnabledBankPackages(List<String> packages) async {}

  final List<SwipeHistoryRecord> _swipeHistory = [];

  @override
  Future<List<SwipeHistoryRecord>> getSwipeHistory() async => List.from(_swipeHistory);

  @override
  Future<void> addSwipeHistoryRecord(SwipeHistoryRecord record) async {
    _swipeHistory.add(record);
  }

  @override
  Future<void> addSwipeHistoryRecords(List<SwipeHistoryRecord> records) async {
    _swipeHistory.addAll(records);
  }

  @override
  Future<void> clearSwipeHistory() async {
    _swipeHistory.clear();
  }

  final List<String> _dismissedBannerTransactionIds = [];

  @override
  Future<List<String>> getDismissedBannerTransactionIds() async =>
      List.from(_dismissedBannerTransactionIds);

  @override
  Future<void> saveDismissedBannerTransactionIds(List<String> ids) async {
    _dismissedBannerTransactionIds
      ..clear()
      ..addAll(ids);
  }

  @override
  Future<void> clearNativeBuffer() async {}

  @override
  Future<void> resetAllAutoSyncData() async {
    pendingStorage.clear();
    _swipeHistory.clear();
    _dismissedBannerTransactionIds.clear();
  }
}

class FakeTransactionRepository implements TransactionRepository {
  final List<TransactionEntity> storage = [];

  @override
  Future<List<TransactionEntity>> getTransactions() async => List.from(storage);

  @override
  Future<void> addTransaction(TransactionEntity transaction) async {
    storage.add(transaction);
  }

  @override
  Future<void> updateTransaction(TransactionEntity transaction) async {
    final idx = storage.indexWhere((t) => t.id == transaction.id);
    if (idx >= 0) storage[idx] = transaction;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    storage.removeWhere((t) => t.id == id);
  }

  @override
  Future<List<TransactionEntity>> getTransactionsByDateRange(DateTime start, DateTime end) async => [];

  @override
  Future<List<TransactionEntity>> getTransactionsByCategory(String categoryId) async => [];

  @override
  Future<List<TransactionEntity>> searchTransactions(String query) async => [];
}

class FakeAccountRepository implements AccountRepository {
  final List<BankAccountEntity> accounts = [];
  bool _isEyeHidden = false;

  @override
  Future<List<BankAccountEntity>> getAccounts() async => List.from(accounts);

  @override
  Future<void> saveAccounts(List<BankAccountEntity> accounts) async {
    this.accounts
      ..clear()
      ..addAll(accounts);
  }

  @override
  Future<void> saveAccount(BankAccountEntity account) async {
    accounts.add(account);
  }

  @override
  Future<void> addOrUpdateAccount(BankAccountEntity account) async {
    final idx = accounts.indexWhere((a) => a.id == account.id || (account.bankId.isNotEmpty && a.bankId == account.bankId));
    if (idx >= 0) {
      accounts[idx] = account;
    } else {
      accounts.add(account);
    }
  }

  @override
  Future<void> updateAccount(BankAccountEntity account) async {
    final idx = accounts.indexWhere((a) => a.id == account.id);
    if (idx >= 0) accounts[idx] = account;
  }

  @override
  Future<void> deleteAccount(String id) async {
    accounts.removeWhere((a) => a.id == id);
  }

  @override
  Future<BankAccountEntity?> getAccountById(String id) async {
    try {
      return accounts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<BankAccountEntity?> getAccountByBankId(String bankId) async {
    try {
      return accounts.firstWhere((a) => a.bankId == bankId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> getEyeViewPrivacy() async => _isEyeHidden;

  @override
  Future<void> setEyeViewPrivacy(bool isHidden) async {
    _isEyeHidden = isHidden;
  }
}

void main() {
  group('Manual Refresh Missed Notifications Tests', () {
    late FakeAutoSyncRepository fakeSyncRepo;
    late FakeTransactionRepository fakeTxRepo;
    late FakeAccountRepository fakeAccountRepo;
    late TransactionCubit txCubit;
    late AccountCubit accountCubit;
    late AutoSyncCubit autoSyncCubit;

    setUp(() async {
      fakeSyncRepo = FakeAutoSyncRepository();
      fakeTxRepo = FakeTransactionRepository();
      fakeAccountRepo = FakeAccountRepository();
      await fakeAccountRepo.saveAccount(
        BankAccountEntity(
          id: 'acc_kbank',
          bankId: 'kbank',
          bankName: 'ธนาคารกสิกรไทย',
          accountName: 'KBank Account',
          brandColor: 0xFF138F2D,
          isAutoSyncActive: true,
          createdAt: DateTime.now(),
        ),
      );
      txCubit = TransactionCubit(
        getTransactionsUseCase: GetTransactionsUseCase(fakeTxRepo),
        addTransactionUseCase: AddTransactionUseCase(fakeTxRepo),
        deleteTransactionUseCase: DeleteTransactionUseCase(fakeTxRepo),
        updateTransactionUseCase: UpdateTransactionUseCase(fakeTxRepo),
      );
      accountCubit = AccountCubit(repository: fakeAccountRepo);
      await accountCubit.loadAccounts();
      autoSyncCubit = AutoSyncCubit(
        repository: fakeSyncRepo,
        transactionCubit: txCubit,
        accountCubit: accountCubit,
      );
    });

    tearDown(() {
      autoSyncCubit.close();
      txCubit.close();
      accountCubit.close();
    });

    test('returns -1 when permission is not granted', () async {
      fakeSyncRepo.permissionGranted = false;
      final count = await autoSyncCubit.manualSyncMissedNotifications();
      expect(count, -1);
      expect(autoSyncCubit.state.isPermissionGranted, false);
    });

    test('successfully syncs missed notification and adds to pending', () async {
      final now = DateTime.now();
      final missed = DetectedTransaction(
        id: 'test_missed_1',
        packageName: 'com.kasikorn.bank',
        title: 'เงินโอนเข้า',
        rawText: 'เงินเข้า 1000.00 บ.',
        amount: 1000.00,
        type: TransactionType.income,
        timestamp: now,
        bankShortName: 'K PLUS',
        bankName: 'ธนาคารกสิกรไทย',
        bankId: 'kbank',
        bankColorValue: 0xFF138F2D,
        suggestedCategoryId: 'income_salary',
        suggestedCategoryName: 'เงินเดือน',
        suggestedCategoryIconCode: 0xe043,
        suggestedCategoryColorValue: 0xFF138F2D,
      );

      fakeSyncRepo.missedNotificationsToReturn = [missed];

      final count = await autoSyncCubit.manualSyncMissedNotifications();
      expect(count, 1);
      expect(autoSyncCubit.state.pendingTransactions.length, 1);
      expect(autoSyncCubit.state.pendingTransactions.first.id, 'test_missed_1');
      expect(txCubit.state.transactions.length, 1);
    });

    test('skips duplicates if already pending or already saved', () async {
      final now = DateTime.now();
      final missed = DetectedTransaction(
        id: 'test_duplicate_1',
        packageName: 'com.kasikorn.bank',
        title: 'เงินโอนเข้า',
        rawText: 'เงินเข้า 500.00 บ.',
        amount: 500.00,
        type: TransactionType.income,
        timestamp: now,
        bankShortName: 'K PLUS',
        bankName: 'ธนาคารกสิกรไทย',
        bankId: 'kbank',
        bankColorValue: 0xFF138F2D,
        suggestedCategoryId: 'income',
        suggestedCategoryName: 'รายรับ',
        suggestedCategoryIconCode: 0xe043,
        suggestedCategoryColorValue: 0xFF138F2D,
      );

      fakeSyncRepo.missedNotificationsToReturn = [missed];

      // First sync
      final firstCount = await autoSyncCubit.manualSyncMissedNotifications();
      expect(firstCount, 1);

      // Second sync with exact same notification
      final secondCount = await autoSyncCubit.manualSyncMissedNotifications();
      expect(secondCount, 0);
      expect(autoSyncCubit.state.pendingTransactions.length, 1);
      expect(txCubit.state.transactions.length, 1);
    });
  });
}
