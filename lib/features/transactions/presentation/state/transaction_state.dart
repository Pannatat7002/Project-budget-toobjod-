import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction_entity.dart';

enum TransactionStatus { initial, loading, success, failure }

enum TransactionFilterType { all, income, expense }

class TransactionState extends Equatable {
  final List<TransactionEntity> transactions;
  final TransactionStatus status;
  final TransactionFilterType filterType;
  final String? selectedCategoryId;
  final String? selectedBankId;
  final String searchQuery;
  final String? errorMessage;

  const TransactionState({
    this.transactions = const [],
    this.status = TransactionStatus.initial,
    this.filterType = TransactionFilterType.all,
    this.selectedCategoryId,
    this.selectedBankId,
    this.searchQuery = '',
    this.errorMessage,
  });

  TransactionState copyWith({
    List<TransactionEntity>? transactions,
    TransactionStatus? status,
    TransactionFilterType? filterType,
    String? selectedCategoryId,
    bool clearCategory = false,
    String? selectedBankId,
    bool clearBank = false,
    String? searchQuery,
    String? errorMessage,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      status: status ?? this.status,
      filterType: filterType ?? this.filterType,
      selectedCategoryId: clearCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      selectedBankId:
          clearBank ? null : (selectedBankId ?? this.selectedBankId),
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Get transactions for a specific bank account or bank profile ID
  /// (includes incoming and outgoing transfers)
  List<TransactionEntity> getTransactionsForBank(String? bankId) {
    if (bankId == null) return transactions;
    return transactions.where((t) {
      final isSource = t.bankAccountId == bankId || t.bankId == bankId;
      final isTarget = t.isTransfer && t.targetAccountId == bankId;
      return isSource || isTarget;
    }).toList();
  }

  /// Calculate total income for a specific bank (or all if null)
  /// (regular income into bank + incoming transfers into this bank)
  double getBankIncome(String? bankId) {
    if (bankId == null) return totalIncome;
    return transactions.where((t) {
      if (t.isIncome) {
        return t.bankAccountId == bankId || t.bankId == bankId;
      } else if (t.isTransfer) {
        return t.targetAccountId == bankId;
      }
      return false;
    }).fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Calculate total expense for a specific bank (or all if null)
  /// (regular expense from bank + outgoing transfers from this bank)
  double getBankExpense(String? bankId) {
    if (bankId == null) return totalExpense;
    return transactions.where((t) {
      if (t.isExpense) {
        return t.bankAccountId == bankId || t.bankId == bankId;
      } else if (t.isTransfer) {
        return t.bankAccountId == bankId || t.bankId == bankId;
      }
      return false;
    }).fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Calculate net balance for a specific bank (or total balance if null)
  double getBankBalance(String? bankId) {
    if (bankId == null) return balance;
    return getBankIncome(bankId) - getBankExpense(bankId);
  }

  /// Filtered transactions based on active filters in Transactions tab
  List<TransactionEntity> get filteredTransactions {
    return transactions.where((t) {
      // 1. Bank Filter (Checks both source and target for transfers)
      if (selectedBankId != null) {
        final isSource = t.bankAccountId == selectedBankId || t.bankId == selectedBankId;
        final isTarget = t.isTransfer && t.targetAccountId == selectedBankId;
        if (!isSource && !isTarget) return false;
      }

      // 2. Type Filter
      if (filterType == TransactionFilterType.income) {
        if (t.isTransfer) {
          if (selectedBankId != null && t.targetAccountId != selectedBankId) {
            return false;
          }
        } else if (!t.isIncome) {
          return false;
        }
      } else if (filterType == TransactionFilterType.expense) {
        if (t.isTransfer) {
          if (selectedBankId != null &&
              (t.bankAccountId != selectedBankId && t.bankId != selectedBankId)) {
            return false;
          }
        } else if (!t.isExpense) {
          return false;
        }
      }

      // 3. Category Filter
      if (selectedCategoryId != null && t.categoryId != selectedCategoryId) {
        return false;
      }

      // 4. Search Query Filter
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchTitle = t.title.toLowerCase().contains(query);
        final matchCategory = t.categoryName.toLowerCase().contains(query);
        final matchNote = (t.note ?? '').toLowerCase().contains(query);
        final matchBank = (t.bankShortName ?? '').toLowerCase().contains(query);
        if (!matchTitle && !matchCategory && !matchNote && !matchBank) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  double get totalIncome => transactions
      .where((t) => t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense => transactions
      .where((t) => t.isExpense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;

  double get totalBalance => balance;

  @override
  List<Object?> get props => [
        transactions,
        status,
        filterType,
        selectedCategoryId,
        selectedBankId,
        searchQuery,
        errorMessage,
      ];
}
