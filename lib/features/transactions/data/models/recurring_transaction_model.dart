import '../../domain/entities/recurring_transaction_entity.dart';
import '../../domain/entities/transaction_entity.dart';

class RecurringTransactionModel extends RecurringTransactionEntity {
  const RecurringTransactionModel({
    required super.id,
    required super.title,
    required super.amount,
    required super.type,
    required super.categoryId,
    required super.categoryName,
    required super.categoryIconCode,
    required super.categoryColorValue,
    super.bankId,
    super.bankAccountId,
    super.bankShortName,
    super.accountMask,
    super.targetAccountId,
    super.frequency = RecurringFrequency.monthly,
    required super.scheduledDay,
    required super.startDate,
    super.endDate,
    super.lastExecutedDate,
    super.autoPost = true,
    super.isActive = true,
    super.note,
    super.tags = const [],
  });

  factory RecurringTransactionModel.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'expense';
    final type = typeStr == 'income'
        ? TransactionType.income
        : typeStr == 'transfer'
            ? TransactionType.transfer
            : TransactionType.expense;

    final freqStr = json['frequency'] as String? ?? 'monthly';
    final freq = freqStr == 'daily'
        ? RecurringFrequency.daily
        : freqStr == 'weekly'
            ? RecurringFrequency.weekly
            : RecurringFrequency.monthly;

    final tagsRaw = json['tags'];
    final List<String> tags = tagsRaw is List
        ? tagsRaw.map((e) => e.toString()).toList()
        : const <String>[];

    return RecurringTransactionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: type,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      categoryIconCode: json['categoryIconCode'] as int,
      categoryColorValue: json['categoryColorValue'] as int,
      bankId: json['bankId'] as String?,
      bankAccountId: json['bankAccountId'] as String?,
      bankShortName: json['bankShortName'] as String?,
      accountMask: json['accountMask'] as String?,
      targetAccountId: json['targetAccountId'] as String?,
      frequency: freq,
      scheduledDay: json['scheduledDay'] as int? ?? 1,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      lastExecutedDate: json['lastExecutedDate'] != null
          ? DateTime.parse(json['lastExecutedDate'] as String)
          : null,
      autoPost: json['autoPost'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? true,
      note: json['note'] as String?,
      tags: tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type == TransactionType.income
          ? 'income'
          : type == TransactionType.transfer
              ? 'transfer'
              : 'expense',
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryIconCode': categoryIconCode,
      'categoryColorValue': categoryColorValue,
      'bankId': bankId,
      'bankAccountId': bankAccountId,
      'bankShortName': bankShortName,
      'accountMask': accountMask,
      'targetAccountId': targetAccountId,
      'frequency': frequency == RecurringFrequency.daily
          ? 'daily'
          : frequency == RecurringFrequency.weekly
              ? 'weekly'
              : 'monthly',
      'scheduledDay': scheduledDay,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'lastExecutedDate': lastExecutedDate?.toIso8601String(),
      'autoPost': autoPost,
      'isActive': isActive,
      'note': note,
      'tags': tags,
    };
  }

  factory RecurringTransactionModel.fromEntity(RecurringTransactionEntity entity) {
    return RecurringTransactionModel(
      id: entity.id,
      title: entity.title,
      amount: entity.amount,
      type: entity.type,
      categoryId: entity.categoryId,
      categoryName: entity.categoryName,
      categoryIconCode: entity.categoryIconCode,
      categoryColorValue: entity.categoryColorValue,
      bankId: entity.bankId,
      bankAccountId: entity.bankAccountId,
      bankShortName: entity.bankShortName,
      accountMask: entity.accountMask,
      targetAccountId: entity.targetAccountId,
      frequency: entity.frequency,
      scheduledDay: entity.scheduledDay,
      startDate: entity.startDate,
      endDate: entity.endDate,
      lastExecutedDate: entity.lastExecutedDate,
      autoPost: entity.autoPost,
      isActive: entity.isActive,
      note: entity.note,
      tags: entity.tags,
    );
  }
}
