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
import '../../features/expenses/presentation/expenses_screen.dart';
import '../../features/expenses/presentation/expense_details_screen.dart';
import '../../features/treasury/presentation/treasury_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/reports/presentation/professional_reports_screen.dart';
import '../../features/performance/presentation/performance_screen.dart';
import '../../features/executive/presentation/executive_dashboard_screen.dart';
import '../../features/monitor/presentation/financial_monitor_screen.dart';
import '../../features/release/presentation/release_readiness_screen.dart';
import '../../features/release/presentation/build_readiness_screen.dart';
import '../../features/release/presentation/store_readiness_screen.dart';
import '../../features/about/presentation/about_app_screen.dart';
import '../../features/release/presentation/final_launch_screen.dart';
import '../../features/release/presentation/field_test_screen.dart';
import '../../features/release/presentation/tester_feedback_screen.dart';
import '../../features/release/presentation/developer_handoff_screen.dart';
import '../../features/release/presentation/feature_requests_screen.dart';
import '../../features/release/presentation/ux_review_screen.dart';
import '../../features/release/presentation/support_tickets_screen.dart';
import '../../features/release/presentation/app_releases_screen.dart';
import '../../features/release/presentation/structural_audit_screen.dart';
import '../../features/release/presentation/flutter_checks_screen.dart';
import '../../features/release/presentation/feature_freeze_screen.dart';
import '../../features/release/presentation/build_fix_log_screen.dart';
import '../../features/release/presentation/code_fix_only_screen.dart';
import '../../features/stabilization/presentation/stabilization_screen.dart';
import '../../features/reports/presentation/advanced_reports_screen.dart';
import '../../features/reports/presentation/saved_report_filters_screen.dart';
import '../../features/users/presentation/users_screen.dart';
import '../../features/backup/presentation/backup_screen.dart';
import '../../features/backup/presentation/secure_backup_screen.dart';
import '../../features/sync/presentation/cloud_sync_screen.dart';
import '../../features/settings/presentation/appearance_screen.dart';
import '../../features/settings/presentation/notifications_settings_screen.dart';
import '../../features/security/presentation/lock_screen.dart';
import '../../features/security/presentation/security_settings_screen.dart';
import '../../features/security/presentation/security_log_screen.dart';
import '../../features/activity/presentation/activity_log_screen.dart';
import '../../features/trash/presentation/trash_screen.dart';
import '../../features/advances/presentation/advances_screen.dart';
import '../../features/incomes/presentation/incomes_screen.dart';
import '../../features/quick_add/presentation/quick_add_screen.dart';
import '../../features/search/presentation/global_search_screen.dart';
import '../../features/ocr/presentation/invoice_scanner_screen.dart';
import '../../features/notifications/presentation/notification_center_screen.dart';
import '../../features/recurring/presentation/recurring_screen.dart';
import '../../features/analytics/presentation/analytics_screen.dart';
import '../../features/attachments/presentation/attachments_screen.dart';
import '../../features/settings/presentation/dashboard_settings_screen.dart';
import '../../features/maintenance/presentation/maintenance_screen.dart';
import '../../features/budgets/presentation/budgets_screen.dart';
import '../../features/kpi/presentation/kpi_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/categories/presentation/categories_screen.dart';
import '../../features/persons/presentation/persons_screen.dart';

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