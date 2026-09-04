import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction_entity.dart';

enum TransactionStatus { initial, loading, success, failure }
enum TransactionFilterType { all, income, expense }

class TransactionState extends Equatable {
  final TransactionStatus status;
  final List<TransactionEntity> transactions;
  final TransactionFilterType filterType;
  final String? selectedCategoryId;
  final String searchQuery;
  final String? errorMessage;

  const TransactionState({
    this.status = TransactionStatus.initial,
    this.transactions = const [],
    this.filterType = TransactionFilterType.all,
    this.selectedCategoryId,
    this.searchQuery = '',
    this.errorMessage,
  });

  List<TransactionEntity> get filteredTransactions {
    return transactions.where((item) {
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
        if (!matchTitle && !matchCategory && !matchNote) return false;
      }

      return true;
    }).toList();
  }

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
    String? searchQuery,
    String? errorMessage,
  }) {
    return TransactionState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      filterType: filterType ?? this.filterType,
      selectedCategoryId: clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
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
        searchQuery,
        errorMessage,
      ];
}
