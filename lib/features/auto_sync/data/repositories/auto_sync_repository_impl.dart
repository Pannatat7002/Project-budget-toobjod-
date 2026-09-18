import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/bank_profile.dart';
import '../../domain/entities/detected_transaction.dart';
import '../../domain/repositories/auto_sync_repository.dart';
import '../../utils/thai_bank_parser.dart';
import '../datasources/auto_sync_local_data_source.dart';

class AutoSyncRepositoryImpl implements AutoSyncRepository {
  final AutoSyncLocalDataSource localDataSource;

  static const MethodChannel _methodChannel =
      MethodChannel('com.toobjod.budgetPlanner/notification_channel');
  static const EventChannel _eventChannel =
      EventChannel('com.toobjod.budgetPlanner/notification_stream');

  Stream<DetectedTransaction>? _stream;

  AutoSyncRepositoryImpl({required this.localDataSource});

  @override
  Future<bool> isPermissionGranted() async {
    try {
      final bool? isGranted =
          await _methodChannel.invokeMethod<bool>('isPermissionGranted');
      return isGranted ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isServiceConnected() async {
    try {
      final bool? connected =
          await _methodChannel.invokeMethod<bool>('isServiceConnected');
      return connected ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> rebindService() async {
    try {
      final bool? success =
          await _methodChannel.invokeMethod<bool>('rebindService');
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isBatteryOptimizationIgnored() async {
    try {
      final bool? ignored =
          await _methodChannel.invokeMethod<bool>('isBatteryOptimizationIgnored');
      return ignored ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> requestIgnoreBatteryOptimization() async {
    try {
      await _methodChannel.invokeMethod('requestIgnoreBatteryOptimization');
    } catch (_) {}
  }

  @override
  Future<void> sendTestNotification({
    String? packageName,
    String? title,
    String? text,
  }) async {
    try {
      await _methodChannel.invokeMethod('sendTestNotification', {
        'packageName': packageName ?? 'com.kasikorn.retail.mbanking.wap',
        'title': title ?? 'K PLUS',
        'text': text ?? 'เงินเข้า 500.00 บ. โอนจาก x-9999',
      });
    } catch (_) {}
  }

  @override
  Future<void> openNotificationSettings() async {
    try {
      await _methodChannel.invokeMethod('openNotificationSettings');
    } catch (_) {}
  }

  @override
  Future<void> openAppDetailsSettings() async {
    try {
      await _methodChannel.invokeMethod('openAppDetailsSettings');
    } catch (_) {}
  }

  @override
  Stream<DetectedTransaction> get notificationStream {
    if (kIsWeb) {
      return const Stream.empty();
    }
    _stream ??= _eventChannel
        .receiveBroadcastStream()
        .where((event) => event is Map)
        .map((event) {
          final map = Map<String, dynamic>.from(event as Map);
          final id = map['id'] as String?;
          final packageName = map['packageName'] as String? ?? '';
          final title = map['title'] as String? ?? '';
          final text = map['text'] as String? ?? '';
          final subText = map['subText'] as String?;
          final postTime = map['postTime'] as int?;

          debugPrint('[AutoSync] 🔔 Event received from Native: pkg=$packageName, title="$title", text="$text"');

          final date = postTime != null && postTime > 0
              ? DateTime.fromMillisecondsSinceEpoch(postTime)
              : DateTime.now();

          final detected = ThaiBankParser.parse(
            id: id,
            packageName: packageName,
            title: title,
            text: text,
            subText: subText,
            timestamp: date,
          );

          if (detected != null) {
            debugPrint('[AutoSync] ✨ Successfully parsed: ${detected.bankShortName} | ${detected.type.name.toUpperCase()} ${detected.amount} THB | "${detected.title}"');
          } else {
            debugPrint('[AutoSync] ⚠️ Not parsed as bank transaction: title="$title", text="$text"');
          }

          return detected;
        })
        .where((detected) => detected != null)
        .cast<DetectedTransaction>();

    return _stream!;
  }

  @override
  Future<List<DetectedTransaction>> syncPendingFromNativeBuffer() async {
    final results = <DetectedTransaction>[];
    try {
      final List<dynamic>? rawList =
          await _methodChannel.invokeMethod<List<dynamic>>('getPendingNotifications');

      if (rawList != null && rawList.isNotEmpty) {
        final enabledPackages = await localDataSource.getEnabledBankPackages();

        for (final item in rawList) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final pkg = map['packageName'] as String? ?? '';
            final isShell = pkg == 'com.android.shell';
            final isDirectlyEnabled = enabledPackages.contains(pkg);
            final profile = BankProfile.findByPackage(pkg);
            final isProfileEnabled = profile != null && (
                enabledPackages.contains(profile.packageName) ||
                profile.packageAliases.any((a) => enabledPackages.contains(a))
            );

            if (enabledPackages.isNotEmpty && !isShell && !isDirectlyEnabled && !isProfileEnabled) {
              continue;
            }

            final id = map['id'] as String?;
            final title = map['title'] as String? ?? '';
            final text = map['text'] as String? ?? '';
            final subText = map['subText'] as String?;
            final postTime = map['postTime'] as int?;

            final date = postTime != null && postTime > 0
                ? DateTime.fromMillisecondsSinceEpoch(postTime)
                : DateTime.now();

            final parsed = ThaiBankParser.parse(
              id: id,
              packageName: pkg,
              title: title,
              text: text,
              subText: subText,
              timestamp: date,
            );

            if (parsed != null) {
              results.add(parsed);
            }
          }
        }

        // Clear buffer on native side once parsed
        await _methodChannel.invokeMethod('clearPendingNotifications');
      }
    } catch (_) {}

    return results;
  }

  @override
  Future<List<DetectedTransaction>> getPendingTransactions() {
    return localDataSource.getPendingTransactions();
  }

  @override
  Future<void> addPendingTransaction(DetectedTransaction transaction) {
    return localDataSource.addPendingTransaction(transaction);
  }

  @override
  Future<void> removePendingTransaction(String id) {
    return localDataSource.removePendingTransaction(id);
  }

  @override
  Future<void> clearPendingTransactions() {
    return localDataSource.clearAllPendingTransactions();
  }

  @override
  Future<void> markAsSaved(DetectedTransaction transaction) async {
    final updated = transaction.copyWith(isSaved: true);
    await localDataSource.removePendingTransaction(transaction.id);
    await localDataSource.addHistoryTransaction(updated);
  }

  @override
  Future<void> markAsDiscarded(DetectedTransaction transaction) async {
    final updated = transaction.copyWith(isDiscarded: true);
    await localDataSource.removePendingTransaction(transaction.id);
    await localDataSource.addHistoryTransaction(updated);
  }

  @override
  Future<bool> isAutoSyncEnabled() {
    return localDataSource.isAutoSyncEnabled();
  }

  @override
  Future<void> setAutoSyncEnabled(bool enabled) {
    return localDataSource.setAutoSyncEnabled(enabled);
  }

  @override
  Future<bool> isAutoSaveEnabled() {
    return localDataSource.isAutoSaveEnabled();
  }

  @override
  Future<void> setAutoSaveEnabled(bool enabled) {
    return localDataSource.setAutoSaveEnabled(enabled);
  }


  @override
  Future<List<String>> getEnabledBankPackages() {
    return localDataSource.getEnabledBankPackages();
  }

  @override
  Future<void> setEnabledBankPackages(List<String> packages) {
    return localDataSource.setEnabledBankPackages(packages);
  }
}
