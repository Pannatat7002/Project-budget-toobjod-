import 'package:equatable/equatable.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';

class DetectedTransaction extends Equatable {
  final String id;
  final String packageName;
  final String bankId;
  final String bankName;
  final String bankShortName;
  final int bankColorValue;
  final String? bankAccountId;
  final String? accountMask;
  final double amount;
  final TransactionType type;
  final String title;
  final String suggestedCategoryId;
  final String suggestedCategoryName;
  final int suggestedCategoryIconCode;
  final int suggestedCategoryColorValue;
  final String? merchantOrSender;
  final String? rawTitle;
  final String? rawText;
  final DateTime timestamp;
  final bool isSaved;
  final bool isDiscarded;

  const DetectedTransaction({
    required this.id,
    required this.packageName,
    this.bankId = 'kbank',
    required this.bankName,
    required this.bankShortName,
    required this.bankColorValue,
    this.bankAccountId,
    this.accountMask,
    required this.amount,
    required this.type,
    required this.title,
    required this.suggestedCategoryId,
    required this.suggestedCategoryName,
    required this.suggestedCategoryIconCode,
    required this.suggestedCategoryColorValue,
    this.merchantOrSender,
    this.rawTitle,
    this.rawText,
    required this.timestamp,
    this.isSaved = false,
    this.isDiscarded = false,
  });

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  DetectedTransaction copyWith({
    String? id,
    String? packageName,
    String? bankId,
    String? bankName,
    String? bankShortName,
    int? bankColorValue,
    String? bankAccountId,
    String? accountMask,
    double? amount,
    TransactionType? type,
    String? title,
    String? suggestedCategoryId,
    String? suggestedCategoryName,
    int? suggestedCategoryIconCode,
    int? suggestedCategoryColorValue,
    String? merchantOrSender,
    String? rawTitle,
    String? rawText,
    DateTime? timestamp,
    bool? isSaved,
    bool? isDiscarded,
  }) {
    return DetectedTransaction(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      bankId: bankId ?? this.bankId,
      bankName: bankName ?? this.bankName,
      bankShortName: bankShortName ?? this.bankShortName,
      bankColorValue: bankColorValue ?? this.bankColorValue,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      accountMask: accountMask ?? this.accountMask,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      title: title ?? this.title,
      suggestedCategoryId: suggestedCategoryId ?? this.suggestedCategoryId,
      suggestedCategoryName: suggestedCategoryName ?? this.suggestedCategoryName,
      suggestedCategoryIconCode: suggestedCategoryIconCode ?? this.suggestedCategoryIconCode,
      suggestedCategoryColorValue: suggestedCategoryColorValue ?? this.suggestedCategoryColorValue,
      merchantOrSender: merchantOrSender ?? this.merchantOrSender,
      rawTitle: rawTitle ?? this.rawTitle,
      rawText: rawText ?? this.rawText,
      timestamp: timestamp ?? this.timestamp,
      isSaved: isSaved ?? this.isSaved,
      isDiscarded: isDiscarded ?? this.isDiscarded,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'packageName': packageName,
      'bankId': bankId,
      'bankName': bankName,
      'bankShortName': bankShortName,
      'bankColorValue': bankColorValue,
      'bankAccountId': bankAccountId,
      'accountMask': accountMask,
      'amount': amount,
      'type': type == TransactionType.income ? 'income' : 'expense',
      'title': title,
      'suggestedCategoryId': suggestedCategoryId,
      'suggestedCategoryName': suggestedCategoryName,
      'suggestedCategoryIconCode': suggestedCategoryIconCode,
      'suggestedCategoryColorValue': suggestedCategoryColorValue,
      'merchantOrSender': merchantOrSender,
      'rawTitle': rawTitle,
      'rawText': rawText,
      'timestamp': timestamp.toIso8601String(),
      'isSaved': isSaved,
      'isDiscarded': isDiscarded,
    };
  }

  factory DetectedTransaction.fromJson(Map<String, dynamic> json) {
    return DetectedTransaction(
      id: json['id'] as String,
      packageName: json['packageName'] as String,
      bankId: json['bankId'] as String? ?? 'kbank',
      bankName: json['bankName'] as String,
      bankShortName: json['bankShortName'] as String,
      bankColorValue: json['bankColorValue'] as int,
      bankAccountId: json['bankAccountId'] as String?,
      accountMask: json['accountMask'] as String?,
      amount: (json['amount'] as num).toDouble(),
      type: (json['type'] as String) == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      title: json['title'] as String,
      suggestedCategoryId: json['suggestedCategoryId'] as String,
      suggestedCategoryName: json['suggestedCategoryName'] as String,
      suggestedCategoryIconCode: json['suggestedCategoryIconCode'] as int,
      suggestedCategoryColorValue: json['suggestedCategoryColorValue'] as int,
      merchantOrSender: json['merchantOrSender'] as String?,
      rawTitle: json['rawTitle'] as String?,
      rawText: json['rawText'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isSaved: json['isSaved'] as bool? ?? false,
      isDiscarded: json['isDiscarded'] as bool? ?? false,
    );
  }

  TransactionEntity toTransactionEntity() {
    return TransactionEntity(
      id: id,
      title: title,
      amount: amount,
      type: type,
      categoryId: suggestedCategoryId,
      categoryName: suggestedCategoryName,
      categoryIconCode: suggestedCategoryIconCode,
      categoryColorValue: suggestedCategoryColorValue,
      date: timestamp,
      note: (rawText != null && rawText!.isNotEmpty)
          ? rawText
          : 'ตรวจจับอัตโนมัติจาก $bankShortName${merchantOrSender != null ? ' ($merchantOrSender)' : ''}',
      bankId: bankId,
      bankAccountId: bankAccountId,
      bankShortName: bankShortName,
      accountMask: accountMask,
    );
  }

  @override
  List<Object?> get props => [
        id,
        packageName,
        bankId,
        bankName,
        bankShortName,
        bankColorValue,
        bankAccountId,
        accountMask,
        amount,
        type,
        title,
        suggestedCategoryId,
        suggestedCategoryName,
        suggestedCategoryIconCode,
        suggestedCategoryColorValue,
        merchantOrSender,
        rawTitle,
        rawText,
        timestamp,
        isSaved,
        isDiscarded,
      ];
}
