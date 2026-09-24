import 'package:equatable/equatable.dart';

enum TransactionType { income, expense, transfer }

class TransactionEntity extends Equatable {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String categoryName;
  final int categoryIconCode;
  final int categoryColorValue;
  final DateTime date;
  final String? note;
  final String? bankId;
  final String? bankAccountId;
  final String? bankShortName;
  final String? accountMask;
  final String? targetAccountId;
  final List<String> tags;

  const TransactionEntity({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIconCode,
    required this.categoryColorValue,
    required this.date,
    this.note,
    this.bankId,
    this.bankAccountId,
    this.bankShortName,
    this.accountMask,
    this.targetAccountId,
    this.tags = const [],
  });

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;
  bool get isTransfer => type == TransactionType.transfer;

  /// Returns true if the transaction's category is unknown, uncategorized, or "other"
  bool get isUnknownCategory {
    final cId = categoryId.toLowerCase().trim();
    final cName = categoryName.toLowerCase().trim();
    return cId == 'other' ||
        cId == 'other_income' ||
        cId == 'uncategorized' ||
        cId == 'unknown' ||
        cId.isEmpty ||
        cName == 'อื่นๆ' ||
        cName == 'รายรับอื่นๆ' ||
        cName == 'หมวดหมู่อื่นๆ' ||
        cName == 'ไม่ระบุ' ||
        cName == 'other' ||
        cName == 'other income' ||
        cName == 'other_income' ||
        cName == 'uncategorized' ||
        cName == 'unknown' ||
        cName.isEmpty;
  }

  TransactionEntity copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? categoryName,
    int? categoryIconCode,
    int? categoryColorValue,
    DateTime? date,
    String? note,
    String? bankId,
    String? bankAccountId,
    String? bankShortName,
    String? accountMask,
    String? targetAccountId,
    List<String>? tags,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIconCode: categoryIconCode ?? this.categoryIconCode,
      categoryColorValue: categoryColorValue ?? this.categoryColorValue,
      date: date ?? this.date,
      note: note ?? this.note,
      bankId: bankId ?? this.bankId,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      bankShortName: bankShortName ?? this.bankShortName,
      accountMask: accountMask ?? this.accountMask,
      targetAccountId: targetAccountId ?? this.targetAccountId,
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
        date,
        note,
        bankId,
        bankAccountId,
        bankShortName,
        accountMask,
        targetAccountId,
        tags,
      ];
}
