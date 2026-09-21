import 'package:equatable/equatable.dart';
import '../../domain/entities/bank_profile.dart';
import '../../domain/entities/detected_transaction.dart';
import '../../domain/entities/swipe_history_record.dart';

class AutoSyncState extends Equatable {
  final bool isPermissionGranted;
  final bool isServiceConnected;
  final bool isBatteryOptimizationIgnored;
  final bool isAutoSyncEnabled;
  final bool isAutoSaveEnabled;
  final List<String> enabledBankPackages;
  final List<DetectedTransaction> pendingTransactions;
  final DetectedTransaction? latestDetected;
  final bool isLoading;
  final String? errorMessage;
  final bool isDashboardBannerDismissed;
  final List<String> dismissedBannerTransactionIds;
  final List<SwipeHistoryRecord> swipeHistory;

  /// Returns only pending transactions that haven't been dismissed by the user on the dashboard banner
  List<DetectedTransaction> get unDismissedPendingTransactions {
    return pendingTransactions
        .where((t) => !dismissedBannerTransactionIds.contains(t.id))
        .toList();
  }

  /// Check whether auto-sync is enabled for a specific bank
  bool isBankEnabled(BankProfile bank) {
    if (enabledBankPackages.isEmpty) return false;
    return enabledBankPackages.contains(bank.packageName) ||
        bank.packageAliases.any((a) => enabledBankPackages.contains(a));
  }

  const AutoSyncState({
    this.isPermissionGranted = false,
    this.isServiceConnected = false,
    this.isBatteryOptimizationIgnored = false,
    this.isAutoSyncEnabled = true,
    this.isAutoSaveEnabled = false,
    this.enabledBankPackages = const [],
    this.pendingTransactions = const [],
    this.latestDetected,
    this.isLoading = false,
    this.errorMessage,
    this.isDashboardBannerDismissed = false,
    this.dismissedBannerTransactionIds = const [],
    this.swipeHistory = const [],
  });

  AutoSyncState copyWith({
    bool? isPermissionGranted,
    bool? isServiceConnected,
    bool? isBatteryOptimizationIgnored,
    bool? isAutoSyncEnabled,
    bool? isAutoSaveEnabled,
    List<String>? enabledBankPackages,
    List<DetectedTransaction>? pendingTransactions,
    DetectedTransaction? latestDetected,
    bool clearLatestDetected = false,
    bool? isLoading,
    String? errorMessage,
    bool? isDashboardBannerDismissed,
    List<String>? dismissedBannerTransactionIds,
    List<SwipeHistoryRecord>? swipeHistory,
  }) {
    return AutoSyncState(
      isPermissionGranted: isPermissionGranted ?? this.isPermissionGranted,
      isServiceConnected: isServiceConnected ?? this.isServiceConnected,
      isBatteryOptimizationIgnored:
          isBatteryOptimizationIgnored ?? this.isBatteryOptimizationIgnored,
      isAutoSyncEnabled: isAutoSyncEnabled ?? this.isAutoSyncEnabled,
      isAutoSaveEnabled: isAutoSaveEnabled ?? this.isAutoSaveEnabled,
      enabledBankPackages: enabledBankPackages ?? this.enabledBankPackages,
      pendingTransactions: pendingTransactions ?? this.pendingTransactions,
      latestDetected:
          clearLatestDetected ? null : (latestDetected ?? this.latestDetected),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isDashboardBannerDismissed:
          isDashboardBannerDismissed ?? this.isDashboardBannerDismissed,
      dismissedBannerTransactionIds:
          dismissedBannerTransactionIds ?? this.dismissedBannerTransactionIds,
      swipeHistory: swipeHistory ?? this.swipeHistory,
    );
  }

  @override
  List<Object?> get props => [
        isPermissionGranted,
        isServiceConnected,
        isBatteryOptimizationIgnored,
        isAutoSyncEnabled,
        isAutoSaveEnabled,
        enabledBankPackages,
        pendingTransactions,
        latestDetected,
        isLoading,
        errorMessage,
        isDashboardBannerDismissed,
        dismissedBannerTransactionIds,
        swipeHistory,
      ];
}
