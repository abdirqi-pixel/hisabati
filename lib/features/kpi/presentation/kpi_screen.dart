import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';
import '../../../core/utils/money_formatter.dart';

class KpiScreen extends ConsumerWidget {
  const KpiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpi = ref.watch(kpiProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('مؤشرات الأداء')),
      body: settings.when(
        data: (s) {
          final symbol = (s?['currency_symbol'] ?? 'د.ع').toString();

          return kpi.when(
            data: (data) {
              final topPerson = data['topPerson'] as Map<String, Object?>?;
              final topCategory = data['topCategory'] as Map<String, Object?>?;
              final activeProject = data['mostActiveProject'] as Map<String, Object?>?;

              return ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  _KpiCard(title: 'إجمالي الإيرادات', value: MoneyFormatter.format((data['totalIncomes'] as num?) ?? 0, symbol), icon: Icons.trending_up_rounded),
                  _KpiCard(title: 'إجمالي المصروفات', value: MoneyFormatter.format((data['totalExpenses'] as num?) ?? 0, symbol), icon: Icons.trending_down_rounded),
                  _KpiCard(title: 'الصافي', value: MoneyFormatter.format((data['net'] as num?) ?? 0, symbol), icon: Icons.balance_rounded),
                  _KpiCard(title: 'السلف المتبقية', value: MoneyFormatter.format((data['totalAdvancesRemaining'] as num?) ?? 0, symbol), icon: Icons.handshake_rounded),
                  _KpiCard(title: 'صافي الصندوق', value: MoneyFormatter.format((data['treasuryNet'] as num?) ?? 0, symbol), icon: Icons.account_balance_wallet_rounded),
                  _KpiCard(title: 'مصروفات اليوم', value: '${MoneyFormatter.format((data['todayExpenses'] as num?) ?? 0, symbol)} • ${data['todayCount']} عملية', icon: Icons.today_rounded),
                  _KpiCard(title: 'أكثر شخص صرفًا', value: topPerson == null ? 'لا توجد بيانات' : '${topPerson['name']} • ${MoneyFormatter.format((topPerson['total'] as num?) ?? 0, symbol)}', icon: Icons.person_rounded),
                  _KpiCard(title: 'أكثر تصنيف استخدامًا', value: topCategory == null ? 'لا توجد بيانات' : '${topCategory['name']} • ${MoneyFormatter.format((topCategory['total'] as num?) ?? 0, symbol)}', icon: Icons.category_rounded),
                  _KpiCard(title: 'أكثر مشروع نشاطًا', value: activeProject == null ? 'لا توجد بيانات' : '${activeProject['name']} • ${activeProject['count']} عملية', icon: Icons.folder_rounded),
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

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        subtitle: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}