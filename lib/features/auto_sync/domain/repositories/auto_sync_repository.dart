import '../../domain/entities/detected_transaction.dart';

abstract class AutoSyncRepository {
  Future<bool> isPermissionGranted();
  Future<bool> isServiceConnected();
  Future<bool> rebindService();
  Future<bool> isBatteryOptimizationIgnored();
  Future<void> requestIgnoreBatteryOptimization();
  Future<void> openNotificationSettings();
  Future<void> openAppDetailsSettings();
  Future<void> sendTestNotification({
    String? packageName,
    String? title,
    String? text,
  });

  Stream<DetectedTransaction> get notificationStream;
  Future<List<DetectedTransaction>> syncPendingFromNativeBuffer();

  Future<List<DetectedTransaction>> getPendingTransactions();
  Future<void> addPendingTransaction(DetectedTransaction transaction);
  Future<void> removePendingTransaction(String id);
  Future<void> clearPendingTransactions();

  Future<void> markAsSaved(DetectedTransaction transaction);
  Future<void> markAsDiscarded(DetectedTransaction transaction);

  Future<bool> isAutoSyncEnabled();
  Future<void> setAutoSyncEnabled(bool enabled);

  Future<bool> isAutoSaveEnabled();
  Future<void> setAutoSaveEnabled(bool enabled);


  Future<List<String>> getEnabledBankPackages();
  Future<void> setEnabledBankPackages(List<String> packages);
}
