import '../../domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.title,
    required super.amount,
    required super.type,
    required super.categoryId,
    required super.categoryName,
    required super.categoryIconCode,
    required super.categoryColorValue,
    required super.date,
    super.note,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: (json['type'] as String) == 'income' ? TransactionType.income : TransactionType.expense,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      categoryIconCode: json['categoryIconCode'] as int,
      categoryColorValue: json['categoryColorValue'] as int,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type == TransactionType.income ? 'income' : 'expense',
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryIconCode': categoryIconCode,
      'categoryColorValue': categoryColorValue,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      title: entity.title,
      amount: entity.amount,
      type: entity.type,
      categoryId: entity.categoryId,
      categoryName: entity.categoryName,
      categoryIconCode: entity.categoryIconCode,
      categoryColorValue: entity.categoryColorValue,
      date: entity.date,
      note: entity.note,
    );
  }
}
