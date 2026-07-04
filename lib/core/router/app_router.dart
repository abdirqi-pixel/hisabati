import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/presentation/splash_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/projects/presentation/projects_screen.dart';
import '../../features/projects/presentation/project_form_screen.dart';
import '../../features/projects/presentation/archived_projects_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/countries/presentation/country_currency_screen.dart';
import '../../features/expenses/presentation/add_expense_screen.dart';
import '../../features/quick_add/presentation/quick_add_screen.dart';
import '../../features/search/presentation/global_search_screen.dart';
import '../../features/ocr/presentation/invoice_scanner_screen.dart';
import '../../features/notifications/presentation/notification_center_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/projects',
        builder: (context, state) => const ProjectsScreen(),
      ),
      GoRoute(
        path: '/project-form',
        builder: (context, state) {
          final id = int.tryParse(state.uri.queryParameters['id'] ?? '');
          return ProjectFormScreen(projectId: id);
        },
      ),
      GoRoute(
        path: '/archived-projects',
        builder: (context, state) => const ArchivedProjectsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/country-currency',
        builder: (context, state) => const CountryCurrencyScreen(),
      ),
      GoRoute(
        path: '/add-expense',
        builder: (context, state) => AddExpenseScreen(
          initialAmount: state.uri.queryParameters['amount'],
          initialDescription: state.uri.queryParameters['description'],
          initialNotes: state.uri.queryParameters['notes'],
          initialAttachmentPath: state.uri.queryParameters['attachment'],
        ),
      ),
      GoRoute(
        path: '/quick-add',
        builder: (context, state) => const QuickAddScreen(),
      ),
      GoRoute(
        path: '/invoice-scanner',
        builder: (context, state) => const InvoiceScannerScreen(),
      ),
      GoRoute(
        path: '/notification-center',
        builder: (context, state) => const NotificationCenterScreen(),
      ),
      GoRoute(
        path: '/global-search',
        builder: (context, state) => const GlobalSearchScreen(),
      ),
    ],
  );
});
