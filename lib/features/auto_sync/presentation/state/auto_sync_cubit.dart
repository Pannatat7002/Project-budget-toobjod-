import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/presentation/state/transaction_cubit.dart';
import '../../../transactions/presentation/state/transaction_state.dart';
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

      debugPrint('[AutoSyncCubit] Initialized. isGranted=$isGranted, isConnected=$isConnected, isBatteryIgnored=$isBatteryIgnored, isAutoSync=$isAutoSync, pendingCount=${pending.length}');

      emit(state.copyWith(
        isPermissionGranted: isGranted,
        isServiceConnected: isConnected,
        isBatteryOptimizationIgnored: isBatteryIgnored,
        isAutoSyncEnabled: isAutoSync,
        isAutoSaveEnabled: isAutoSave,
        enabledBankPackages: packages,
        pendingTransactions: pending,
        isLoading: false,
      ));

      // Sync any buffered notifications from native side
      await syncNativeBuffer();


      // Start listening to real-time notification stream if enabled
      _startStreamListener();
      // Note: _startTransactionListener already called in constructor — do not call again
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'ไม่สามารถโหลดข้อมูลระบบตรวจจับ: $e',
      ));
    }
  }

  /// Listen to TransactionCubit so any transaction deleted from TransactionsView or DashboardView
  /// is immediately removed from the pending notification drawer, bell badge, and banner!
  void _startTransactionListener() {
    _transactionSubscription?.cancel();
    _transactionSubscription = transactionCubit.stream.listen((txState) {
      if (txState.status == TransactionStatus.success && state.pendingTransactions.isNotEmpty) {
        final existingTxIds = txState.transactions.map((t) => t.id).toSet();
        final toRemove = state.pendingTransactions
            .where((p) => !existingTxIds.contains(p.id))
            .toList();

        if (toRemove.isNotEmpty) {
          debugPrint('[AutoSyncCubit] 🔄 Syncing deletions: ${toRemove.length} transaction(s) deleted from main list.');
          for (final r in toRemove) {
            repository.removePendingTransaction(r.id);
            repository.markAsDiscarded(r);
          }

          final remaining = state.pendingTransactions
              .where((p) => existingTxIds.contains(p.id))
              .toList();

          final isLatestRemoved = state.latestDetected != null &&
              !existingTxIds.contains(state.latestDetected!.id);

          emit(state.copyWith(
            pendingTransactions: remaining,
            clearLatestDetected: isLatestRemoved,
          ));
        }
      }
    });
  }

  void _startStreamListener() {
    _streamSubscription?.cancel();
    debugPrint('[AutoSyncCubit] 📡 Listening to real-time notificationStream...');
    _streamSubscription = repository.notificationStream.listen(
      (detected) {
        debugPrint('[AutoSyncCubit] 📥 Received from stream: ${detected.bankShortName} -> ${detected.title}');
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
    if (!bypassFilter && !state.isAutoSyncEnabled) {
      debugPrint('[AutoSyncCubit] ⏸️ Ignored: Auto-Sync is disabled in settings.');
      return;
    }

    // Check if package is enabled in user settings
    if (!bypassFilter && state.enabledBankPackages.isNotEmpty) {
      final isShell = detected.packageName == 'com.android.shell';
      final isDirectlyEnabled = state.enabledBankPackages.contains(detected.packageName);
      final profile = BankProfile.findByPackage(detected.packageName);
      final isProfileEnabled = profile != null && (
          state.enabledBankPackages.contains(profile.packageName) ||
          profile.packageAliases.any((a) => state.enabledBankPackages.contains(a))
      );

      if (!isShell && !isDirectlyEnabled && !isProfileEnabled) {
        debugPrint('[AutoSyncCubit] ⏸️ Ignored: Package ${detected.packageName} is disabled in bank filter.');
        return;
      }
    }

    // Prevent duplicate processing if already in pending list (per bank & per amount)
    final isAlreadyPending = state.pendingTransactions.any((t) =>
        t.id == detected.id ||
        (t.bankId == detected.bankId &&
            t.amount == detected.amount &&
            t.type == detected.type &&
            t.timestamp.difference(detected.timestamp).abs().inSeconds < 15));

    if (isAlreadyPending) {
      debugPrint('[AutoSyncCubit] ⏭️ Duplicate transaction ignored in stream: ${detected.title} ${detected.amount} THB');
      return;
    }

    // Auto-discover / ensure account exists for this bank
    final account = await accountCubit.ensureAccountForBank(
      detected.bankId,
      accountMask: detected.accountMask,
      bankName: detected.bankName,
      brandColor: detected.bankColorValue,
    );

    final enrichedDetected = detected.copyWith(
      bankAccountId: account.id,
      bankId: account.bankId,
    );


    // ⚡ Always auto-save transaction to database immediately
    debugPrint('[AutoSyncCubit] ⚡ Auto-saved transaction: ${enrichedDetected.bankShortName} ${enrichedDetected.amount} THB (Account: ${account.accountName})');
    await transactionCubit.addTransaction(enrichedDetected.toTransactionEntity());

    // Refresh bank balances
    accountCubit.refreshBalancesFromTransactions(transactionCubit.state.transactions);

    // Add to pending review queue
    await repository.addPendingTransaction(enrichedDetected);
    final updatedPending = await repository.getPendingTransactions();
    emit(state.copyWith(
      pendingTransactions: updatedPending,
      latestDetected: enrichedDetected,
    ));
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
        emit(state.copyWith(
          isLoading: false,
          isPermissionGranted: false,
        ));
        return -1;
      }

      // Rebind service if currently disconnected
      final isConnected = await repository.isServiceConnected();
      if (!isConnected) {
        debugPrint('[AutoSyncCubit] 🔄 Service disconnected before manual sync. Forcing rebind...');
        await repository.rebindService();
        await Future.delayed(const Duration(milliseconds: 600));
      }

      // Fetch missed notifications from native
      final missed = await repository.syncMissedNotifications();
      debugPrint('[AutoSyncCubit] 📬 Native returned ${missed.length} notification(s)');

      int newlyAddedCount = 0;

      if (missed.isNotEmpty) {
        for (final tx in missed) {
          // Check bank package filter (if user configured specific banks)
          if (state.enabledBankPackages.isNotEmpty) {
            final isShell = tx.packageName == 'com.android.shell';
            final isDirectlyEnabled = state.enabledBankPackages.contains(tx.packageName);
            final profile = BankProfile.findByPackage(tx.packageName);
            final isProfileEnabled = profile != null && (
                state.enabledBankPackages.contains(profile.packageName) ||
                profile.packageAliases.any((a) => state.enabledBankPackages.contains(a))
            );

            if (!isShell && !isDirectlyEnabled && !isProfileEnabled) {
              debugPrint('[AutoSyncCubit] ⏭️ Skipping ${tx.packageName} (disabled by filter)');
              continue;
            }
          }

          // Deduplication:
          // 1. Check in pendingTransactions
          final isAlreadyPending = state.pendingTransactions.any((p) =>
              p.id == tx.id ||
              (p.packageName == tx.packageName &&
               p.amount == tx.amount &&
               p.type == tx.type &&
               p.timestamp.difference(tx.timestamp).abs().inSeconds < 15));

          if (isAlreadyPending) {
            debugPrint('[AutoSyncCubit] ⏭️ Already pending in review: ${tx.bankShortName} ${tx.amount} THB');
            continue;
          }

          // 2. Check in swipe history (already swiped/reviewed in this session)
          final isAlreadySwiped = state.swipeHistory.any((h) => h.id == tx.id);
          if (isAlreadySwiped) {
            debugPrint('[AutoSyncCubit] ⏭️ Already swiped in history: ${tx.bankShortName} ${tx.amount} THB');
            continue;
          }

          // 3. Check in saved transactions
          final isAlreadySaved = transactionCubit.state.transactions.any((t) =>
              t.id == tx.id ||
              (t.amount == tx.amount &&
               t.type == tx.type &&
               t.date.difference(tx.timestamp).abs().inMinutes < 2));

          final acc = await accountCubit.ensureAccountForBank(
            tx.bankId,
            accountMask: tx.accountMask,
            bankName: tx.bankName,
            brandColor: tx.bankColorValue,
          );

          final enriched = tx.copyWith(
            bankAccountId: acc.id,
            bankId: acc.bankId,
          );

          if (!isAlreadySaved) {
            await transactionCubit.addTransaction(enriched.toTransactionEntity());
          } else {
            debugPrint('[AutoSyncCubit] ℹ️ Transaction already saved in DB, adding to pending review: ${tx.bankShortName} ${tx.amount} THB');
          }

          await repository.addPendingTransaction(enriched);
          newlyAddedCount++;
        }

        if (newlyAddedCount > 0) {
          accountCubit.refreshBalancesFromTransactions(transactionCubit.state.transactions);
        }
      }

      final updatedPending = await repository.getPendingTransactions();
      final nowConnected = await repository.isServiceConnected();

      emit(state.copyWith(
        isLoading: false,
        isPermissionGranted: true,
        isServiceConnected: nowConnected,
        pendingTransactions: updatedPending,
        latestDetected: updatedPending.isNotEmpty ? updatedPending.first : null,
      ));

      return newlyAddedCount;
    } catch (e) {
      debugPrint('[AutoSyncCubit] ❌ Error in manualSyncMissedNotifications: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'ไม่สามารถดึงแจ้งเตือนที่ตกหล่นได้: $e',
      ));
      return 0;
    }
  }

  Future<void> checkPermission() async {
    final isGranted = await repository.isPermissionGranted();
    final isConnected = await repository.isServiceConnected();
    final isBatteryIgnored = await repository.isBatteryOptimizationIgnored();

    emit(state.copyWith(
      isPermissionGranted: isGranted,
      isServiceConnected: isConnected,
      isBatteryOptimizationIgnored: isBatteryIgnored,
    ));

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
    final current = List<String>.from(state.enabledBankPackages);
    if (enabled) {
      if (!current.contains(packageName)) current.add(packageName);
    } else {
      current.remove(packageName);
    }
    await repository.setEnabledBankPackages(current);
    emit(state.copyWith(enabledBankPackages: current));
  }

  Future<void> toggleAllBankPackages(bool enableAll) async {
    final newPackages = enableAll
        ? BankProfile.supportedBanks.map((b) => b.packageName).toList()
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
      confirmedCategoryId: customEntity?.categoryId ?? detected.suggestedCategoryId,
      confirmedCategoryName: customEntity?.categoryName ?? detected.suggestedCategoryName,
    );

    emit(state.copyWith(
      pendingTransactions: updatedPending,
      clearLatestDetected: true,
      swipeHistory: [...state.swipeHistory, record],
    ));
  }

  /// User pressed "❌ ไม่ถูกต้อง" -> Delete from database!
  Future<void> discardTransaction(DetectedTransaction detected) async {
    debugPrint('[AutoSyncCubit] 🗑️ Discarding/Deleting transaction: ${detected.title} (${detected.id})');
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

    emit(state.copyWith(
      pendingTransactions: updatedPending,
      clearLatestDetected: true,
      swipeHistory: [...state.swipeHistory, record],
    ));
  }

  /// User dismissed / closed dialog -> Keep auto-saved transaction
  Future<void> dismissReview(DetectedTransaction detected) async {
    debugPrint('[AutoSyncCubit] 💾 Dismissed review: keeping auto-saved transaction: ${detected.title}');
    await repository.markAsSaved(detected);
    final updatedPending = await repository.getPendingTransactions();
    emit(state.copyWith(
      pendingTransactions: updatedPending,
      clearLatestDetected: true,
    ));
  }

  /// Confirm / Keep all remaining pending reviews
  Future<void> confirmAllPending() async {
    final pending = List<DetectedTransaction>.from(state.pendingTransactions);
    for (final tx in pending) {
      await repository.markAsSaved(tx);
    }
    final updatedPending = await repository.getPendingTransactions();

    // 📋 บันทึกประวัติการปัดแบบ bulk
    final newRecords = pending.map((tx) => _buildSwipeRecord(
      detected: tx,
      result: SwipeResult.confirmed,
      confirmedCategoryId: tx.suggestedCategoryId,
      confirmedCategoryName: tx.suggestedCategoryName,
    )).toList();

    emit(state.copyWith(
      pendingTransactions: updatedPending,
      clearLatestDetected: true,
      swipeHistory: [...state.swipeHistory, ...newRecords],
    ));
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
    final newRecords = pending.map((tx) => _buildSwipeRecord(
      detected: tx,
      result: SwipeResult.discarded,
      confirmedCategoryId: tx.suggestedCategoryId,
      confirmedCategoryName: tx.suggestedCategoryName,
    )).toList();

    emit(state.copyWith(
      pendingTransactions: updatedPending,
      clearLatestDetected: true,
      swipeHistory: [...state.swipeHistory, ...newRecords],
    ));
  }

  /// Clear all pending notifications directly
  Future<void> clearAllPending() async {
    await repository.clearPendingTransactions();
    emit(state.copyWith(
      pendingTransactions: [],
      clearLatestDetected: true,
    ));
  }

  void clearLatestDetected() {
    emit(state.copyWith(clearLatestDetected: true));
  }

  /// Clear swipe history
  void clearSwipeHistory() {
    emit(state.copyWith(swipeHistory: []));
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
