import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class SecurityLocalDataSource {
  bool isPinEnabled();
  bool isPinSet();
  bool isBiometricEnabled();
  Future<void> setBiometricEnabled(bool enabled);
  Future<void> savePin(String pin);
  bool verifyPin(String pin);
  Future<void> removePin();
  int getFailedAttempts();
  Future<void> recordFailedAttempt();
  Future<void> resetFailedAttempts();
  int? getLockoutTimestamp();
  Future<void> setLockoutTimestamp(int timestampMillis);
  Future<void> clearLockout();
}

class SecurityLocalDataSourceImpl implements SecurityLocalDataSource {
  final SharedPreferences sharedPreferences;

  static const String _keyPinHash = 'security_pin_hash';
  static const String _keyPinSalt = 'security_pin_salt';
  static const String _keyPinEnabled = 'security_pin_enabled';
  static const String _keyBiometricEnabled = 'security_biometric_enabled';
  static const String _keyFailedAttempts = 'security_failed_attempts';
  static const String _keyLockoutTimestamp = 'security_lockout_timestamp';

  SecurityLocalDataSourceImpl({required this.sharedPreferences});

  @override
  bool isPinEnabled() {
    return sharedPreferences.getBool(_keyPinEnabled) ?? false;
  }

  @override
  bool isPinSet() {
    final hash = sharedPreferences.getString(_keyPinHash);
    return hash != null && hash.isNotEmpty;
  }

  @override
  bool isBiometricEnabled() {
    return sharedPreferences.getBool(_keyBiometricEnabled) ?? false;
  }

  @override
  Future<void> setBiometricEnabled(bool enabled) async {
    await sharedPreferences.setBool(_keyBiometricEnabled, enabled);
  }

  @override
  Future<void> savePin(String pin) async {
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    await sharedPreferences.setString(_keyPinHash, hash);
    await sharedPreferences.setString(_keyPinSalt, salt);
    await sharedPreferences.setBool(_keyPinEnabled, true);
    await resetFailedAttempts();
    await clearLockout();
  }

  @override
  bool verifyPin(String pin) {
    final storedHash = sharedPreferences.getString(_keyPinHash);
    final storedSalt = sharedPreferences.getString(_keyPinSalt);
    if (storedHash == null || storedSalt == null) return false;

    final computedHash = _hashPin(pin, storedSalt);
    return storedHash == computedHash;
  }

  @override
  Future<void> removePin() async {
    await sharedPreferences.remove(_keyPinHash);
    await sharedPreferences.remove(_keyPinSalt);
    await sharedPreferences.setBool(_keyPinEnabled, false);
    await sharedPreferences.setBool(_keyBiometricEnabled, false);
    await resetFailedAttempts();
    await clearLockout();
  }

  @override
  int getFailedAttempts() {
    return sharedPreferences.getInt(_keyFailedAttempts) ?? 0;
  }

  @override
  Future<void> recordFailedAttempt() async {
    final current = getFailedAttempts();
    await sharedPreferences.setInt(_keyFailedAttempts, current + 1);
  }

  @override
  Future<void> resetFailedAttempts() async {
    await sharedPreferences.remove(_keyFailedAttempts);
  }

  @override
  int? getLockoutTimestamp() {
    return sharedPreferences.getInt(_keyLockoutTimestamp);
  }

  @override
  Future<void> setLockoutTimestamp(int timestampMillis) async {
    await sharedPreferences.setInt(_keyLockoutTimestamp, timestampMillis);
  }

  @override
  Future<void> clearLockout() async {
    await sharedPreferences.remove(_keyLockoutTimestamp);
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin:$salt');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _generateSalt([int length = 16]) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }
}
