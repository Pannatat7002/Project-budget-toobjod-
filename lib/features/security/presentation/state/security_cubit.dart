import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/security_local_data_source.dart';
import '../../domain/models/pin_mode.dart';
import 'security_state.dart';

class SecurityCubit extends Cubit<SecurityState> {
  final SecurityLocalDataSource localDataSource;
  Timer? _lockoutTimer;

  SecurityCubit({required this.localDataSource})
      : super(const SecurityState()) {
    init();
  }

  Future<void> init({PinMode defaultMode = PinMode.verify}) async {
    final isPinSet = localDataSource.isPinSet();
    final isPinEnabled = localDataSource.isPinEnabled();
    final isBiometricEnabled = localDataSource.isBiometricEnabled();
    final isDeviceAuthSupported = await localDataSource.isDeviceAuthSupported();

    // Check existing lockout
    final lockoutTimestamp = localDataSource.getLockoutTimestamp();
    int remainingSeconds = 0;
    bool isLocked = false;

    if (lockoutTimestamp != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsed = (now - lockoutTimestamp) ~/ 1000;
      if (elapsed < 30) {
        remainingSeconds = 30 - elapsed;
        isLocked = true;
        _startLockoutCountdown(remainingSeconds);
      } else {
        localDataSource.clearLockout();
        localDataSource.resetFailedAttempts();
      }
    }

    emit(state.copyWith(
      mode: isPinSet ? defaultMode : PinMode.create,
      isPinSet: isPinSet && isPinEnabled,
      isBiometricEnabled: isBiometricEnabled,
      isBiometricAvailable: isDeviceAuthSupported,
      isLocked: isLocked,
      lockoutRemainingSeconds: remainingSeconds,
      enteredPin: '',
      isError: false,
      clearErrorMessage: true,
      isAuthenticated: false,
      isSuccess: false,
    ));

    // Auto trigger biometric if enabled in verify mode
    if (isPinSet && isPinEnabled && isBiometricEnabled && defaultMode == PinMode.verify && !isLocked) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!isClosed && state.mode == PinMode.verify && !state.isLocked && !state.isSuccess) {
          triggerBiometric();
        }
      });
    }
  }

  void setMode(PinMode mode, {String? tempPin}) {
    emit(state.copyWith(
      mode: mode,
      tempOriginalPin: tempPin ?? '',
      enteredPin: '',
      isError: false,
      clearErrorMessage: true,
      isSuccess: false,
    ));
  }

  void inputDigit(String digit) {
    if (state.isLocked || state.isSuccess || state.enteredPin.length >= 4) {
      return;
    }

    final newPin = '${state.enteredPin}$digit';
    emit(state.copyWith(
      enteredPin: newPin,
      isError: false,
      clearErrorMessage: true,
    ));

    if (newPin.length == 4) {
      _handleCompletePin(newPin);
    }
  }

  void deleteDigit() {
    if (state.isLocked || state.isSuccess || state.enteredPin.isEmpty) {
      return;
    }

    final newPin = state.enteredPin.substring(0, state.enteredPin.length - 1);
    emit(state.copyWith(
      enteredPin: newPin,
      isError: false,
      clearErrorMessage: true,
    ));
  }

  void clearPin() {
    if (state.isLocked || state.isSuccess) return;
    emit(state.copyWith(
      enteredPin: '',
      isError: false,
      clearErrorMessage: true,
    ));
  }

  Future<void> _handleCompletePin(String pin) async {
    switch (state.mode) {
      case PinMode.verify:
        _verifyPin(pin);
        break;

      case PinMode.create:
        // Wait a tiny moment so the 4th dot animates, then go to confirm
        await Future.delayed(const Duration(milliseconds: 180));
        if (isClosed) return;
        emit(state.copyWith(
          mode: PinMode.confirm,
          tempOriginalPin: pin,
          enteredPin: '',
          isError: false,
          clearErrorMessage: true,
        ));
        break;

      case PinMode.confirm:
        if (pin == state.tempOriginalPin) {
          await localDataSource.savePin(pin);
          emit(state.copyWith(
            isSuccess: true,
            isPinSet: true,
            isAuthenticated: true,
            isError: false,
            clearErrorMessage: true,
          ));
        } else {
          _triggerError('รหัส PIN ไม่ตรงกัน กรุณากรอกใหม่');
        }
        break;

      case PinMode.change:
        final isValid = localDataSource.verifyPin(pin);
        if (isValid) {
          await Future.delayed(const Duration(milliseconds: 180));
          if (isClosed) return;
          emit(state.copyWith(
            mode: PinMode.create,
            enteredPin: '',
            isError: false,
            clearErrorMessage: true,
          ));
        } else {
          _triggerError('รหัส PIN เดิมไม่ถูกต้อง');
        }
        break;
    }
  }

  Future<void> _verifyPin(String pin) async {
    final isValid = localDataSource.verifyPin(pin);

    if (isValid) {
      await localDataSource.resetFailedAttempts();
      await localDataSource.clearLockout();
      emit(state.copyWith(
        isSuccess: true,
        isAuthenticated: true,
        isError: false,
        clearErrorMessage: true,
      ));
    } else {
      await localDataSource.recordFailedAttempt();
      final failedCount = localDataSource.getFailedAttempts();

      if (failedCount >= 5) {
        final now = DateTime.now().millisecondsSinceEpoch;
        await localDataSource.setLockoutTimestamp(now);
        emit(state.copyWith(
          isLocked: true,
          lockoutRemainingSeconds: 30,
          isError: true,
          errorMessage: 'กรอกผิดเกินกำหนด กรุณารอ 30 วินาที',
          enteredPin: '',
          shakeCount: state.shakeCount + 1,
        ));
        _startLockoutCountdown(30);
      } else {
        final remaining = 5 - failedCount;
        _triggerError(
          'รหัส PIN ไม่ถูกต้อง (เหลือโอกาสอีก $remaining ครั้ง)',
        );
      }
    }
  }

  void _triggerError(String message) {
    emit(state.copyWith(
      isError: true,
      errorMessage: message,
      shakeCount: state.shakeCount + 1,
    ));

    // Clear entered PIN after brief animation window
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!isClosed && !state.isLocked && !state.isSuccess) {
        emit(state.copyWith(
          enteredPin: '',
        ));
      }
    });
  }

  void _startLockoutCountdown(int seconds) {
    _lockoutTimer?.cancel();
    int current = seconds;

    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      current--;
      if (current <= 0) {
        timer.cancel();
        localDataSource.clearLockout();
        localDataSource.resetFailedAttempts();
        if (!isClosed) {
          emit(state.copyWith(
            isLocked: false,
            lockoutRemainingSeconds: 0,
            isError: false,
            clearErrorMessage: true,
          ));
        }
      } else {
        if (!isClosed) {
          emit(state.copyWith(
            lockoutRemainingSeconds: current,
          ));
        }
      }
    });
  }

  Future<void> triggerBiometric() async {
    if (state.isLocked || state.isSuccess) return;

    final success = await localDataSource.authenticateWithBiometrics(
      localizedReason: 'สแกนลายนิ้วมือหรือใบหน้าเพื่อเข้าสู่ระบบ เจ้าตูบจด',
    );

    if (success) {
      await localDataSource.resetFailedAttempts();
      await localDataSource.clearLockout();
      emit(state.copyWith(
        isSuccess: true,
        isAuthenticated: true,
        isError: false,
        clearErrorMessage: true,
      ));
    }
  }

  /// Authenticate using OS Lock Screen (Device PIN, Pattern, Password, or Biometrics)
  /// Used when user forgets their in-app PIN to verify device ownership and reset PIN
  Future<bool> authenticateWithDeviceLock({bool resetPinAfterAuth = true}) async {
    final success = await localDataSource.authenticateWithDeviceCredentials(
      localizedReason: 'ยืนยันตัวตนด้วยรหัสล็อกหน้าจอเครื่องเพื่อยืนยันความเป็นเจ้าของและตั้งรหัส PIN ใหม่',
    );

    if (success) {
      await localDataSource.resetFailedAttempts();
      await localDataSource.clearLockout();
      _lockoutTimer?.cancel();

      if (resetPinAfterAuth) {
        emit(state.copyWith(
          mode: PinMode.create,
          isLocked: false,
          lockoutRemainingSeconds: 0,
          enteredPin: '',
          tempOriginalPin: '',
          isError: false,
          clearErrorMessage: true,
          isSuccess: false,
        ));
      } else {
        emit(state.copyWith(
          isSuccess: true,
          isAuthenticated: true,
          isLocked: false,
          lockoutRemainingSeconds: 0,
          isError: false,
          clearErrorMessage: true,
        ));
      }
      return true;
    } else {
      _triggerError('การยืนยันตัวตนไม่สำเร็จ กรุณาลองใหม่');
      return false;
    }
  }

  Future<void> toggleBiometric(bool enabled) async {
    await localDataSource.setBiometricEnabled(enabled);
    emit(state.copyWith(isBiometricEnabled: enabled));
  }

  Future<void> removePin() async {
    await localDataSource.removePin();
    emit(state.copyWith(
      isPinSet: false,
      isBiometricEnabled: false,
      enteredPin: '',
    ));
  }

  @override
  Future<void> close() {
    _lockoutTimer?.cancel();
    return super.close();
  }
}
