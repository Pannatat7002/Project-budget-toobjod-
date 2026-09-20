import '../datasources/account_local_data_source.dart';
import '../models/bank_account_model.dart';
import '../../domain/entities/bank_account_entity.dart';
import '../../domain/repositories/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AccountLocalDataSource localDataSource;

  AccountRepositoryImpl({required this.localDataSource});

  @override
  Future<List<BankAccountEntity>> getAccounts() async {
    final models = await localDataSource.getAccounts();
    return models
        .map(
          (m) => BankAccountEntity(
            id: m.id,
            bankId: m.bankId,
            bankName: m.bankName,
            accountName: m.accountName,
            accountMask: m.accountMask,
            currentBalance: m.currentBalance,
            brandColor: m.brandColor,
            isAutoSyncActive: m.isAutoSyncActive,
            createdAt: m.createdAt,
            isDefault: m.isDefault,
          ),
        )
        .toList();
  }

  @override
  Future<void> saveAccounts(List<BankAccountEntity> accounts) async {
    final models = accounts.map((a) => BankAccountModel.fromEntity(a)).toList();
    await localDataSource.saveAccounts(models);
  }

  @override
  Future<void> addOrUpdateAccount(BankAccountEntity account) async {
    final model = BankAccountModel.fromEntity(account);
    await localDataSource.addOrUpdateAccount(model);
  }

  @override
  Future<void> deleteAccount(String id) async {
    await localDataSource.deleteAccount(id);
  }

  @override
  Future<bool> getEyeViewPrivacy() async {
    return await localDataSource.getEyeViewPrivacy();
  }

  @override
  Future<void> setEyeViewPrivacy(bool isHidden) async {
    await localDataSource.setEyeViewPrivacy(isHidden);
  }
}
