import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/widgets/app_stat_card.dart';
import '../../../core/widgets/simple_bar_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final insightsAsync = ref.watch(dashboardInsightsProvider);
    final projectsAsync = ref.watch(projectsProvider);
    final notificationCountAsync = ref.watch(unreadNotificationsCountProvider);
    final visibleKeysAsync = ref.watch(dashboardVisibleKeysProvider);

    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_rounded), label: 'الرئيسية'),
          NavigationDestination(
              icon: Icon(Icons.folder_rounded), label: 'المشاريع'),
          NavigationDestination(
              icon: Icon(Icons.add_circle_rounded), label: 'إضافة'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_rounded), label: 'التقارير'),
          NavigationDestination(
              icon: Icon(Icons.settings_rounded), label: 'الإعدادات'),
        ],
        onDestinationSelected: (index) {
          if (index == 1) context.go('/projects');
          if (index == 2) context.go('/quick-add');
          if (index == 3) context.go('/reports');
          if (index == 4) context.go('/settings');
        },
      ),
      body: SafeArea(
        child: settingsAsync.when(
          data: (settings) {
            final symbol = (settings?['currency_symbol'] ?? 'د.ع').toString();
            final visibleKeys = visibleKeysAsync.value ??
                {
                  'balance_card',
                  'budget_alert',
                  'quick_actions',
                  'projects',
                  'latest_expenses',
                  'top_categories',
                  'top_persons',
                };

            bool show(String key) => visibleKeys.contains(key);

            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'السلام عليكم 👋\nلوحة حساباتي',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () => context.go('/global-search'),
                      icon: const Icon(Icons.search_rounded),
                    ),
                    const SizedBox(width: 8),
                    Stack(
                      children: [
                        IconButton.filledTonal(
                          onPressed: () => context.go('/notification-center'),
                          icon: const Icon(Icons.notifications_rounded),
                        ),
                        if ((notificationCountAsync.value ?? 0) > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: CircleAvatar(
                              radius: 9,
                              backgroundColor: Colors.red,
                              child: Text(
                                '${notificationCountAsync.value}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (show('balance_card'))
                  summaryAsync.when(
                    data: (summary) {
                      final balance = summary['currentBalance'] ?? 0;
                      final expenses = summary['expensesTotal'] ?? 0;
                      final deposits = summary['deposits'] ?? 0;
                      final withdrawals = summary['withdrawals'] ?? 0;
                      final incomes = summary['incomes'] ?? 0;

                      return Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [AppColors.emerald, AppColors.sky]),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('الرصيد الحالي',
                                style: TextStyle(color: Colors.white70)),
                            const SizedBox(height: 8),
                            Text(
                              MoneyFormatter.format(balance, symbol),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 31,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                    child: _WhiteMetric(
                                        title: 'الإيداعات',
                                        value: MoneyFormatter.format(
                                            deposits, symbol))),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: _WhiteMetric(
                                        title: 'السحوبات',
                                        value: MoneyFormatter.format(
                                            withdrawals, symbol))),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _WhiteMetric(
                                title: 'إجمالي الإيرادات',
                                value: MoneyFormatter.format(incomes, symbol)),
                            const SizedBox(height: 10),
                            _WhiteMetric(
                                title: 'إجمالي المصروفات',
                                value: MoneyFormatter.format(expenses, symbol)),
                          ],
                        ),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('خطأ: $e'),
                  ),
                const SizedBox(height: 14),
                if (show('budget_alert'))
                  insightsAsync.when(
                    data: (insights) {
                      final percent = (insights['budgetPercent'] as num?) ?? 0;
                      final totalBudget =
                          (insights['totalBudget'] as num?) ?? 0;
                      final totalExpenses =
                          (insights['totalExpenses'] as num?) ?? 0;
                      final percentText = (percent * 100).toStringAsFixed(0);

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('مؤشر الميزانية',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              LinearProgressIndicator(
                                  value: percent > 1 ? 1 : percent.toDouble()),
                              const SizedBox(height: 8),
                              Text('تم صرف $percentText% من الميزانية'),
                              Text(
                                  'الميزانية: ${MoneyFormatter.format(totalBudget, symbol)}'),
                              Text(
                                  'المصروف: ${MoneyFormatter.format(totalExpenses, symbol)}'),
                              if (percent >= .8 && totalBudget > 0)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Text(
                                      'تنبيه: المصروفات اقتربت من الميزانية المحددة',
                                      style: TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => Text('خطأ: $e'),
                  ),
                const SizedBox(height: 14),
                if (show('quick_actions'))
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => context.go('/project-form'),
                          child: const AppStatCard(
                              title: 'مشروع جديد',
                              value: 'إضافة',
                              icon: Icons.create_new_folder_rounded),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => context.go('/quick-add'),
                          child: const AppStatCard(
                              title: 'إضافة سريعة',
                              value: 'فتح',
                              icon: Icons.add_card_rounded),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                        child: _QuickButton(
                            label: 'الأشخاص',
                            icon: Icons.people_rounded,
                            route: '/persons')),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _QuickButton(
                            label: 'الصندوق',
                            icon: Icons.account_balance_wallet_rounded,
                            route: '/treasury')),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _QuickButton(
                            label: 'التقارير',
                            icon: Icons.bar_chart_rounded,
                            route: '/reports')),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _QuickButton(
                            label: 'المؤشرات',
                            icon: Icons.query_stats_rounded,
                            route: '/kpi')),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _QuickButton(
                            label: 'التحليلات',
                            icon: Icons.insights_rounded,
                            route: '/analytics')),
                  ],
                ),
                if (show('projects')) ...[
                  const SizedBox(height: 22),
                  const Text('المشاريع النشطة',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  projectsAsync.when(
                    data: (projects) {
                      if (projects.isEmpty) {
                        return const Card(
                            child: Padding(
                                padding: EdgeInsets.all(18),
                                child: Text('لا توجد مشاريع بعد')));
                      }
                      return Column(
                        children: projects.take(4).map((p) {
                          return Card(
                            child: ListTile(
                              leading: Text((p['icon'] ?? '📁').toString(),
                                  style: const TextStyle(fontSize: 30)),
                              title: Text(p['name'].toString(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text('العملة: ${p['currency_symbol']}'),
                              trailing:
                                  const Icon(Icons.arrow_back_ios_new_rounded),
                              onTap: () => context.go('/projects'),
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('خطأ: $e'),
                  ),
                ],
                const SizedBox(height: 22),
                insightsAsync.when(
                  data: (insights) {
                    final latest = (insights['latestExpenses'] as List)
                        .cast<Map<String, Object?>>();
                    final topCategories = (insights['topCategories'] as List)
                        .cast<Map<String, Object?>>();
                    final topPersons = (insights['topPersons'] as List)
                        .cast<Map<String, Object?>>();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (show('latest_expenses'))
                          _MiniList(
                            title: 'آخر العمليات',
                            emptyText: 'لا توجد عمليات بعد',
                            items: latest.map((e) {
                              return '${e['serial_number']} • ${e['amount']} ${e['currency_symbol']} • ${e['category_name'] ?? 'بدون تصنيف'}';
                            }).toList(),
                          ),
                        const SizedBox(height: 16),
                        if (show('top_categories'))
                          SimpleBarChart(
                            title: 'رسم سريع للتصنيفات',
                            items: topCategories
                                .map((e) => ChartItem(
                                      label: e['name'].toString(),
                                      value: (e['total'] as num?) ?? 0,
                                    ))
                                .toList(),
                            valueLabelBuilder: (value) =>
                                MoneyFormatter.format(value, symbol),
                          ),
                        const SizedBox(height: 16),
                        if (show('top_categories'))
                          _MiniList(
                            title: 'أعلى التصنيفات صرفًا',
                            emptyText: 'لا توجد بيانات',
                            items: topCategories
                                .map((e) =>
                                    '${e['name']} • ${MoneyFormatter.format((e['total'] as num?) ?? 0, symbol)}')
                                .toList(),
                          ),
                        const SizedBox(height: 16),
                        if (show('top_persons'))
                          _MiniList(
                            title: 'أعلى الأشخاص صرفًا',
                            emptyText: 'لا توجد بيانات',
                            items: topPersons
                                .map((e) =>
                                    '${e['name']} • ${MoneyFormatter.format((e['total'] as num?) ?? 0, symbol)}')
                                .toList(),
                          ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('خطأ: $e'),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('خطأ: $e')),
        ),
      ),
    );
  }
}

class _WhiteMetric extends StatelessWidget {
  const _WhiteMetric({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  const _QuickButton({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: () => context.go(route),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _MiniList extends StatelessWidget {
  const _MiniList({
    required this.title,
    required this.items,
    required this.emptyText,
  });

  final String title;
  final List<String> items;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (items.isEmpty)
              Text(emptyText)
            else
              ...items.map((text) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 8),
                        const SizedBox(width: 8),
                        Expanded(child: Text(text)),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
