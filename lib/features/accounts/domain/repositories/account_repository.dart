import '../entities/bank_account_entity.dart';

abstract class AccountRepository {
  Future<List<BankAccountEntity>> getAccounts();
  Future<void> saveAccounts(List<BankAccountEntity> accounts);
  Future<void> addOrUpdateAccount(BankAccountEntity account);
  Future<void> deleteAccount(String id);
  Future<bool> getEyeViewPrivacy();
  Future<void> setEyeViewPrivacy(bool isHidden);
}
