import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/bank_account_entity.dart';
import '../../domain/repositories/account_repository.dart';
import '../../../auto_sync/domain/entities/bank_profile.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import 'account_state.dart';

class AccountCubit extends Cubit<AccountState> {
  final AccountRepository repository;

  AccountCubit({required this.repository}) : super(const AccountState());

  Future<void> loadAccounts() async {
    emit(state.copyWith(isLoading: true));
    try {
      final accounts = await repository.getAccounts();
      final isEyeHidden = await repository.getEyeViewPrivacy();
      emit(state.copyWith(
        accounts: accounts,
        isEyeViewHidden: isEyeHidden,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'ไม่สามารถโหลดบัญชี: $e',
      ));
    }
  }

  void selectBank(String? bankId) {
    if (bankId == null) {
      emit(state.copyWith(clearSelectedBank: true));
    } else {
      emit(state.copyWith(selectedBankId: bankId));
    }
  }

  Future<void> toggleEyeView() async {
    final nextVal = !state.isEyeViewHidden;
    await repository.setEyeViewPrivacy(nextVal);
    emit(state.copyWith(isEyeViewHidden: nextVal));
  }

  Future<void> addOrUpdateAccount(BankAccountEntity account) async {
    await repository.addOrUpdateAccount(account);
    await loadAccounts();
  }

  Future<void> deleteAccount(String id) async {
    await repository.deleteAccount(id);
    await loadAccounts();
  }

  /// Auto-Discovery: Ensure an account exists for this bankId
  Future<BankAccountEntity> ensureAccountForBank(
    String bankId, {
    String? accountMask,
    String? bankName,
    int? brandColor,
  }) async {
    final existing = state.accounts.where((a) => a.bankId == bankId).toList();
    if (existing.isNotEmpty) {
      // If we have an existing account and accountMask matches or is empty, return it
      if (accountMask == null) return existing.first;
      final matched = existing.firstWhere(
        (a) => a.accountMask == accountMask,
        orElse: () => existing.first,
      );
      return matched;
    }

    // Auto-create new account
    final profile = BankProfile.findById(bankId);
    final finalName = bankName ?? profile?.name ?? bankId.toUpperCase();
    final finalColor = brandColor ?? profile?.brandColor ?? 0xFF2563EB;
    final newId = 'acc_${bankId}_${DateTime.now().millisecondsSinceEpoch % 10000}';

    final newAccount = BankAccountEntity(
      id: newId,
      bankId: bankId,
      bankName: finalName,
      accountName: profile?.shortName ?? finalName,
      accountMask: accountMask,
      currentBalance: 0.0,
      brandColor: finalColor,
      isAutoSyncActive: true,
      createdAt: DateTime.now(),
    );

    await repository.addOrUpdateAccount(newAccount);
    final updatedList = List<BankAccountEntity>.from(state.accounts)..add(newAccount);
    emit(state.copyWith(accounts: updatedList));
    return newAccount;
  }

  /// Calculate balances for each account from transaction list
  void refreshBalancesFromTransactions(List<TransactionEntity> transactions) {
    if (state.accounts.isEmpty) return;

    final updated = state.accounts.map((acc) {
      double incomeSum = 0.0;
      double expenseSum = 0.0;

      for (final tx in transactions) {
        if (tx.bankId == acc.bankId || (tx.bankAccountId == acc.id)) {
          if (tx.type == TransactionType.income) {
            incomeSum += tx.amount;
          } else if (tx.type == TransactionType.expense) {
            expenseSum += tx.amount;
          }
        }
      }

      final balance = incomeSum - expenseSum;
      return acc.copyWith(currentBalance: balance);
    }).toList();

    // Guard: only emit if any balance actually changed
    bool changed = false;
    for (int i = 0; i < updated.length; i++) {
      if (updated[i].currentBalance != state.accounts[i].currentBalance) {
        changed = true;
        break;
      }
    }
    if (!changed) return;

    emit(state.copyWith(accounts: updated));
  }
}
