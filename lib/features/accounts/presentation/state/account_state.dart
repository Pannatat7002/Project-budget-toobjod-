import 'package:equatable/equatable.dart';
import '../../domain/entities/bank_account_entity.dart';

class AccountState extends Equatable {
  final List<BankAccountEntity> accounts;
  final String? selectedBankId; // null = All Wallets (รวมทุกบัญชี)
  final bool isEyeViewHidden; // true = ซ่อนยอดเงินรวมที่ Card (••••)
  final bool isLoading;
  final String? errorMessage;

  const AccountState({
    this.accounts = const [],
    this.selectedBankId,
    this.isEyeViewHidden = false,
    this.isLoading = false,
    this.errorMessage,
  });

  BankAccountEntity? get selectedAccount {
    if (selectedBankId == null) return null;
    try {
      return accounts.firstWhere((a) => a.bankId == selectedBankId);
    } catch (_) {
      return null;
    }
  }

  AccountState copyWith({
    List<BankAccountEntity>? accounts,
    String? selectedBankId,
    bool clearSelectedBank = false,
    bool? isEyeViewHidden,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AccountState(
      accounts: accounts ?? this.accounts,
      selectedBankId: clearSelectedBank ? null : (selectedBankId ?? this.selectedBankId),
      isEyeViewHidden: isEyeViewHidden ?? this.isEyeViewHidden,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        accounts,
        selectedBankId,
        isEyeViewHidden,
        isLoading,
        errorMessage,
      ];
}
