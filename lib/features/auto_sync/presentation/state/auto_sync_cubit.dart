import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/presentation/state/transaction_cubit.dart';
import '../../../transactions/presentation/state/transaction_state.dart';
import '../../../accounts/presentation/state/account_cubit.dart';
import '../../domain/entities/bank_profile.dart';
import '../../domain/entities/detected_transaction.dart';
import '../../domain/repositories/auto_sync_repository.dart';
import '../../utils/thai_bank_parser.dart';
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
      final isTransferDetection = await repository.isTransferDetectionEnabled();
      final packages = await repository.getEnabledBankPackages();
      final pending = await repository.getPendingTransactions();

      debugPrint('[AutoSyncCubit] Initialized. isGranted=$isGranted, isConnected=$isConnected, isBatteryIgnored=$isBatteryIgnored, isAutoSync=$isAutoSync, isTransferDetection=$isTransferDetection, pendingCount=${pending.length}');

      emit(state.copyWith(
        isPermissionGranted: isGranted,
        isServiceConnected: isConnected,
        isBatteryOptimizationIgnored: isBatteryIgnored,
        isAutoSyncEnabled: isAutoSync,
        isAutoSaveEnabled: isAutoSave,
        isTransferDetectionEnabled: isTransferDetection,
        enabledBankPackages: packages,
        pendingTransactions: pending,
        isLoading: false,
      ));

      // Sync any buffered notifications from native side
      await syncNativeBuffer();


      // Start listening to real-time notification stream if enabled
      _startStreamListener();
      _startTransactionListener();
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

  /// Check if the incoming transaction matches an opposite counterpart in pending queue
  /// (e.g. KBank expense 500 & SCB income 500 within 90s, or same bank sub-accounts)
  DetectedTransaction? _findMatchingInternalTransferInPending(DetectedTransaction detected) {
    // If incoming transaction is an explicit merchant or bill payment, do not treat as self-transfer
    final isDetectedMerchant = ThaiBankParser.isExplicitMerchantOrBill('${detected.title} ${detected.rawText ?? ''}');
    if (isDetectedMerchant) return null;

    for (final tx in state.pendingTransactions) {
      if (tx.id != detected.id &&
          (tx.amount - detected.amount).abs() < 0.01 &&
          tx.type != detected.type &&
          tx.timestamp.difference(detected.timestamp).abs().inSeconds <= 90) {
        final isTxMerchant = ThaiBankParser.isExplicitMerchantOrBill('${tx.title} ${tx.rawText ?? ''}');
        if (!isTxMerchant) {
          return tx;
        }
      }
    }
    return null;
  }

  /// Check if the incoming transaction matches an opposite counterpart in saved transactions
  TransactionEntity? _findMatchingInternalTransferInCubit(DetectedTransaction detected) {
    final isDetectedMerchant = ThaiBankParser.isExplicitMerchantOrBill('${detected.title} ${detected.rawText ?? ''}');
    if (isDetectedMerchant) return null;

    for (final entity in transactionCubit.state.transactions) {
      if (entity.id != detected.id &&
          (entity.amount - detected.amount).abs() < 0.01 &&
          entity.type != detected.type &&
          entity.date.difference(detected.timestamp).abs().inSeconds <= 90) {
        final isEntityMerchant = ThaiBankParser.isExplicitMerchantOrBill('${entity.title} ${entity.note ?? ''}');
        if (!isEntityMerchant) {
          return entity;
        }
      }
    }
    return null;
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

    // 🔁 Smart Internal Transfer Detection (โอนเงินข้ามบัญชีตัวเอง)
    if (state.isTransferDetectionEnabled) {
      final matchedPending = _findMatchingInternalTransferInPending(enrichedDetected);
      final matchedEntity = matchedPending != null ? null : _findMatchingInternalTransferInCubit(enrichedDetected);

      if (matchedPending != null || matchedEntity != null) {
        final counterpartName = matchedPending?.bankShortName ?? matchedEntity!.title;
        debugPrint('[AutoSyncCubit] 🔁 Transfer Detected: ${enrichedDetected.bankShortName} ➔ $counterpartName (${enrichedDetected.amount} THB). Marking as paired transfer.');

        // Save as transfer item linked to target account
        final transferTx = enrichedDetected.toTransactionEntity().copyWith(
          type: TransactionType.transfer,
          targetAccountId: matchedPending?.bankAccountId ?? matchedEntity?.bankAccountId,
          note: 'โอนข้ามบัญชีระหว่าง ${enrichedDetected.bankShortName} และ $counterpartName',
        );
        await transactionCubit.addTransaction(transferTx);

        // Update counterpart in database if needed
        if (matchedEntity != null) {
          final updatedCounterpart = matchedEntity.copyWith(
            type: TransactionType.transfer,
            targetAccountId: account.id,
          );
          await transactionCubit.updateTransaction(updatedCounterpart);
        }

        accountCubit.refreshBalancesFromTransactions(transactionCubit.state.transactions);

        emit(state.copyWith(
          lastTransferNotice: 'ตรวจพบการโอนข้ามบัญชี ฿${enrichedDetected.amount.toStringAsFixed(2)} ระบบจัดเป็นโอนเงินข้ามบัญชี',
        ));
        return;
      }
    }

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
      final buffered = await repository.syncPendingFromNativeBuffer();
      if (buffered.isNotEmpty) {
        final remainingBuffer = <DetectedTransaction>[];
        final matchedBufferIds = <String>{};

        // Filter out internal transfer pairs in the incoming buffer
        if (state.isTransferDetectionEnabled) {
          for (int i = 0; i < buffered.length; i++) {
            if (matchedBufferIds.contains(buffered[i].id)) continue;
            bool isPair = false;
            final t1 = buffered[i];
            final isT1Merchant = ThaiBankParser.isExplicitMerchantOrBill('${t1.title} ${t1.rawText ?? ''}');

            if (!isT1Merchant) {
              for (int j = i + 1; j < buffered.length; j++) {
                if (matchedBufferIds.contains(buffered[j].id)) continue;
                final t2 = buffered[j];
                final isT2Merchant = ThaiBankParser.isExplicitMerchantOrBill('${t2.title} ${t2.rawText ?? ''}');

                if (!isT2Merchant &&
                    (t1.amount - t2.amount).abs() < 0.01 &&
                    t1.type != t2.type &&
                    t1.timestamp.difference(t2.timestamp).abs().inSeconds <= 90) {
                  debugPrint('[AutoSyncCubit] 🔁 Matched transfer pair in native buffer: ${t1.bankShortName} & ${t2.bankShortName} (${t1.amount} THB)');
                  matchedBufferIds.add(t1.id);
                  matchedBufferIds.add(t2.id);
                  await repository.markAsDiscarded(t1);
                  await repository.markAsDiscarded(t2);
                  isPair = true;
                  break;
                }
              }
            }
            if (!isPair) {
              remainingBuffer.add(buffered[i]);
            }
          }
        } else {
          remainingBuffer.addAll(buffered);
        }

        for (final tx in remainingBuffer) {
          // Check for transfer match with existing pending or saved transactions
          if (state.isTransferDetectionEnabled) {
            final matchedPending = _findMatchingInternalTransferInPending(tx);
            final matchedEntity = matchedPending != null ? null : _findMatchingInternalTransferInCubit(tx);

            if (matchedPending != null || matchedEntity != null) {
              final matchedId = matchedPending?.id ?? matchedEntity!.id;
              debugPrint('[AutoSyncCubit] 🔁 Buffer item matched existing transfer: ${tx.bankShortName} (${tx.amount} THB)');
              await transactionCubit.deleteTransaction(matchedId);
              if (matchedPending != null) {
                await repository.removePendingTransaction(matchedId);
                await repository.markAsDiscarded(matchedPending);
              }
              await repository.markAsDiscarded(tx);
              continue;
            }
          }

          final isAlreadyPending = state.pendingTransactions.any((t) =>
              t.id == tx.id ||
              (t.packageName == tx.packageName &&
                  t.amount == tx.amount &&
                  t.type == tx.type &&
                  t.timestamp.difference(tx.timestamp).abs().inSeconds < 10));

          if (!isAlreadyPending) {
            await transactionCubit.addTransaction(tx.toTransactionEntity());
            await repository.addPendingTransaction(tx);
          } else {
            debugPrint('[AutoSyncCubit] ⏭️ Duplicate transaction ignored in buffer sync: ${tx.title} ${tx.amount} THB');
          }
        }

        final updatedPending = await repository.getPendingTransactions();
        emit(state.copyWith(
          pendingTransactions: updatedPending,
          latestDetected: remainingBuffer.isNotEmpty ? remainingBuffer.last : null,
        ));
      }
    } catch (e) {
      debugPrint('[AutoSyncCubit] ❌ Error syncing native buffer: $e');
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

  Future<void> toggleTransferDetection(bool enabled) async {
    await repository.setTransferDetectionEnabled(enabled);
    emit(state.copyWith(isTransferDetectionEnabled: enabled));
  }

  void clearLastTransferNotice() {
    emit(state.copyWith(clearLastTransferNotice: true));
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
    emit(state.copyWith(
      pendingTransactions: updatedPending,
      clearLatestDetected: true,
    ));
  }

  /// User pressed "❌ ไม่ถูกต้อง" -> Delete from database!
  Future<void> discardTransaction(DetectedTransaction detected) async {
    debugPrint('[AutoSyncCubit] 🗑️ Discarding/Deleting transaction: ${detected.title} (${detected.id})');
    await transactionCubit.deleteTransaction(detected.id);
    await repository.markAsDiscarded(detected);
    final updatedPending = await repository.getPendingTransactions();
    emit(state.copyWith(
      pendingTransactions: updatedPending,
      clearLatestDetected: true,
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
    emit(state.copyWith(
      pendingTransactions: updatedPending,
      clearLatestDetected: true,
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
    emit(state.copyWith(
      pendingTransactions: updatedPending,
      clearLatestDetected: true,
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

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    _transactionSubscription?.cancel();
    return super.close();
  }
}
