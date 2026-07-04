import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/widgets/simple_bar_chart.dart';

class ExecutiveDashboardScreen extends ConsumerWidget {
  const ExecutiveDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(executiveDashboardProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('اللوحة التنفيذية')),
      body: settings.when(
        data: (s) {
          final symbol = (s?['currency_symbol'] ?? 'د.ع').toString();

          return dashboard.when(
            data: (data) {
              final totals = data['totals'] as Map<String, Object?>;
              final projects =
                  (data['projects'] as List).cast<Map<String, Object?>>();
              final risks =
                  (data['riskBudgets'] as List).cast<Map<String, Object?>>();
              final trend =
                  (data['monthTrend'] as List).cast<Map<String, Object?>>();

              final incomes = (totals['incomes'] as num?) ?? 0;
              final expenses = (totals['expenses'] as num?) ?? 0;
              final deposits = (totals['deposits'] as num?) ?? 0;
              final withdrawals = (totals['withdrawals'] as num?) ?? 0;
              final net = incomes + deposits - expenses - withdrawals;

              return ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF3B82F6)]),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('الملخص التنفيذي',
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),
                        Text(
                          MoneyFormatter.format(net, symbol),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('الصافي العام',
                            style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.35,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _Metric(
                          title: 'الإيرادات',
                          value: MoneyFormatter.format(incomes, symbol),
                          icon: Icons.trending_up_rounded),
                      _Metric(
                          title: 'المصروفات',
                          value: MoneyFormatter.format(expenses, symbol),
                          icon: Icons.trending_down_rounded),
                      _Metric(
                          title: 'الصندوق',
                          value: MoneyFormatter.format(
                              deposits - withdrawals, symbol),
                          icon: Icons.account_balance_wallet_rounded),
                      _Metric(
                          title: 'السلف المتبقية',
                          value: MoneyFormatter.format(
                              (totals['advances_remaining'] as num?) ?? 0,
                              symbol),
                          icon: Icons.handshake_rounded),
                      _Metric(
                          title: 'المشاريع النشطة',
                          value: '${totals['active_projects'] ?? 0}',
                          icon: Icons.folder_rounded),
                      _Metric(
                          title: 'عدد العمليات',
                          value: '${totals['expense_count'] ?? 0}',
                          icon: Icons.receipt_long_rounded),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SimpleBarChart(
                    title: 'اتجاه المصروفات آخر 6 أشهر',
                    items: trend.reversed
                        .map((e) => ChartItem(
                            label: e['month'].toString(),
                            value: (e['total'] as num?) ?? 0))
                        .toList(),
                    valueLabelBuilder: (value) =>
                        MoneyFormatter.format(value, symbol),
                  ),
                  const SizedBox(height: 14),
                  _ProjectComparison(projects: projects, defaultSymbol: symbol),
                  const SizedBox(height: 14),
                  _RiskBudgets(risks: risks, defaultSymbol: symbol),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('خطأ: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.title, required this.value, required this.icon});

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const Spacer(),
            Text(title),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _ProjectComparison extends StatelessWidget {
  const _ProjectComparison(
      {required this.projects, required this.defaultSymbol});

  final List<Map<String, Object?>> projects;
  final String defaultSymbol;

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return const Card(
          child: Padding(
              padding: EdgeInsets.all(18),
              child: Text('لا توجد مشاريع للمقارنة')));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('مقارنة المشاريع',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...projects.take(8).map((p) {
              final symbol = p['currency_symbol']?.toString() ?? defaultSymbol;
              final expenses = (p['expenses'] as num?) ?? 0;
              final incomes = (p['incomes'] as num?) ?? 0;
              final balance = ((p['opening_balance'] as num?) ?? 0) +
                  incomes +
                  ((p['deposits'] as num?) ?? 0) -
                  ((p['withdrawals'] as num?) ?? 0) -
                  expenses;
              final budget = (p['budget'] as num?) ?? 0;
              final percent =
                  budget <= 0 ? 0.0 : (expenses / budget).clamp(0.0, 1.0);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['name'].toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: percent),
                    const SizedBox(height: 4),
                    Text(
                        'المصروف: ${MoneyFormatter.format(expenses, symbol)} • الرصيد: ${MoneyFormatter.format(balance, symbol)}'),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _RiskBudgets extends StatelessWidget {
  const _RiskBudgets({required this.risks, required this.defaultSymbol});

  final List<Map<String, Object?>> risks;
  final String defaultSymbol;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('تنبيهات الميزانية',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (risks.isEmpty)
              const Text('لا توجد ميزانيات معرضة للخطر')
            else
              ...risks.map((r) {
                final symbol =
                    r['currency_symbol']?.toString() ?? defaultSymbol;
                final percent = ((r['percent'] as num?) ?? 0) * 100;
                return ListTile(
                  leading: Icon(
                      percent >= 100
                          ? Icons.error_rounded
                          : Icons.warning_amber_rounded,
                      color: percent >= 100 ? Colors.red : Colors.orange),
                  title: Text('${r['name']} - ${r['project_name']}'),
                  subtitle: Text(
                      'المصروف: ${MoneyFormatter.format((r['spent'] as num?) ?? 0, symbol)} من ${MoneyFormatter.format((r['amount'] as num?) ?? 0, symbol)}'),
                  trailing: Text('${percent.toStringAsFixed(0)}%'),
                );
              }),
          ],
        ),
      ),
    );
  }
}
