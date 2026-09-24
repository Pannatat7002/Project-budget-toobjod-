import 'package:equatable/equatable.dart';
import 'transaction_entity.dart';

enum RecurringFrequency { daily, weekly, monthly }

extension RecurringFrequencyX on RecurringFrequency {
  String get title {
    switch (this) {
      case RecurringFrequency.daily:
        return 'ทุกวัน';
      case RecurringFrequency.weekly:
        return 'ทุกสัปดาห์';
      case RecurringFrequency.monthly:
        return 'ทุกเดือน';
    }
  }
}

class RecurringTransactionEntity extends Equatable {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String categoryName;
  final int categoryIconCode;
  final int categoryColorValue;
  final String? bankId;
  final String? bankAccountId;
  final String? bankShortName;
  final String? accountMask;
  final String? targetAccountId;
  final RecurringFrequency frequency;
  final int scheduledDay; // 1-31 for monthly, 1-7 for weekly
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? lastExecutedDate;
  final bool autoPost;
  final bool isActive;
  final String? note;
  final List<String> tags;

  const RecurringTransactionEntity({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIconCode,
    required this.categoryColorValue,
    this.bankId,
    this.bankAccountId,
    this.bankShortName,
    this.accountMask,
    this.targetAccountId,
    this.frequency = RecurringFrequency.monthly,
    required this.scheduledDay,
    required this.startDate,
    this.endDate,
    this.lastExecutedDate,
    this.autoPost = true,
    this.isActive = true,
    this.note,
    this.tags = const [],
  });

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;
  bool get isTransfer => type == TransactionType.transfer;

  /// Next estimated execution date based on frequency and scheduledDay
  DateTime getNextDueDate([DateTime? fromDate]) {
    final now = fromDate ?? DateTime.now();
    if (frequency == RecurringFrequency.daily) {
      if (lastExecutedDate != null &&
          lastExecutedDate!.year == now.year &&
          lastExecutedDate!.month == now.month &&
          lastExecutedDate!.day == now.day) {
        return DateTime(now.year, now.month, now.day + 1);
      }
      return DateTime(now.year, now.month, now.day);
    } else if (frequency == RecurringFrequency.weekly) {
      // scheduledDay: 1 (Mon) to 7 (Sun)
      int currentWeekday = now.weekday;
      int daysUntil = (scheduledDay - currentWeekday) % 7;
      if (daysUntil < 0) daysUntil += 7;
      if (daysUntil == 0 &&
          lastExecutedDate != null &&
          lastExecutedDate!.year == now.year &&
          lastExecutedDate!.month == now.month &&
          lastExecutedDate!.day == now.day) {
        daysUntil = 7;
      }
      return DateTime(now.year, now.month, now.day + daysUntil);
    } else {
      // Monthly
      final maxDaysThisMonth = DateTime(now.year, now.month + 1, 0).day;
      final targetDayThisMonth = scheduledDay.clamp(1, maxDaysThisMonth);
      final thisMonthDue = DateTime(now.year, now.month, targetDayThisMonth);

      // Check if already executed this month or today is past due day
      final alreadyRunThisMonth = lastExecutedDate != null &&
          lastExecutedDate!.year == now.year &&
          lastExecutedDate!.month == now.month;

      if (!alreadyRunThisMonth && !now.isBefore(thisMonthDue)) {
        return thisMonthDue;
      } else if (now.day < targetDayThisMonth && !alreadyRunThisMonth) {
        return thisMonthDue;
      } else {
        // Next month
        final nextMonth = now.month == 12 ? 1 : now.month + 1;
        final nextYear = now.month == 12 ? now.year + 1 : now.year;
        final maxDaysNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        final targetDayNextMonth = scheduledDay.clamp(1, maxDaysNextMonth);
        return DateTime(nextYear, nextMonth, targetDayNextMonth);
      }
    }
  }

  /// Whether this recurring rule should trigger today
  bool isDueToday([DateTime? testNow]) {
    if (!isActive) return false;
    final now = testNow ?? DateTime.now();
    if (now.isBefore(startDate)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;

    if (frequency == RecurringFrequency.daily) {
      return lastExecutedDate == null ||
          !(lastExecutedDate!.year == now.year &&
              lastExecutedDate!.month == now.month &&
              lastExecutedDate!.day == now.day);
    } else if (frequency == RecurringFrequency.weekly) {
      if (now.weekday != scheduledDay) return false;
      return lastExecutedDate == null ||
          !(lastExecutedDate!.year == now.year &&
              lastExecutedDate!.month == now.month &&
              lastExecutedDate!.day == now.day);
    } else {
      // Monthly
      final maxDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final effectiveDay = scheduledDay.clamp(1, maxDaysInMonth);
      final isDueDayOrPast = now.day >= effectiveDay;
      final alreadyExecutedThisMonth = lastExecutedDate != null &&
          lastExecutedDate!.year == now.year &&
          lastExecutedDate!.month == now.month;

      return isDueDayOrPast && !alreadyExecutedThisMonth;
    }
  }

  RecurringTransactionEntity copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? categoryName,
    int? categoryIconCode,
    int? categoryColorValue,
    String? bankId,
    String? bankAccountId,
    String? bankShortName,
    String? accountMask,
    String? targetAccountId,
    RecurringFrequency? frequency,
    int? scheduledDay,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? lastExecutedDate,
    bool? autoPost,
    bool? isActive,
    String? note,
    List<String>? tags,
  }) {
    return RecurringTransactionEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIconCode: categoryIconCode ?? this.categoryIconCode,
      categoryColorValue: categoryColorValue ?? this.categoryColorValue,
      bankId: bankId ?? this.bankId,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      bankShortName: bankShortName ?? this.bankShortName,
      accountMask: accountMask ?? this.accountMask,
      targetAccountId: targetAccountId ?? this.targetAccountId,
      frequency: frequency ?? this.frequency,
      scheduledDay: scheduledDay ?? this.scheduledDay,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      lastExecutedDate: lastExecutedDate ?? this.lastExecutedDate,
      autoPost: autoPost ?? this.autoPost,
      isActive: isActive ?? this.isActive,
      note: note ?? this.note,
      tags: tags ?? this.tags,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        amount,
        type,
        categoryId,
        categoryName,
        categoryIconCode,
        categoryColorValue,
        bankId,
        bankAccountId,
        bankShortName,
        accountMask,
        targetAccountId,
        frequency,
        scheduledDay,
        startDate,
        endDate,
        lastExecutedDate,
        autoPost,
        isActive,
        note,
        tags,
      ];
}
