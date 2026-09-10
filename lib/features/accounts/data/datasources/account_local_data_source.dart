import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/bank_account_model.dart';

abstract class AccountLocalDataSource {
  Future<List<BankAccountModel>> getAccounts();
  Future<void> saveAccounts(List<BankAccountModel> accounts);
  Future<void> addOrUpdateAccount(BankAccountModel account);
  Future<void> deleteAccount(String id);
  Future<bool> getEyeViewPrivacy();
  Future<void> setEyeViewPrivacy(bool isHidden);
}

class AccountLocalDataSourceImpl implements AccountLocalDataSource {
  final SharedPreferences sharedPreferences;

  AccountLocalDataSourceImpl({required this.sharedPreferences});

  static final List<BankAccountModel> _defaultAccounts = [
    BankAccountModel(
      id: 'acc_kbank',
      bankId: 'kbank',
      bankName: 'ธนาคารกสิกรไทย (K PLUS)',
      accountName: 'บัญชีหลัก K PLUS',
      accountMask: '4521',
      currentBalance: 0.0,
      brandColor: 0xFF138F2D,
      isAutoSyncActive: true,
      createdAt: DateTime.now(),
      isDefault: true,
    ),
  ];

  @override
  Future<List<BankAccountModel>> getAccounts() async {
    try {
      final jsonString = sharedPreferences.getString(AppConstants.accountsStorageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final list = jsonList
            .map((item) => BankAccountModel.fromJson(item as Map<String, dynamic>))
            .where((acc) => acc.bankId != 'cash')
            .toList();
        if (list.isEmpty) {
          await saveAccounts(_defaultAccounts);
          return _defaultAccounts;
        }
        return list;
      } else {
        // Save initial default accounts
        await saveAccounts(_defaultAccounts);
        return _defaultAccounts;
      }
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> saveAccounts(List<BankAccountModel> accounts) async {
    try {
      final jsonList = accounts.map((a) => a.toJson()).toList();
      await sharedPreferences.setString(
        AppConstants.accountsStorageKey,
        jsonEncode(jsonList),
      );
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> addOrUpdateAccount(BankAccountModel account) async {
    final accounts = await getAccounts();
    final index = accounts.indexWhere((a) => a.id == account.id);
    if (index != -1) {
      accounts[index] = account;
    } else {
      accounts.add(account);
    }
    await saveAccounts(accounts);
  }

  @override
  Future<void> deleteAccount(String id) async {
    final accounts = await getAccounts();
    accounts.removeWhere((a) => a.id == id);
    await saveAccounts(accounts);
  }

  @override
  Future<bool> getEyeViewPrivacy() async {
    return sharedPreferences.getBool(AppConstants.accountEyeViewKey) ?? false;
  }

  @override
  Future<void> setEyeViewPrivacy(bool isHidden) async {
    await sharedPreferences.setBool(AppConstants.accountEyeViewKey, isHidden);
  }
}
