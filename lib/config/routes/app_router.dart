import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../injection_container.dart' as di;
import '../../features/analytics/presentation/views/analytics_view.dart';
import '../../features/auto_sync/presentation/views/auto_sync_settings_view.dart';
import '../../features/auto_sync/presentation/views/bank_selection_view.dart';
import '../../features/auto_sync/presentation/views/notification_permission_view.dart';
import '../../features/auto_sync/presentation/views/swipe_history_view.dart';
import '../../features/budget/presentation/views/budget_view.dart';
import '../../features/dashboard/presentation/views/dashboard_view.dart';
import '../../features/security/domain/models/pin_mode.dart';
import '../../features/security/presentation/views/pin_screen.dart';
import '../../features/security/presentation/views/security_settings_view.dart';
import '../../features/splash/presentation/views/splash_view.dart';
import '../../features/transactions/presentation/views/transactions_view.dart';
import '../../shared/widgets/app_bottom_nav_bar.dart';
import '../../shared/widgets/toob_jod_ai_dialog.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

String _determineInitialLocation() {
  try {
    final prefs = di.sl<SharedPreferences>();
    final lastSplashDate = prefs.getString(AppConstants.lastSplashDateKey);
    final isPinEnabled = prefs.getBool('security_pin_enabled') ?? false;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (lastSplashDate == today) {
      if (isPinEnabled) {
        return '/pin';
      }
      return '/';
    }
  } catch (_) {}
  return '/splash';
}

class AppRouter {
  static GoRouter? _router;

  static GoRouter get router => _router ??= _buildRouter();

  static GoRouter _buildRouter() => GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: _determineInitialLocation(),
    routes: [
      // 0. Fullscreen Splash Screen (ToobJod Shiba Orange)
      GoRoute(
        path: '/splash',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashView(),
      ),
      // Main App Shell with Bottom Navigation Bar
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithBottomNavBar(navigationShell: navigationShell);
        },
        branches: [
          // 1. Dashboard Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardView(),
              ),
            ],
          ),
          // 2. Transactions Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                builder: (context, state) => const TransactionsView(),
              ),
            ],
          ),
        ],
      ),
      // Standalone Routes accessible from Dashboard (ภาพรวม)
      GoRoute(
        path: '/analytics',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AnalyticsView(),
      ),
      // Standalone Fullscreen Route for Category Budgets
      GoRoute(
        path: '/budgets',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BudgetView(),
      ),
      // Standalone Fullscreen Route for Auto-Sync & Bank Notifications
      GoRoute(
        path: '/auto-sync-settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AutoSyncSettingsView(),
      ),
      // Standalone Route for Notification Permission Request
      GoRoute(
        path: '/notification-permission',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationPermissionView(),
      ),
      // Standalone Route for Bank Selection Filter
      GoRoute(
        path: '/bank-selection',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BankSelectionView(),
      ),
      // Standalone Route for Detection / Swipe History
      GoRoute(
        path: '/swipe-history',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SwipeHistoryView(),
      ),
      // Standalone Route for Security Settings (PIN & Biometrics)
      GoRoute(
        path: '/security-settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SecuritySettingsView(),
      ),
      // Standalone Route for Security PIN Screen
      GoRoute(
        path: '/pin',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final mode = state.extra is PinMode ? state.extra as PinMode : PinMode.verify;
          return PinScreen(initialMode: mode);
        },
      ),
    ],
  );
}

class ScaffoldWithBottomNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithBottomNavBar({
    super.key,
    required this.navigationShell,
  });

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: navigationShell.currentIndex,
        onItemSelected: _onTap,
        onAiPressed: () => ToobJodAiDialog.show(context),
      ),
    );
  }
}

