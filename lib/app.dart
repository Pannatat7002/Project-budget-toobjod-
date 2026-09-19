import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'config/routes/app_router.dart';
import 'config/theme/app_theme.dart';
import 'features/accounts/presentation/state/account_cubit.dart';
import 'features/auto_sync/presentation/state/auto_sync_cubit.dart';
import 'features/budget/presentation/state/budget_cubit.dart';
import 'features/settings/presentation/state/theme_cubit.dart';
import 'features/transactions/presentation/state/transaction_cubit.dart';
import 'features/transactions/presentation/state/transaction_state.dart';
import 'injection_container.dart' as di;

class BudgetPlannerApp extends StatefulWidget {
  const BudgetPlannerApp({super.key});

  @override
  State<BudgetPlannerApp> createState() => _BudgetPlannerAppState();
}

class _BudgetPlannerAppState extends State<BudgetPlannerApp>
    with WidgetsBindingObserver {
  late final AccountCubit _accountCubit;
  late final AutoSyncCubit _autoSyncCubit;
  late final TransactionCubit _transactionCubit;
  late final BudgetCubit _budgetCubit;
  late final ThemeCubit _themeCubit;
  StreamSubscription<TransactionState>? _txSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _accountCubit = di.sl<AccountCubit>()..loadAccounts();
    _transactionCubit = di.sl<TransactionCubit>()..loadTransactions();
    _budgetCubit = di.sl<BudgetCubit>()..loadBudgets();
    _autoSyncCubit = di.sl<AutoSyncCubit>()..initialize();
    _themeCubit = ThemeCubit()..loadTheme();

    _txSubscription = _transactionCubit.stream.listen((txState) {
      if (txState.status == TransactionStatus.success) {
        _budgetCubit.updateWithTransactions(txState.transactions);
        _accountCubit.refreshBalancesFromTransactions(txState.transactions);
      }
    });
  }

  @override
  void dispose() {
    _txSubscription?.cancel();
    _themeCubit.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _autoSyncCubit.syncNativeBuffer();
      _autoSyncCubit.checkPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AccountCubit>.value(value: _accountCubit),
        BlocProvider<TransactionCubit>.value(value: _transactionCubit),
        BlocProvider<BudgetCubit>.value(value: _budgetCubit),
        BlocProvider<AutoSyncCubit>.value(value: _autoSyncCubit),
        BlocProvider<ThemeCubit>.value(value: _themeCubit),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        bloc: _themeCubit,
        builder: (context, themeMode) => MaterialApp.router(
          title: 'Budget Planner',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
