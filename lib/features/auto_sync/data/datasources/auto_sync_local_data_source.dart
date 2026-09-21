import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/bank_profile.dart';
import '../../domain/entities/detected_transaction.dart';
import '../../domain/entities/swipe_history_record.dart';

abstract class AutoSyncLocalDataSource {
  Future<bool> isAutoSyncEnabled();
  Future<void> setAutoSyncEnabled(bool enabled);

  Future<bool> isAutoSaveEnabled();
  Future<void> setAutoSaveEnabled(bool enabled);


  Future<List<String>> getEnabledBankPackages();
  Future<void> setEnabledBankPackages(List<String> packages);

  Future<List<DetectedTransaction>> getPendingTransactions();
  Future<void> savePendingTransactions(List<DetectedTransaction> transactions);
  Future<void> addPendingTransaction(DetectedTransaction transaction);
  Future<void> removePendingTransaction(String id);
  Future<void> clearAllPendingTransactions();

  Future<List<DetectedTransaction>> getHistoryTransactions();
  Future<void> addHistoryTransaction(DetectedTransaction transaction);

  Future<List<SwipeHistoryRecord>> getSwipeHistory();
  Future<void> saveSwipeHistory(List<SwipeHistoryRecord> records);
  Future<void> addSwipeHistoryRecord(SwipeHistoryRecord record);
  Future<void> addSwipeHistoryRecords(List<SwipeHistoryRecord> records);
  Future<void> clearSwipeHistory();

  Future<List<String>> getDismissedBannerTransactionIds();
  Future<void> saveDismissedBannerTransactionIds(List<String> ids);
}

class AutoSyncLocalDataSourceImpl implements AutoSyncLocalDataSource {
  final SharedPreferences sharedPreferences;

  static const String _keyAutoSyncEnabled = 'bp_auto_sync_enabled_v1';
  static const String _keyAutoSaveEnabled = 'bp_auto_save_enabled_v1';
  static const String _keyEnabledPackages = 'bp_enabled_bank_packages_v1';
  static const String _keyPendingTxs = 'bp_pending_detected_txs_v1';
  static const String _keyHistoryTxs = 'bp_history_detected_txs_v1';
  static const String _keySwipeHistory = 'bp_swipe_history_records_v1';
  static const String _keyDismissedBannerTxIds = 'bp_dismissed_banner_tx_ids_v1';

  List<DetectedTransaction>? _cachedPending;
  List<DetectedTransaction>? _cachedHistory;
  List<SwipeHistoryRecord>? _cachedSwipeHistory;

  AutoSyncLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<bool> isAutoSyncEnabled() async {
    return sharedPreferences.getBool(_keyAutoSyncEnabled) ?? true;
  }

  @override
  Future<void> setAutoSyncEnabled(bool enabled) async {
    await sharedPreferences.setBool(_keyAutoSyncEnabled, enabled);
  }

  @override
  Future<bool> isAutoSaveEnabled() async {
    return sharedPreferences.getBool(_keyAutoSaveEnabled) ?? false;
  }

  @override
  Future<void> setAutoSaveEnabled(bool enabled) async {
    await sharedPreferences.setBool(_keyAutoSaveEnabled, enabled);
  }


  @override
  Future<List<String>> getEnabledBankPackages() async {
    final list = sharedPreferences.getStringList(_keyEnabledPackages);
    if (list != null) {
      return list;
    }
    // Default: empty until user explicitly adds bank account and enables auto-sync
    return [];
  }

  @override
  Future<void> setEnabledBankPackages(List<String> packages) async {
    await sharedPreferences.setStringList(_keyEnabledPackages, packages);
  }

  @override
  Future<List<DetectedTransaction>> getPendingTransactions() async {
    if (_cachedPending != null) return List.from(_cachedPending!);
    final jsonStr = sharedPreferences.getString(_keyPendingTxs);
    if (jsonStr == null || jsonStr.isEmpty) {
      _cachedPending = [];
      return [];
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      final rawList = list.map((e) => DetectedTransaction.fromJson(e as Map<String, dynamic>)).toList();
      final filteredList = rawList.where((e) => !e.id.startsWith('mock_')).toList();
      if (filteredList.length != rawList.length) {
        savePendingTransactions(filteredList);
      }
      _cachedPending = filteredList;
      return List.from(_cachedPending!);
    } catch (_) {
      _cachedPending = [];
      return [];
    }
  }

  @override
  Future<void> savePendingTransactions(List<DetectedTransaction> transactions) async {
    _cachedPending = List.from(transactions);
    final jsonList = transactions.map((t) => t.toJson()).toList();
    await sharedPreferences.setString(_keyPendingTxs, jsonEncode(jsonList));
  }

