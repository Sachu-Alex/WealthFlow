import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/main_shell.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/expenses/expenses_screen.dart';
import '../screens/expenses/chat_expense_screen.dart';
import '../screens/investments/add_investment_screen.dart';
import '../screens/investments/investment_detail_screen.dart';
import '../screens/withdrawals/add_withdrawal_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/expenses/bill_splitter_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isLoggedIn = authState.valueOrNull != null;
      final isSplash = state.matchedLocation == '/splash';
      final isLogin = state.matchedLocation == '/login';

      if (isLoading || isSplash) return null;
      if (!isLoggedIn && !isLogin) return '/login';
      if (isLoggedIn && isLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ── Shell with bottom nav ─────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/expenses',
                builder: (context, state) => const ExpensesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                builder: (context, state) => const ReportsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── Full-screen routes ────────────────────────────────────────────────
      GoRoute(
        path: '/expenses/chat',
        builder: (context, state) => const ChatExpenseScreen(),
      ),
      GoRoute(
        path: '/expenses/split',
        builder: (context, state) => const BillSplitterScreen(),
      ),
      GoRoute(
        path: '/investments/add',
        builder: (context, state) => const AddInvestmentScreen(),
      ),
      GoRoute(
        path: '/investments/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return InvestmentDetailScreen(investmentId: id);
        },
      ),
      GoRoute(
        path: '/investments/:id/withdrawal/add',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AddWithdrawalScreen(investmentId: id);
        },
      ),
    ],
  );
});
