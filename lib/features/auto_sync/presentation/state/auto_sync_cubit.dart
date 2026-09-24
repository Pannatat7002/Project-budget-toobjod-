import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/presentation/state/transaction_cubit.dart';
import '../../../transactions/presentation/state/transaction_state.dart';
import '../../../accounts/domain/entities/bank_account_entity.dart';
import '../../../accounts/presentation/state/account_cubit.dart';
import '../../domain/entities/bank_profile.dart';
import '../../domain/entities/detected_transaction.dart';
import '../../domain/entities/swipe_history_record.dart';
import '../../domain/repositories/auto_sync_repository.dart';
import 'auto_sync_state.dart';

class AutoSyncCubit extends Cubit<AutoSyncState> {
  final AutoSyncRepository repository;
  final TransactionCubit transactionCubit;
  final AccountCubit accountCubit;
  StreamSubscription<DetectedTransaction>? _streamSubscription;
  StreamSubscription<TransactionState>? _transactionSubscription;

  AutoSyncCubit({
    required this.repository,
    required this.transactionCubit,
    required this.accountCubit,
  }) : super(const AutoSyncState()) {
    _startTransactionListener();
  }

  Future<void> initialize() async {
    emit(state.copyWith(isLoading: true));

    try {
      final isGranted = await repository.isPermissionGranted();
      final isConnected = await repository.isServiceConnected();
      final isBatteryIgnored = await repository.isBatteryOptimizationIgnored();
      final isAutoSync = await repository.isAutoSyncEnabled();
      final isAutoSave = await repository.isAutoSaveEnabled();
      final packages = await repository.getEnabledBankPackages();
      final pending = await repository.getPendingTransactions();
      final history = await repository.getSwipeHistory();
      final dismissedBannerIds = await repository.getDismissedBannerTransactionIds();

      // Auto-backfill: Ensure all detected/pending items are in swipeHistory immediately
      final historyIds = history.map((h) => h.id).toSet();
      final missingFromHistory = pending
          .where((p) => !historyIds.contains(p.id))
          .map((p) => _buildSwipeRecord(
                detected: p,
                result: SwipeResult.confirmed,
                confirmedCategoryId: p.suggestedCategoryId,
                confirmedCategoryName: p.suggestedCategoryName,
              ))
          .toList();

      List<SwipeHistoryRecord> finalHistory = history;
      if (missingFromHistory.isNotEmpty) {
        await repository.addSwipeHistoryRecords(missingFromHistory);
        finalHistory = await repository.getSwipeHistory();
      }

      debugPrint(
        '[AutoSyncCubit] Initialized. isGranted=$isGranted, isConnected=$isConnected, isBatteryIgnored=$isBatteryIgnored, isAutoSync=$isAutoSync, pendingCount=${pending.length}, historyCount=${finalHistory.length}, dismissedBannerCount=${dismissedBannerIds.length}',
      );

      emit(
        state.copyWith(
          isPermissionGranted: isGranted,
          isServiceConnected: isConnected,
          isBatteryOptimizationIgnored: isBatteryIgnored,
          isAutoSyncEnabled: isAutoSync,
          isAutoSaveEnabled: isAutoSave,
          enabledBankPackages: packages,
          pendingTransactions: pending,
          swipeHistory: finalHistory,
          dismissedBannerTransactionIds: dismissedBannerIds,
          isLoading: false,
        ),
      );

      // Sync any buffered notifications from native side
      await syncNativeBuffer();

      // Start listening to real-time notification stream if enabled
      _startStreamListener();
      // Note: _startTransactionListener already called in constructor — do not call again
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'ไม่สามารถโหลดข้อมูลระบบตรวจจับ: $e',
        ),
      );
    }
  }

  /// Listen to TransactionCubit so any transaction deleted from TransactionsView or DashboardView
  /// is immediately removed from the pending notification drawer, bell badge, and banner!
  void _startTransactionListener() {
    _transactionSubscription?.cancel();
    _transactionSubscription = transactionCubit.stream.listen((txState) {
      if (txState.status == TransactionStatus.success &&
          state.pendingTransactions.isNotEmpty) {
        final existingTxIds = txState.transactions.map((t) => t.id).toSet();
        final toRemove = state.pendingTransactions
            .where((p) => !existingTxIds.contains(p.id))
            .toList();

        if (toRemove.isNotEmpty) {
          debugPrint(
            '[AutoSyncCubit] 🔄 Syncing deletions: ${toRemove.length} transaction(s) deleted from main list.',
          );
          for (final r in toRemove) {
            repository.removePendingTransaction(r.id);
            repository.markAsDiscarded(r);
          }

          final remaining = state.pendingTransactions
              .where((p) => existingTxIds.contains(p.id))
              .toList();

          final isLatestRemoved =
              state.latestDetected != null &&
              !existingTxIds.contains(state.latestDetected!.id);

          emit(
            state.copyWith(
              pendingTransactions: remaining,
              clearLatestDetected: isLatestRemoved,
            ),
          );
        }
      }
    });
  }

  void _startStreamListener() {
    _streamSubscription?.cancel();
    debugPrint(
      '[AutoSyncCubit] 📡 Listening to real-time notificationStream...',
    );
    _streamSubscription = repository.notificationStream.listen(
      (detected) {
        debugPrint(
          '[AutoSyncCubit] 📥 Received from stream: ${detected.bankShortName} -> ${detected.title}',
        );
        _handleIncomingDetectedTransaction(detected);
      },
      onError: (error) {
        debugPrint('[AutoSyncCubit] ❌ Stream error: $error');
      },
    );
  }

  Future<void> _handleIncomingDetectedTransaction(
    DetectedTransaction detected, {
    bool bypassFilter = false,
  }) async {
    debugPrint(
      '[AutoSyncCubit] 📲 Incoming: pkg=${detected.packageName} | bank=${detected.bankShortName} | amount=${detected.amount} | type=${detected.type.name} | id=${detected.id}',
    );

    if (!bypassFilter && !state.isAutoSyncEnabled) {
      debugPrint(
        '[AutoSyncCubit] ⏸️ Ignored: Auto-Sync is disabled in settings.',
      );
      return;
    }

    // 🔒 ธนาคารต้องเปิดดักจับก่อนเท่านั้น
    if (!bypassFilter) {
      final isEnabled = isBankSyncEnabled(
        packageName: detected.packageName,
        bankId: detected.bankId,
      );

      if (!isEnabled) {
        debugPrint(
          '[AutoSyncCubit] ❌ BLOCKED: ธนาคาร ${detected.bankShortName} (${detected.bankId}) ยังไม่ได้เปิดดักจับแจ้งเตือน (ต้องเปิดดักจับก่อนเท่านั้น)',
        );
        return;
      }
    }

    // 1. Prevent duplicate processing if already in pending list (exact ID or within 15s rapid duplicate)
    final isAlreadyPending = state.pendingTransactions.any(
      (t) =>
          t.id == detected.id ||
          (t.bankId == detected.bankId &&
              (t.amount - detected.amount).abs() < 0.001 &&
              t.type == detected.type &&
              t.timestamp.difference(detected.timestamp).abs().inSeconds < 15),
    );

    if (isAlreadyPending) {
      debugPrint(
        '[AutoSyncCubit] ⏭️ BLOCKED: already in pending queue: ${detected.title} ${detected.amount} THB (id=${detected.id})',
      );
      return;
    }

    // 2. Check if already swiped/reviewed in history (exact ID or within 15s rapid duplicate)
    final isAlreadySwiped = state.swipeHistory.any(
      (h) =>
          h.id == detected.id ||
          (h.bankShortName == detected.bankShortName &&
              (h.amount - detected.amount).abs() < 0.001 &&
              h.type == detected.type &&
              h.swipedAt.difference(detected.timestamp).abs().inSeconds < 15),
    );

    if (isAlreadySwiped) {
      debugPrint(
        '[AutoSyncCubit] ⏭️ BLOCKED: already in swipeHistory: ${detected.title} ${detected.amount} THB (id=${detected.id})',
      );
      return;
    }

    // 3. Check if already in saved transactions (exact ID or within 15s rapid duplicate)
    final isAlreadySaved = transactionCubit.state.transactions.any(
      (t) =>
          t.id == detected.id ||
          ((t.amount - detected.amount).abs() < 0.001 &&
              t.type == detected.type &&
              t.date.difference(detected.timestamp).abs().inSeconds < 15),
    );

    if (isAlreadySaved) {
      debugPrint(
        '[AutoSyncCubit] ⏭️ BLOCKED: already saved in DB: ${detected.title} ${detected.amount} THB (id=${detected.id})',
      );
      return;
    }

    // หาบัญชีธนาคารของผู้ใช้ที่มีการเพิ่มไว้และเปิดดักจับอยู่ (ไม่สร้างบัญชีเองอัตโนมัติ)
    final matchingAccounts = accountCubit.state.accounts.where(
      (a) => a.bankId == detected.bankId && a.isAutoSyncActive,
    ).toList();

    if (matchingAccounts.isEmpty) {
      debugPrint(
        '[AutoSyncCubit] ❌ BLOCKED: ไม่พบบัญชีธนาคารสำหรับ ${detected.bankShortName} (${detected.bankId}) ที่เปิดใช้งานดักจับ (ต้องเพิ่มธนาคารก่อน)',
      );
      return;
    }

    BankAccountEntity account = matchingAccounts.first;
    if (detected.accountMask != null) {
      final maskMatch = matchingAccounts.where((a) => a.accountMask == detected.accountMask).firstOrNull;
      if (maskMatch != null) {
        account = maskMatch;
      }
    }

    final enrichedDetected = detected.copyWith(
      bankAccountId: account.id,
      bankId: account.bankId,
    );

    // ⚡ Always auto-save transaction to database immediately
    debugPrint(
      '[AutoSyncCubit] ⚡ Auto-saved transaction: ${enrichedDetected.bankShortName} ${enrichedDetected.amount} THB (Account: ${account.accountName})',
    );
    await transactionCubit.addTransaction(
      enrichedDetected.toTransactionEntity(),
    );

    // Refresh bank balances
    accountCubit.refreshBalancesFromTransactions(
      transactionCubit.state.transactions,
    );

    // Add to pending review queue
    await repository.addPendingTransaction(enrichedDetected);

    // 📋 บันทึกลงประวัติการตรวจจับทันที
    final record = _buildSwipeRecord(
      detected: enrichedDetected,
      result: SwipeResult.confirmed,
      confirmedCategoryId: enrichedDetected.suggestedCategoryId,
      confirmedCategoryName: enrichedDetected.suggestedCategoryName,
    );
    await repository.addSwipeHistoryRecord(record);

    final updatedPending = await repository.getPendingTransactions();
    final updatedHistory = await repository.getSwipeHistory();
    emit(
      state.copyWith(
        pendingTransactions: updatedPending,
        swipeHistory: updatedHistory,
        latestDetected: enrichedDetected,
        isDashboardBannerDismissed: false,
      ),
    );
  }

  Future<void> syncNativeBuffer() async {
    try {
      // ดึงแจ้งเตือนที่ตกหล่นอัตโนมัติ (ทั้งจาก active notifications บนแถบสถานะ และ native buffer)
      await manualSyncMissedNotifications();
    } catch (e) {
      debugPrint('[AutoSyncCubit] ❌ Error syncing native buffer: $e');
    }
  }

  /// ดึงการแจ้งเตือนที่ตกหล่นด้วยตนเอง (Active status bar notifications + buffer)
  /// คืนค่าจำนวนรายการใหม่ที่ดึงเข้ามาได้สำเร็จ หรือ -1 หากไม่มีสิทธิ์ Notification Access
  Future<int> manualSyncMissedNotifications() async {
    emit(state.copyWith(isLoading: true));
    try {
      final isGranted = await repository.isPermissionGranted();
      if (!isGranted) {
        emit(state.copyWith(isLoading: false, isPermissionGranted: false));
        return -1;
      }

      // Rebind service if currently disconnected
      final isConnected = await repository.isServiceConnected();
      if (!isConnected) {
        debugPrint(
          '[AutoSyncCubit] 🔄 Service disconnected before manual sync. Forcing rebind...',
        );
        await repository.rebindService();
        await Future.delayed(const Duration(milliseconds: 600));
      }

      // Fetch missed notifications from native
      final missed = await repository.syncMissedNotifications();
      debugPrint(
        '[AutoSyncCubit] 📬 Native returned ${missed.length} notification(s)',
      );

      int newlyAddedCount = 0;

      if (missed.isNotEmpty) {
        for (final tx in missed) {
          // 🔒 ธนาคารต้องเปิดดักจับก่อนเท่านั้น
          final isEnabled = isBankSyncEnabled(
            packageName: tx.packageName,
            bankId: tx.bankId,
          );

          if (!isEnabled) {
            debugPrint(
              '[AutoSyncCubit] ⏭️ Skipping ${tx.packageName} / ${tx.bankShortName} (ธนาคารยังไม่ได้เปิดดักจับ)',
            );
            continue;
          }

          // Deduplication: exact ID match only.
          // ไม่ใช้ fuzzy match (amount+type+time) เพราะอาจตัดธุรกรรมจริงที่ยอดเหมือนกันออกไปผิดพลาด
          // 1. Pending queue
          if (state.pendingTransactions.any((p) => p.id == tx.id)) {
            debugPrint('[AutoSyncCubit] ⏭️ Already pending (id match): ${tx.id}');
            continue;
          }

          // 2. Swipe history
          if (state.swipeHistory.any((h) => h.id == tx.id)) {
            debugPrint('[AutoSyncCubit] ⏭️ Already swiped (id match): ${tx.id}');
            continue;
          }

          // 3. Saved transactions DB
          if (transactionCubit.state.transactions.any((t) => t.id == tx.id)) {
            debugPrint('[AutoSyncCubit] ⏭️ Already saved (id match): ${tx.id}');
            continue;
          }

          final matchingAccounts = accountCubit.state.accounts.where(
            (a) => a.bankId == tx.bankId && a.isAutoSyncActive,
          ).toList();

          if (matchingAccounts.isEmpty) {
            debugPrint(
              '[AutoSyncCubit] ⏭️ Skipping ${tx.packageName} / ${tx.bankShortName} (ยังไม่ได้เพิ่มบัญชีธนาคารนี้)',
            );
            continue;
          }

          BankAccountEntity acc = matchingAccounts.first;
          if (tx.accountMask != null) {
            final maskMatch = matchingAccounts.where((a) => a.accountMask == tx.accountMask).firstOrNull;
            if (maskMatch != null) {
              acc = maskMatch;
            }
          }

          final enriched = tx.copyWith(
            bankAccountId: acc.id,
            bankId: acc.bankId,
          );

          await transactionCubit.addTransaction(enriched.toTransactionEntity());
          await repository.addPendingTransaction(enriched);

          // 📋 บันทึกลงประวัติการตรวจจับ
          final record = _buildSwipeRecord(
            detected: enriched,
            result: SwipeResult.confirmed,
            confirmedCategoryId: enriched.suggestedCategoryId,
            confirmedCategoryName: enriched.suggestedCategoryName,
          );
          await repository.addSwipeHistoryRecord(record);
          newlyAddedCount++;
        }

        if (newlyAddedCount > 0) {
          accountCubit.refreshBalancesFromTransactions(
            transactionCubit.state.transactions,
          );
        }
      }

      final updatedPending = await repository.getPendingTransactions();
      final updatedHistory = await repository.getSwipeHistory();
      final nowConnected = await repository.isServiceConnected();

      emit(
        state.copyWith(
          isLoading: false,
          isPermissionGranted: true,
          isServiceConnected: nowConnected,
          pendingTransactions: updatedPending,
          swipeHistory: updatedHistory,
          latestDetected: updatedPending.isNotEmpty
              ? updatedPending.first
              : null,
        ),
      );

      return newlyAddedCount;
    } catch (e) {
      debugPrint(
        '[AutoSyncCubit] ❌ Error in manualSyncMissedNotifications: $e',
      );
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'ไม่สามารถดึงแจ้งเตือนที่ตกหล่นได้: $e',
        ),
      );
      return 0;
    }
  }

  Future<void> checkPermission() async {
    final isGranted = await repository.isPermissionGranted();
    final isConnected = await repository.isServiceConnected();
    final isBatteryIgnored = await repository.isBatteryOptimizationIgnored();

    emit(
      state.copyWith(
        isPermissionGranted: isGranted,
        isServiceConnected: isConnected,
        isBatteryOptimizationIgnored: isBatteryIgnored,
      ),
    );

    if (isGranted) {
      await syncNativeBuffer();
    }
  }

  /// Force rebind the notification listener service (Fix background connection drops)
  Future<bool> forceRebindService() async {
    final success = await repository.rebindService();
    // Wait a brief moment for OS to bind
    await Future.delayed(const Duration(milliseconds: 600));
    final isConnected = await repository.isServiceConnected();
    emit(state.copyWith(isServiceConnected: isConnected));
    return success;
  }

  Future<void> requestIgnoreBatteryOptimization() async {
    await repository.requestIgnoreBatteryOptimization();
    final isBatteryIgnored = await repository.isBatteryOptimizationIgnored();
    emit(state.copyWith(isBatteryOptimizationIgnored: isBatteryIgnored));
  }

  Future<void> sendTestNotification({
    String? packageName,
    String? title,
    String? text,
  }) async {
    await repository.sendTestNotification(
      packageName: packageName,
      title: title,
      text: text,
    );
  }

  Future<void> openNotificationSettings() async {
    await repository.openNotificationSettings();
  }

  Future<void> openAppDetailsSettings() async {
    await repository.openAppDetailsSettings();
  }

  Future<void> toggleAutoSync(bool enabled) async {
    await repository.setAutoSyncEnabled(enabled);
    emit(state.copyWith(isAutoSyncEnabled: enabled));
  }

  Future<void> toggleAutoSave(bool enabled) async {
    await repository.setAutoSaveEnabled(enabled);
    emit(state.copyWith(isAutoSaveEnabled: enabled));
  }

  Future<void> toggleBankPackage(String packageName, bool enabled) async {
    final current = List<String>.from(
      state.enabledBankPackages.isEmpty && !enabled
          ? BankProfile.allSupportedPackages
          : state.enabledBankPackages,
    );
    if (enabled) {
      if (!current.contains(packageName)) current.add(packageName);
    } else {
      current.remove(packageName);
    }
    await repository.setEnabledBankPackages(current);
    emit(state.copyWith(enabledBankPackages: current));
  }

  /// Atomically toggle a bank and all its package aliases
  Future<void> toggleBankProfile(BankProfile profile, bool enabled) async {
    final current = List<String>.from(
      state.enabledBankPackages.isEmpty && !enabled
          ? BankProfile.allSupportedPackages
          : state.enabledBankPackages,
    );
    final allForBank = [profile.packageName, ...profile.packageAliases];
    if (enabled) {
      for (final pkg in allForBank) {
        if (!current.contains(pkg)) current.add(pkg);
      }
    } else {
      current.removeWhere((pkg) => allForBank.contains(pkg));
    }
    await repository.setEnabledBankPackages(current);
    emit(state.copyWith(enabledBankPackages: current));
  }

  /// ตรวจสอบว่าธนาคารนี้เปิดระบบดักจับแจ้งเตือนไว้หรือไม่ (ต้องทำการเพิ่มธนาคารและเปิดดักจับก่อนเท่านั้น)
  bool isBankSyncEnabled({required String packageName, required String bankId}) {
    if (packageName == 'com.android.shell') {
      final userAccounts = accountCubit.state.accounts;
      if (userAccounts.any((acc) => acc.bankId == bankId && acc.isAutoSyncActive)) {
        return true;
      }
      return state.enabledBankPackages.contains(packageName);
    }

    // 🔒 1. ตรวจสอบว่าผู้ใช้ได้เพิ่มบัญชีธนาคารนี้ในระบบ และเปิดสวิตช์ดักจับ (isAutoSyncActive: true) หรือไม่
    final userAccounts = accountCubit.state.accounts;
    final hasActiveAccount = userAccounts.any(
      (acc) => acc.bankId == bankId && acc.isAutoSyncActive,
    );

    if (!hasActiveAccount) {
      return false; // ยังไม่ได้เพิ่มธนาคาร หรือปิดดักจับไว้ -> ไม่อนุญาตให้ดักจับ
    }

    // 2. ถ้ามีการระบุ enabledBankPackages ให้ตรวจเช็คควบคู่กัน
    if (state.enabledBankPackages.isNotEmpty) {
      final isDirectlyEnabled = state.enabledBankPackages.contains(packageName);
      final profile = BankProfile.findById(bankId) ?? BankProfile.findByPackage(packageName);
      final isProfileEnabled = profile != null &&
          (state.enabledBankPackages.contains(profile.packageName) ||
              profile.packageAliases.any((a) => state.enabledBankPackages.contains(a)));
      return isDirectlyEnabled || isProfileEnabled;
    }

    return true;
  }

  Future<void> toggleAllBankPackages(bool enableAll) async {
    final newPackages = enableAll
        ? BankProfile.allSupportedPackages
        : <String>[];
    await repository.setEnabledBankPackages(newPackages);
    emit(state.copyWith(enabledBankPackages: newPackages));
  }

  /// User confirmed "✅ ถูกต้อง"
  Future<void> confirmTransaction(
    DetectedTransaction detected, {
    TransactionEntity? customEntity,
  }) async {
    // If user edited title/category, update the saved transaction
    if (customEntity != null) {
      await transactionCubit.updateTransaction(customEntity);
    }
    await repository.markAsSaved(detected);
    final updatedPending = await repository.getPendingTransactions();

    // 📋 บันทึกประวัติการปัด
    final record = _buildSwipeRecord(
      detected: detected,
      result: SwipeResult.confirmed,
      confirmedCategoryId:
          customEntity?.categoryId ?? detected.suggestedCategoryId,
      confirmedCategoryName:
          customEntity?.categoryName ?? detected.suggestedCategoryName,
    );

    await repository.addSwipeHistoryRecord(record);

    emit(
      state.copyWith(
        pendingTransactions: updatedPending,
        clearLatestDetected: true,
        swipeHistory: [record, ...state.swipeHistory.where((r) => r.id != record.id)],
      ),
    );
  }

  /// User pressed "❌ ไม่ถูกต้อง" -> Delete from database!
  Future<void> discardTransaction(DetectedTransaction detected) async {
    debugPrint(
      '[AutoSyncCubit] 🗑️ Discarding/Deleting transaction: ${detected.title} (${detected.id})',
    );
    await transactionCubit.deleteTransaction(detected.id);
    await repository.markAsDiscarded(detected);
    final updatedPending = await repository.getPendingTransactions();

    // 📋 บันทึกประวัติการปัด
    final record = _buildSwipeRecord(
      detected: detected,
      result: SwipeResult.discarded,
      confirmedCategoryId: detected.suggestedCategoryId,
      confirmedCategoryName: detected.suggestedCategoryName,
    );

    await repository.addSwipeHistoryRecord(record);

    emit(
      state.copyWith(
        pendingTransactions: updatedPending,
        clearLatestDetected: true,
        swipeHistory: [record, ...state.swipeHistory.where((r) => r.id != record.id)],
      ),
    );
  }

  /// Dismisses only the Dashboard banner card for all current pending transactions
  /// It persists the dismissed IDs so it will NOT show again on app reopen/refresh,
  /// UNLESS a new transaction is detected!
  Future<void> dismissDashboardBanner() async {
    final currentPendingIds = state.pendingTransactions.map((t) => t.id).toList();
    final updatedDismissed = {...state.dismissedBannerTransactionIds, ...currentPendingIds}.toList();
    await repository.saveDismissedBannerTransactionIds(updatedDismissed);
    emit(
      state.copyWith(
        isDashboardBannerDismissed: true,
        dismissedBannerTransactionIds: updatedDismissed,
      ),
    );
  }

  /// User dismissed / closed dialog -> Keep auto-saved transaction
  Future<void> dismissReview(DetectedTransaction detected) async {
    debugPrint(
      '[AutoSyncCubit] 💾 Dismissed review: keeping auto-saved transaction: ${detected.title}',
    );
    await repository.markAsSaved(detected);
    final updatedPending = await repository.getPendingTransactions();
    emit(
      state.copyWith(
        pendingTransactions: updatedPending,
        clearLatestDetected: true,
      ),
    );
  }

  /// Confirm / Keep all remaining pending reviews
  Future<void> confirmAllPending() async {
    final pending = List<DetectedTransaction>.from(state.pendingTransactions);
    for (final tx in pending) {
      await repository.markAsSaved(tx);
    }
    final updatedPending = await repository.getPendingTransactions();

    // 📋 บันทึกประวัติการปัดแบบ bulk
    final newRecords = pending
        .map(
          (tx) => _buildSwipeRecord(
            detected: tx,
            result: SwipeResult.confirmed,
            confirmedCategoryId: tx.suggestedCategoryId,
            confirmedCategoryName: tx.suggestedCategoryName,
          ),
        )
        .toList();

    await repository.addSwipeHistoryRecords(newRecords);
    final currentSwipeHistory = await repository.getSwipeHistory();

    emit(
      state.copyWith(
        pendingTransactions: updatedPending,
        clearLatestDetected: true,
        swipeHistory: currentSwipeHistory,
      ),
    );
  }

  /// Discard and delete all remaining pending reviews from database
  Future<void> discardAllPending() async {
    final pending = List<DetectedTransaction>.from(state.pendingTransactions);
    for (final tx in pending) {
      await transactionCubit.deleteTransaction(tx.id);
      await repository.markAsDiscarded(tx);
    }
    final updatedPending = await repository.getPendingTransactions();

    // 📋 บันทึกประวัติการปัดแบบ bulk
    final newRecords = pending
        .map(
          (tx) => _buildSwipeRecord(
            detected: tx,
            result: SwipeResult.discarded,
            confirmedCategoryId: tx.suggestedCategoryId,
            confirmedCategoryName: tx.suggestedCategoryName,
          ),
        )
        .toList();

    await repository.addSwipeHistoryRecords(newRecords);
    final currentSwipeHistory = await repository.getSwipeHistory();

    emit(
      state.copyWith(
        pendingTransactions: updatedPending,
        clearLatestDetected: true,
        swipeHistory: currentSwipeHistory,
      ),
    );
  }

  /// Clear all pending notifications directly
  Future<void> clearAllPending() async {
    await repository.clearPendingTransactions();
    await repository.clearNativeBuffer();
    emit(state.copyWith(pendingTransactions: [], clearLatestDetected: true));
  }

  void clearLatestDetected() {
    emit(state.copyWith(clearLatestDetected: true));
  }

  /// Clear swipe history
  Future<void> clearSwipeHistory() async {
    await repository.clearSwipeHistory();
    emit(state.copyWith(swipeHistory: []));
  }

  /// Complete reset of all auto-sync data (RAM caches, DB, native buffers)
  Future<void> clearAllData() async {
    await repository.resetAllAutoSyncData();
    emit(
      state.copyWith(
        pendingTransactions: [],
        swipeHistory: [],
        clearLatestDetected: true,
        dismissedBannerTransactionIds: [],
        isDashboardBannerDismissed: false,
      ),
    );
  }

  /// Helper: สร้าง SwipeHistoryRecord จาก DetectedTransaction
  SwipeHistoryRecord _buildSwipeRecord({
    required DetectedTransaction detected,
    required SwipeResult result,
    required String confirmedCategoryId,
    required String confirmedCategoryName,
  }) {
    return SwipeHistoryRecord(
      id: detected.id,
      swipedAt: DateTime.now(),
      title: detected.title,
      bankShortName: detected.bankShortName,
      type: detected.type,
      amount: detected.amount,
      suggestedCategoryId: detected.suggestedCategoryId,
      suggestedCategoryName: detected.suggestedCategoryName,
      confirmedCategoryId: confirmedCategoryId,
      confirmedCategoryName: confirmedCategoryName,
      swipeResult: result,
      rawText: detected.rawText,
    );
  }

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    _transactionSubscription?.cancel();
    return super.close();
  }
}
