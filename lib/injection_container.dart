import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Features - Transactions
import 'features/transactions/data/datasources/transaction_local_data_source.dart';
import 'features/transactions/data/repositories/transaction_repository_impl.dart';
import 'features/transactions/domain/repositories/transaction_repository.dart';
import 'features/transactions/domain/usecases/add_transaction.dart';
import 'features/transactions/domain/usecases/delete_transaction.dart';
import 'features/transactions/domain/usecases/get_transactions.dart';
import 'features/transactions/domain/usecases/update_transaction.dart';
import 'features/transactions/presentation/state/transaction_cubit.dart';

// Features - Budget
import 'features/budget/data/datasources/budget_local_data_source.dart';
import 'features/budget/data/repositories/budget_repository_impl.dart';
import 'features/budget/domain/repositories/budget_repository.dart';
import 'features/budget/domain/usecases/delete_budget.dart';
import 'features/budget/domain/usecases/get_budgets.dart';
import 'features/budget/domain/usecases/set_budget.dart';
import 'features/budget/presentation/state/budget_cubit.dart';

// Features - Spending Plan
import 'features/spending_plan/data/datasources/spending_plan_local_data_source.dart';
import 'features/spending_plan/data/repositories/spending_plan_repository_impl.dart';
import 'features/spending_plan/domain/repositories/spending_plan_repository.dart';
import 'features/spending_plan/domain/usecases/get_spending_plan.dart';
import 'features/spending_plan/domain/usecases/save_spending_plan.dart';
import 'features/spending_plan/presentation/state/spending_plan_cubit.dart';

// Features - Accounts (Multi-Bank & Privacy)
import 'features/accounts/data/datasources/account_local_data_source.dart';
import 'features/accounts/data/repositories/account_repository_impl.dart';
import 'features/accounts/domain/repositories/account_repository.dart';
import 'features/accounts/presentation/state/account_cubit.dart';

// Features - Auto Sync (NotificationListenerService)
import 'features/auto_sync/data/datasources/auto_sync_local_data_source.dart';
import 'features/auto_sync/data/repositories/auto_sync_repository_impl.dart';
import 'features/auto_sync/domain/repositories/auto_sync_repository.dart';
import 'features/auto_sync/presentation/state/auto_sync_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Transactions
  // Cubit
  sl.registerLazySingleton(
    () => TransactionCubit(
      getTransactionsUseCase: sl(),
      addTransactionUseCase: sl(),
      deleteTransactionUseCase: sl(),
      updateTransactionUseCase: sl(),
    ),
  );

  // UseCases
  sl.registerLazySingleton(() => GetTransactionsUseCase(sl()));
  sl.registerLazySingleton(() => AddTransactionUseCase(sl()));
  sl.registerLazySingleton(() => DeleteTransactionUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTransactionUseCase(sl()));

  // Repository
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(localDataSource: sl()),
  );

  // DataSource
  sl.registerLazySingleton<TransactionLocalDataSource>(
    () => TransactionLocalDataSourceImpl(sharedPreferences: sl()),
  );

  //! Features - Budget
  // Cubit
  sl.registerLazySingleton(
    () => BudgetCubit(
      getBudgetsUseCase: sl(),
      setBudgetUseCase: sl(),
      deleteBudgetUseCase: sl(),
    ),
  );

  // UseCases
  sl.registerLazySingleton(() => GetBudgetsUseCase(sl()));
  sl.registerLazySingleton(() => SetBudgetUseCase(sl()));
  sl.registerLazySingleton(() => DeleteBudgetUseCase(sl()));

  // Repository
  sl.registerLazySingleton<BudgetRepository>(
    () => BudgetRepositoryImpl(localDataSource: sl()),
  );

  // DataSource
  sl.registerLazySingleton<BudgetLocalDataSource>(
    () => BudgetLocalDataSourceImpl(sharedPreferences: sl()),
  );

  //! Features - Spending Plan
  // Cubit
  sl.registerLazySingleton(
    () => SpendingPlanCubit(
      getSpendingPlanUseCase: sl(),
      saveSpendingPlanUseCase: sl(),
    ),
  );

  // UseCases
  sl.registerLazySingleton(() => GetSpendingPlanUseCase(sl()));
  sl.registerLazySingleton(() => SaveSpendingPlanUseCase(sl()));

  // Repository
  sl.registerLazySingleton<SpendingPlanRepository>(
    () => SpendingPlanRepositoryImpl(localDataSource: sl()),
  );

  // DataSource
  sl.registerLazySingleton<SpendingPlanLocalDataSource>(
    () => SpendingPlanLocalDataSourceImpl(sharedPreferences: sl()),
  );

  //! Features - Accounts (Multi-Bank & Privacy)
  sl.registerLazySingleton(
    () => AccountCubit(repository: sl()),
  );
  sl.registerLazySingleton<AccountRepository>(
    () => AccountRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<AccountLocalDataSource>(
    () => AccountLocalDataSourceImpl(sharedPreferences: sl()),
  );

  //! Features - Auto Sync (NotificationListenerService)
  // Cubit
  sl.registerLazySingleton(
    () => AutoSyncCubit(
      repository: sl(),
      transactionCubit: sl(),
      accountCubit: sl(),
    ),
  );

  // Repository
  sl.registerLazySingleton<AutoSyncRepository>(
    () => AutoSyncRepositoryImpl(localDataSource: sl()),
  );

  // DataSource
  sl.registerLazySingleton<AutoSyncLocalDataSource>(
    () => AutoSyncLocalDataSourceImpl(sharedPreferences: sl()),
  );

  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
}
