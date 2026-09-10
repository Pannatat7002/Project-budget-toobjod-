import 'package:equatable/equatable.dart';
import '../../../auto_sync/domain/entities/bank_profile.dart';

class BankAccountEntity extends Equatable {
  final String id;
  final String bankId;
  final String bankName;
  final String accountName;
  final String? accountMask;
  final double currentBalance;
  final int brandColor;
  final bool isAutoSyncActive;
  final DateTime createdAt;
  final bool isDefault;

  const BankAccountEntity({
    required this.id,
    required this.bankId,
    required this.bankName,
    required this.accountName,
    this.accountMask,
    this.currentBalance = 0.0,
    required this.brandColor,
    this.isAutoSyncActive = true,
    required this.createdAt,
    this.isDefault = false,
  });

  String get shortName {
    final profile = BankProfile.findById(bankId);
    return profile?.shortName ?? bankName;
  }

  String get logoAsset => 'assets/images/banks/$bankId.png';

  BankAccountEntity copyWith({
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
    return BankAccountEntity(
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

  @override
  List<Object?> get props => [
        id,
        bankId,
        bankName,
        accountName,
        accountMask,
        currentBalance,
        brandColor,
        isAutoSyncActive,
        createdAt,
        isDefault,
      ];
}
