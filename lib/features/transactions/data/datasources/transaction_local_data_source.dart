import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/transaction_model.dart';

abstract class TransactionLocalDataSource {
  Future<List<TransactionModel>> getTransactions();
  Future<void> saveTransactions(List<TransactionModel> transactions);
  Future<void> addTransaction(TransactionModel transaction);
  Future<void> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String transactionId);
}

class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  final SharedPreferences sharedPreferences;

  TransactionLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<TransactionModel>> getTransactions() async {
    try {
      final jsonString = sharedPreferences.getString(AppConstants.transactionsStorageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final transactions = jsonList
            .map((item) => TransactionModel.fromJson(item as Map<String, dynamic>))
            .where((t) => !t.id.startsWith('mock_'))
            .toList();
        if (transactions.length != jsonList.length) {
          await saveTransactions(transactions);
        }
        // Sort descending by date
        transactions.sort((a, b) => b.date.compareTo(a.date));
        return transactions;
      } else {
        return [];
      }
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> saveTransactions(List<TransactionModel> transactions) async {
    try {
      final jsonList = transactions.map((t) => t.toJson()).toList();
      await sharedPreferences.setString(AppConstants.transactionsStorageKey, jsonEncode(jsonList));
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    final list = await getTransactions();
    final index = list.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      list[index] = transaction;
    } else {
      list.insert(0, transaction);
    }
    await saveTransactions(list);
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    final list = await getTransactions();
    final index = list.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      list[index] = transaction;
      await saveTransactions(list);
    }
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    final list = await getTransactions();
    list.removeWhere((t) => t.id == transactionId);
    await saveTransactions(list);
  }
}
