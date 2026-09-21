import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../domain/entities/bank_account_entity.dart';
import '../../domain/repositories/account_repository.dart';
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
        errorMessage: 'ไม่สามารถโหลดบัญชีได้: $e',
      ));
    }
  }

  Future<void> addAccount(BankAccountEntity account) async {
    try {
      await repository.addOrUpdateAccount(account);
      await loadAccounts();
    } catch (e) {
      emit(state.copyWith(errorMessage: 'ไม่สามารถเพิ่มบัญชีได้: $e'));
    }
  }

  Future<void> updateAccount(BankAccountEntity account) async {
    try {
      await repository.addOrUpdateAccount(account);
      await loadAccounts();
    } catch (e) {
      emit(state.copyWith(errorMessage: 'ไม่สามารถแก้ไขบัญชีได้: $e'));
    }
  }

  Future<void> addOrUpdateAccount(BankAccountEntity account) async {
    try {
      await repository.addOrUpdateAccount(account);
      await loadAccounts();
    } catch (e) {
      emit(state.copyWith(errorMessage: 'ไม่สามารถบันทึกบัญชีได้: $e'));
    }
  }

  Future<void> deleteAccount(String id) async {
    try {
      await repository.deleteAccount(id);
      await loadAccounts();
    } catch (e) {
      emit(state.copyWith(errorMessage: 'ไม่สามารถลบบัญชีได้: $e'));
    }
  }

  void selectBank(String? bankId) {
    emit(state.copyWith(
      selectedBankId: bankId,
      clearSelectedBank: bankId == null,
    ));
  }

  Future<void> toggleEyeView() async {
    final nextState = !state.isEyeViewHidden;
    emit(state.copyWith(isEyeViewHidden: nextState));
    await repository.setEyeViewPrivacy(nextState);
  }

  /// Recalculates balance of each account from transactions
  /// including normal income, expense, and transfer (between source & target accounts)
  Future<void> refreshBalancesFromTransactions(
    List<TransactionEntity> transactions,
  ) async {
    if (state.accounts.isEmpty) return;

    final updatedAccounts = state.accounts.map((acc) {
      double current = 0.0;

      for (final t in transactions) {
        final isSourceMatch =
            t.bankAccountId == acc.id || t.bankId == acc.bankId;
        final isTargetMatch =
            t.targetAccountId == acc.id || t.targetAccountId == acc.bankId;

        if (t.isIncome && isSourceMatch) {
          current += t.amount;
        } else if (t.isExpense && isSourceMatch) {
          current -= t.amount;
        } else if (t.isTransfer) {
          if (isSourceMatch) {
            current -= t.amount;
          }
          if (isTargetMatch) {
            current += t.amount;
          }
        }
      }

      return acc.copyWith(currentBalance: current);
    }).toList();

    emit(state.copyWith(accounts: updatedAccounts));
    await repository.saveAccounts(updatedAccounts);
  }
}
