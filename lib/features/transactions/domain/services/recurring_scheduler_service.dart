import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/recurring_transaction_model.dart';
import '../entities/recurring_transaction_entity.dart';
import '../entities/transaction_entity.dart';

class RecurringProcessResult {
  final List<TransactionEntity> autoPostedTransactions;
  final List<RecurringTransactionEntity> dueToNotifyRules;
  final List<RecurringTransactionEntity> updatedRules;

  const RecurringProcessResult({
    required this.autoPostedTransactions,
    required this.dueToNotifyRules,
    required this.updatedRules,
  });

  bool get hasAutoPosted => autoPostedTransactions.isNotEmpty;
  bool get hasNotifications => dueToNotifyRules.isNotEmpty;
}

class RecurringSchedulerService {
  final SharedPreferences _prefs;
  final Uuid _uuid;

  RecurringSchedulerService(this._prefs, [Uuid? uuid]) : _uuid = uuid ?? const Uuid();

  List<RecurringTransactionEntity> loadRules() {
    final raw = _prefs.getString(AppConstants.recurringTransactionsStorageKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => RecurringTransactionModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRules(List<RecurringTransactionEntity> rules) async {
    final jsonList = rules
        .map((r) => RecurringTransactionModel.fromEntity(r).toJson())
        .toList();
    await _prefs.setString(AppConstants.recurringTransactionsStorageKey, jsonEncode(jsonList));
  }

  /// Evaluates all active recurring rules against the current date [now].
  /// Generates transactions for rules with autoPost == true, and flags rules with autoPost == false.
  RecurringProcessResult processDueRules(
    List<RecurringTransactionEntity> rules, {
    DateTime? now,
  }) {
    final currentDate = now ?? DateTime.now();
    final List<TransactionEntity> autoPosted = [];
    final List<RecurringTransactionEntity> dueToNotify = [];
    final List<RecurringTransactionEntity> updatedList = [];

    for (final rule in rules) {
      if (rule.isDueToday(currentDate)) {
        if (rule.autoPost) {
          // Auto create transaction
          final txDate = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            8,
            0,
          );

          final autoNote = rule.note != null && rule.note!.isNotEmpty
              ? '${rule.note} (รายการอัตโนมัติ 🐾)'
              : 'รายการประจำอัตโนมัติ 🐾';

          final autoTags = {...rule.tags, '#รายการประจำ'}.toList();

          final newTx = TransactionEntity(
            id: _uuid.v4(),
            title: rule.title,
            amount: rule.amount,
            type: rule.type,
            categoryId: rule.categoryId,
            categoryName: rule.categoryName,
            categoryIconCode: rule.categoryIconCode,
            categoryColorValue: rule.categoryColorValue,
            date: txDate,
            note: autoNote,
            bankId: rule.bankId,
            bankAccountId: rule.bankAccountId,
            bankShortName: rule.bankShortName,
            accountMask: rule.accountMask,
            targetAccountId: rule.targetAccountId,
            tags: autoTags,
          );

          autoPosted.add(newTx);
          updatedList.add(rule.copyWith(lastExecutedDate: currentDate));
        } else {
          // Needs manual user confirmation
          dueToNotify.add(rule);
          updatedList.add(rule);
        }
      } else {
        updatedList.add(rule);
      }
    }

    return RecurringProcessResult(
      autoPostedTransactions: autoPosted,
      dueToNotifyRules: dueToNotify,
      updatedRules: updatedList,
    );
  }
}
