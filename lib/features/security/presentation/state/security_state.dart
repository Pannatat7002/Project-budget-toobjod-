import 'package:equatable/equatable.dart';
import '../../domain/models/pin_mode.dart';

class SecurityState extends Equatable {
  final PinMode mode;
  final String enteredPin;
  final String tempOriginalPin;
  final bool isBiometricEnabled;
  final bool isBiometricAvailable;
  final bool isPinSet;
  final bool isLocked;
  final int lockoutRemainingSeconds;
  final bool isError;
  final String? errorMessage;
  final bool isAuthenticated;
  final bool isSuccess;
  final int shakeCount;

  const SecurityState({
    this.mode = PinMode.verify,
    this.enteredPin = '',
    this.tempOriginalPin = '',
    this.isBiometricEnabled = false,
    this.isBiometricAvailable = true,
    this.isPinSet = false,
    this.isLocked = false,
    this.lockoutRemainingSeconds = 0,
    this.isError = false,
    this.errorMessage,
    this.isAuthenticated = false,
    this.isSuccess = false,
    this.shakeCount = 0,
  });

  SecurityState copyWith({
    PinMode? mode,
    String? enteredPin,
    String? tempOriginalPin,
    bool? isBiometricEnabled,
    bool? isBiometricAvailable,
    bool? isPinSet,
    bool? isLocked,
    int? lockoutRemainingSeconds,
    bool? isError,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? isAuthenticated,
    bool? isSuccess,
    int? shakeCount,
  }) {
    return SecurityState(
      mode: mode ?? this.mode,
      enteredPin: enteredPin ?? this.enteredPin,
      tempOriginalPin: tempOriginalPin ?? this.tempOriginalPin,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      isPinSet: isPinSet ?? this.isPinSet,
      isLocked: isLocked ?? this.isLocked,
      lockoutRemainingSeconds:
          lockoutRemainingSeconds ?? this.lockoutRemainingSeconds,
      isError: isError ?? this.isError,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isSuccess: isSuccess ?? this.isSuccess,
      shakeCount: shakeCount ?? this.shakeCount,
    );
  }

  @override
  List<Object?> get props => [
        mode,
        enteredPin,
        tempOriginalPin,
        isBiometricEnabled,
        isBiometricAvailable,
        isPinSet,
        isLocked,
        lockoutRemainingSeconds,
        isError,
        errorMessage,
        isAuthenticated,
        isSuccess,
        shakeCount,
      ];
}
