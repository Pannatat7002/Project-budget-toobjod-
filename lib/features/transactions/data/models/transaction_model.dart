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
    super.bankId,
    super.bankAccountId,
    super.bankShortName,
    super.accountMask,
    super.targetAccountId,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'expense';
    final type = typeStr == 'income'
        ? TransactionType.income
        : typeStr == 'transfer'
            ? TransactionType.transfer
            : TransactionType.expense;

    // Backward compatibility: detect bankId from note or title if missing or cash
    String? bankId = json['bankId'] as String?;
    String? bankShortName = json['bankShortName'] as String?;
    if (bankId == null || bankId == 'cash') {
      final text = '${json['title'] ?? ''} ${json['note'] ?? ''}'.toLowerCase();
      if (text.contains('k plus') || text.contains('kbank') || text.contains('กสิกร')) {
        bankId = 'kbank';
        bankShortName = 'K PLUS';
      } else if (text.contains('scb') || text.contains('ไทยพาณิชย์')) {
        bankId = 'scb';
        bankShortName = 'SCB EASY';
      } else if (text.contains('next') || text.contains('กรุงไทย') || text.contains('ktb')) {
        bankId = 'ktb';
        bankShortName = 'Krungthai NEXT';
      } else if (text.contains('truemoney') || text.contains('ทรูมันนี่')) {
        bankId = 'truemoney';
        bankShortName = 'TrueMoney';
      } else if (text.contains('ttb') || text.contains('ทีทีบี')) {
        bankId = 'ttb';
        bankShortName = 'ttb touch';
      } else if (text.contains('kma') || text.contains('กรุงศรี')) {
        bankId = 'kma';
        bankShortName = 'KMA Krungsri';
      } else {
        bankId = 'kbank';
        bankShortName = 'K PLUS';
      }
    }

    return TransactionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: type,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      categoryIconCode: json['categoryIconCode'] as int,
      categoryColorValue: json['categoryColorValue'] as int,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
      bankId: bankId,
      bankAccountId: json['bankAccountId'] as String?,
      bankShortName: bankShortName,
      accountMask: json['accountMask'] as String?,
      targetAccountId: json['targetAccountId'] as String?,
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
      'date': date.toIso8601String(),
      'note': note,
      'bankId': bankId,
      'bankAccountId': bankAccountId,
      'bankShortName': bankShortName,
      'accountMask': accountMask,
      'targetAccountId': targetAccountId,
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
      bankId: entity.bankId,
      bankAccountId: entity.bankAccountId,
      bankShortName: entity.bankShortName,
      accountMask: entity.accountMask,
      targetAccountId: entity.targetAccountId,
    );
  }
}
