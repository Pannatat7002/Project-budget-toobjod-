import '../../domain/entities/bank_account_entity.dart';

class BankAccountModel extends BankAccountEntity {
  const BankAccountModel({
    required super.id,
    required super.bankId,
    required super.bankName,
    required super.accountName,
    super.accountMask,
    super.currentBalance = 0.0,
    required super.brandColor,
    super.isAutoSyncActive = true,
    required super.createdAt,
    super.isDefault = false,
  });

  factory BankAccountModel.fromJson(Map<String, dynamic> json) {
    return BankAccountModel(
      id: json['id'] as String,
      bankId: json['bankId'] as String,
      bankName: json['bankName'] as String,
      accountName: json['accountName'] as String,
      accountMask: json['accountMask'] as String?,
      currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0.0,
      brandColor: json['brandColor'] as int? ?? 0xFF2563EB,
      isAutoSyncActive: json['isAutoSyncActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bankId': bankId,
      'bankName': bankName,
      'accountName': accountName,
      'accountMask': accountMask,
      'currentBalance': currentBalance,
      'brandColor': brandColor,
      'isAutoSyncActive': isAutoSyncActive,
      'createdAt': createdAt.toIso8601String(),
      'isDefault': isDefault,
    };
  }

  factory BankAccountModel.fromEntity(BankAccountEntity entity) {
    return BankAccountModel(
      id: entity.id,
      bankId: entity.bankId,
      bankName: entity.bankName,
      accountName: entity.accountName,
      accountMask: entity.accountMask,
      currentBalance: entity.currentBalance,
      brandColor: entity.brandColor,
      isAutoSyncActive: entity.isAutoSyncActive,
      createdAt: entity.createdAt,
      isDefault: entity.isDefault,
    );
  }

  @override
  BankAccountModel copyWith({
    String? id,
    String? bankId,
    String? bankName,
    String? accountName,
    String? accountMask,
    double? currentBalance,
    int? brandColor,
    bool? isAutoSyncActive,
    DateTime? createdAt,
    bool? isDefault,
  }) {
    return BankAccountModel(
      id: id ?? this.id,
      bankId: bankId ?? this.bankId,
      bankName: bankName ?? this.bankName,
      accountName: accountName ?? this.accountName,
      accountMask: accountMask ?? this.accountMask,
      currentBalance: currentBalance ?? this.currentBalance,
      brandColor: brandColor ?? this.brandColor,
      isAutoSyncActive: isAutoSyncActive ?? this.isAutoSyncActive,
      createdAt: createdAt ?? this.createdAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
