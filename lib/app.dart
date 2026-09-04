import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'config/routes/app_router.dart';
import 'config/theme/app_theme.dart';
import 'features/auto_sync/presentation/state/auto_sync_cubit.dart';
import 'features/budget/presentation/state/budget_cubit.dart';
import 'features/spending_plan/presentation/state/spending_plan_cubit.dart';
import 'features/transactions/presentation/state/transaction_cubit.dart';
import 'injection_container.dart' as di;

class BudgetPlannerApp extends StatefulWidget {
  const BudgetPlannerApp({super.key});

  @override
  State<BudgetPlannerApp> createState() => _BudgetPlannerAppState();
}

class _BudgetPlannerAppState extends State<BudgetPlannerApp> with WidgetsBindingObserver {
  late final AutoSyncCubit _autoSyncCubit;
  late final TransactionCubit _transactionCubit;
  late final BudgetCubit _budgetCubit;
  late final SpendingPlanCubit _spendingPlanCubit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _transactionCubit = di.sl<TransactionCubit>()..loadTransactions();
    _budgetCubit = di.sl<BudgetCubit>()..loadBudgets();
    _spendingPlanCubit = di.sl<SpendingPlanCubit>()..loadPlan();
    _autoSyncCubit = di.sl<AutoSyncCubit>()..initialize();
  }

  @override
  void dispose() {
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
        BlocProvider<TransactionCubit>.value(value: _transactionCubit),
        BlocProvider<BudgetCubit>.value(value: _budgetCubit),
        BlocProvider<SpendingPlanCubit>.value(value: _spendingPlanCubit),
        BlocProvider<AutoSyncCubit>.value(value: _autoSyncCubit),
      ],
      child: MaterialApp.router(
        title: 'Budget Planner',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
