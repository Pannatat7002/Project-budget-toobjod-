import 'package:equatable/equatable.dart';
import '../../domain/entities/detected_transaction.dart';

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
      ];
}
