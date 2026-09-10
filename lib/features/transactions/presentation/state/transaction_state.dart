import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction_entity.dart';

enum TransactionStatus { initial, loading, success, failure }
enum TransactionFilterType { all, income, expense }

class TransactionState extends Equatable {
  final TransactionStatus status;
  final List<TransactionEntity> transactions;
  final TransactionFilterType filterType;
  final String? selectedCategoryId;
  final String? selectedBankId; // null = All Banks / All Accounts
  final String searchQuery;
  final String? errorMessage;

  const TransactionState({
    this.status = TransactionStatus.initial,
    this.transactions = const [],
    this.filterType = TransactionFilterType.all,
    this.selectedCategoryId,
    this.selectedBankId,
    this.searchQuery = '',
    this.errorMessage,
  });

  List<TransactionEntity> get filteredTransactions {
    return transactions.where((item) {
      // Filter by bank
      if (selectedBankId != null && item.bankId != selectedBankId) return false;

      // Filter by type
      if (filterType == TransactionFilterType.income && !item.isIncome) return false;
      if (filterType == TransactionFilterType.expense && !item.isExpense) return false;

      // Filter by category
      if (selectedCategoryId != null && item.categoryId != selectedCategoryId) return false;

      // Filter by search query
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchTitle = item.title.toLowerCase().contains(query);
        final matchCategory = item.categoryName.toLowerCase().contains(query);
        final matchNote = item.note?.toLowerCase().contains(query) ?? false;
        final matchBank = item.bankShortName?.toLowerCase().contains(query) ?? false;
        if (!matchTitle && !matchCategory && !matchNote && !matchBank) return false;
      }

      return true;
    }).toList();
  }

  /// Get transactions for a specific bank or all banks
  List<TransactionEntity> getTransactionsForBank(String? bankId) {
    if (bankId == null) return transactions;
    return transactions.where((t) => t.bankId == bankId).toList();
  }

  double getBankIncome(String? bankId) {
    final list = getTransactionsForBank(bankId);
    return list
        .where((t) => t.isIncome)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double getBankExpense(String? bankId) {
    final list = getTransactionsForBank(bankId);
    return list
        .where((t) => t.isExpense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double getBankBalance(String? bankId) => getBankIncome(bankId) - getBankExpense(bankId);

  double get totalIncome {
    return transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalExpense {
    return transactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalBalance => totalIncome - totalExpense;

  TransactionState copyWith({
    TransactionStatus? status,
    List<TransactionEntity>? transactions,
    TransactionFilterType? filterType,
    String? selectedCategoryId,
    bool clearCategory = false,
    String? selectedBankId,
    bool clearBank = false,
    String? searchQuery,
    String? errorMessage,
  }) {
    return TransactionState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      filterType: filterType ?? this.filterType,
      selectedCategoryId: clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
      selectedBankId: clearBank ? null : (selectedBankId ?? this.selectedBankId),
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        transactions,
        filterType,
        selectedCategoryId,
        selectedBankId,
        searchQuery,
        errorMessage,
      ];
}
