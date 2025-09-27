import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/routes.dart';
import '../services/firebase_service.dart';
import '../widgets/main_layout.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/inventory/screens/inventory_screen.dart';
import '../../features/sales/screens/sales_screen.dart';
import '../../features/services/screens/services_screen.dart';
import '../../features/customers/screens/customers_screen.dart';
import '../../features/customers/screens/udhar_screen.dart';
import '../../features/expenses/screens/expenses_screen.dart';
import '../../features/reports/screens/reports_screen.dart';

class AppRouter {
  static final FirebaseService _firebaseService = FirebaseService();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.dashboard,
    redirect: (context, state) {
      final isAuthenticated = _firebaseService.isAuthenticated;
      final isAuthRoute = [
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
      ].contains(state.fullPath);

      // If not authenticated and not on auth route, redirect to login
      if (!isAuthenticated && !isAuthRoute) {
        return AppRoutes.login;
      }

      // If authenticated and on auth route, redirect to dashboard
      if (isAuthenticated && isAuthRoute) {
        return AppRoutes.dashboard;
      }

      return null; // No redirect needed
    },
    routes: [
      // Auth Routes (separate from shell)
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Main Shell Route for authenticated screens
      ShellRoute(
        builder: (context, state, child) {
          return MainLayout(
            currentRoute: state.fullPath ?? AppRoutes.dashboard,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const DashboardContent(),
            ),
          ),
          GoRoute(
            path: AppRoutes.inventory,
            name: 'inventory',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const InventoryContent(),
            ),
          ),
          GoRoute(
            path: AppRoutes.sales,
            name: 'sales',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const SalesContent(),
            ),
          ),
          GoRoute(
            path: AppRoutes.services,
            name: 'services',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ServicesScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.customers,
            name: 'customers',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const CustomersContent(),
            ),
          ),
          GoRoute(
            path: AppRoutes.udhar,
            name: 'udhar',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const UdharContent(),
            ),
          ),
          GoRoute(
            path: AppRoutes.expenses,
            name: 'expenses',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ExpensesContent(),
            ),
          ),
          GoRoute(
            path: AppRoutes.reports,
            name: 'reports',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ReportsScreen(),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The page you are looking for does not exist.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
}

// Custom page with no transition animation
class NoTransitionPage<T> extends Page<T> {
  const NoTransitionPage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      pageBuilder: (context, animation, _) => child,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }
}

// Content widgets that extract just the content without MainLayout
class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardScreen();
  }
}

class InventoryContent extends StatelessWidget {
  const InventoryContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const InventoryScreen();
  }
}

class SalesContent extends StatelessWidget {
  const SalesContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const SalesScreen();
  }
}

class CustomersContent extends StatelessWidget {
  const CustomersContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomersScreen();
  }
}

class UdharContent extends StatelessWidget {
  const UdharContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const UdharScreen();
  }
}

class ExpensesContent extends StatelessWidget {
  const ExpensesContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const ExpensesScreen();
  }
}