  @override
  Future<void> addPendingTransaction(DetectedTransaction transaction) async {
    final list = await getPendingTransactions();
    // Check duplicate strictly by unique id or content within 10s
    final exists = list.any((t) =>
        t.id == transaction.id ||
        (t.packageName == transaction.packageName &&
            t.amount == transaction.amount &&
            t.type == transaction.type &&
            t.timestamp.difference(transaction.timestamp).abs().inSeconds < 10));
    if (!exists) {
      list.insert(0, transaction);
      await savePendingTransactions(list);
    }
  }

  @override
  Future<void> removePendingTransaction(String id) async {
    final list = await getPendingTransactions();
    list.removeWhere((t) => t.id == id);
    await savePendingTransactions(list);
  }

  @override
  Future<void> clearAllPendingTransactions() async {
    _cachedPending = [];
    await sharedPreferences.remove(_keyPendingTxs);
  }

  @override
  Future<List<DetectedTransaction>> getHistoryTransactions() async {
    if (_cachedHistory != null) return List.from(_cachedHistory!);
    final jsonStr = sharedPreferences.getString(_keyHistoryTxs);
    if (jsonStr == null || jsonStr.isEmpty) {
      _cachedHistory = [];
      return [];
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      final rawList = list.map((e) => DetectedTransaction.fromJson(e as Map<String, dynamic>)).toList();
      final filteredList = rawList.where((e) => !e.id.startsWith('mock_')).toList();
      _cachedHistory = filteredList;
      return List.from(_cachedHistory!);
    } catch (_) {
      _cachedHistory = [];
      return [];
    }
  }

  @override
  Future<void> addHistoryTransaction(DetectedTransaction transaction) async {
    final list = await getHistoryTransactions();
    list.insert(0, transaction);
    // Keep max 100 in history
    if (list.length > 100) {
      list.removeRange(100, list.length);
    }
    _cachedHistory = List.from(list);
    final jsonList = list.map((t) => t.toJson()).toList();
    await sharedPreferences.setString(_keyHistoryTxs, jsonEncode(jsonList));
  }

  @override
  Future<List<SwipeHistoryRecord>> getSwipeHistory() async {
    if (_cachedSwipeHistory != null) return List.from(_cachedSwipeHistory!);
    final jsonStr = sharedPreferences.getString(_keySwipeHistory);
    if (jsonStr == null || jsonStr.isEmpty) {
      _cachedSwipeHistory = [];
      return [];
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      final records = list
          .map((e) => SwipeHistoryRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      _cachedSwipeHistory = records;
      return List.from(_cachedSwipeHistory!);
    } catch (_) {
      _cachedSwipeHistory = [];
      return [];
    }
  }

  @override
  Future<void> saveSwipeHistory(List<SwipeHistoryRecord> records) async {
    _cachedSwipeHistory = List.from(records);
    final jsonList = records.map((r) => r.toJson()).toList();
    await sharedPreferences.setString(_keySwipeHistory, jsonEncode(jsonList));
  }

  @override
  Future<void> addSwipeHistoryRecord(SwipeHistoryRecord record) async {
    final list = await getSwipeHistory();
    list.removeWhere((r) => r.id == record.id);
    list.insert(0, record);
    if (list.length > 500) {
      list.removeRange(500, list.length);
    }
    await saveSwipeHistory(list);
  }

  @override
  Future<void> addSwipeHistoryRecords(List<SwipeHistoryRecord> records) async {
    final list = await getSwipeHistory();
    final newIds = records.map((r) => r.id).toSet();
    list.removeWhere((r) => newIds.contains(r.id));
    list.insertAll(0, records);
    if (list.length > 500) {
      list.removeRange(500, list.length);
    }
    await saveSwipeHistory(list);
  }

  @override
  Future<void> clearSwipeHistory() async {
    _cachedSwipeHistory = [];
    await sharedPreferences.remove(_keySwipeHistory);
  }

  @override
  Future<List<String>> getDismissedBannerTransactionIds() async {
    final list = sharedPreferences.getStringList(_keyDismissedBannerTxIds);
    return list != null ? List<String>.from(list) : [];
  }

  @override
  Future<void> saveDismissedBannerTransactionIds(List<String> ids) async {
    // Keep max 200 IDs to avoid unbounded growth
    final trimmed = ids.length > 200 ? ids.sublist(ids.length - 200) : ids;
    await sharedPreferences.setStringList(_keyDismissedBannerTxIds, trimmed);
  }
}
