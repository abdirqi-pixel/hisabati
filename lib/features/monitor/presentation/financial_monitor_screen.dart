import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/data/database_providers.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/widgets/simple_bar_chart.dart';

class FinancialMonitorScreen extends ConsumerWidget {
  const FinancialMonitorScreen({super.key});

  Future<void> shareSummary(WidgetRef ref, String symbol) async {
    final data = await ref.read(financialMonitorProvider.future);
    final text = '''
ملخص حساباتي التنفيذي:
الرصيد الحالي: ${MoneyFormatter.format((data['currentBalance'] as num?) ?? 0, symbol)}
تدفق الشهر الحالي: ${MoneyFormatter.format((data['currentCashFlow'] as num?) ?? 0, symbol)}
التدفق المتوقع نهاية الشهر: ${MoneyFormatter.format((data['expectedMonthCashFlow'] as num?) ?? 0, symbol)}
مصروف الشهر المتوقع: ${MoneyFormatter.format((data['expectedMonthExpense'] as num?) ?? 0, symbol)}
''';

    await Share.share(text);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitor = ref.watch(financialMonitorProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المراقبة المالية'),
        actions: [
          IconButton(
            onPressed: () async {
              final s = await ref.read(settingsProvider.future);
              await shareSummary(ref, (s?['currency_symbol'] ?? 'د.ع').toString());
            },
            icon: const Icon(Icons.share_rounded),
          ),
        ],
      ),
      body: settings.when(
        data: (s) {
          final symbol = (s?['currency_symbol'] ?? 'د.ع').toString();

          return monitor.when(
            data: (data) {
              final topSpending = (data['topSpending'] as List).cast<Map<String, Object?>>();
              final ranking = (data['projectRanking'] as List).cast<Map<String, Object?>>();

              return ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF3B82F6)]),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('توقع التدفق النقدي', style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),
                        Text(
                          MoneyFormatter.format((data['expectedMonthCashFlow'] as num?) ?? 0, symbol),
                          style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text('التدفق المتوقع نهاية الشهر', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _Metric('الرصيد الحالي', MoneyFormatter.format((data['currentBalance'] as num?) ?? 0, symbol), Icons.account_balance_wallet_rounded),
                      _Metric('تدفق الشهر', MoneyFormatter.format((data['currentCashFlow'] as num?) ?? 0, symbol), Icons.compare_arrows_rounded),
                      _Metric('مصروف متوقع', MoneyFormatter.format((data['expectedMonthExpense'] as num?) ?? 0, symbol), Icons.trending_down_rounded),
                      _Metric('المعدل اليومي', MoneyFormatter.format((data['dailyExpenseAverage'] as num?) ?? 0, symbol), Icons.today_rounded),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SimpleBarChart(
                    title: 'أكبر بنود الصرف',
                    items: topSpending
                        .map((e) => ChartItem(label: (e['name'] ?? 'بدون تصنيف').toString(), value: (e['total'] as num?) ?? 0))
                        .toList(),
                    valueLabelBuilder: (value) => MoneyFormatter.format(value, symbol),
                  ),
                  const SizedBox(height: 14),
                  _ProjectRanking(items: ranking, symbol: symbol),
                  const SizedBox(height: 14),
                  const FinancialGoalsPanel(),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const _GoalForm(),
        ),
        icon: const Icon(Icons.flag_rounded),
        label: const Text('هدف مالي'),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.title, this.value, this.icon);

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const Spacer(),
            Text(title),
            const SizedBox(height: 5),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _ProjectRanking extends StatelessWidget {
  const _ProjectRanking({required this.items, required this.symbol});

  final List<Map<String, Object?>> items;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ترتيب المشاريع حسب الصافي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (items.isEmpty)
              const Text('لا توجد بيانات')
            else
              ...items.map((p) {
                final s = p['currency_symbol']?.toString() ?? symbol;
                final net = (p['net'] as num?) ?? 0;
                return ListTile(
                  leading: CircleAvatar(child: Text('${items.indexOf(p) + 1}')),
                  title: Text(p['name'].toString()),
                  subtitle: Text('إيرادات: ${MoneyFormatter.format((p['incomes'] as num?) ?? 0, s)} • مصروفات: ${MoneyFormatter.format((p['expenses'] as num?) ?? 0, s)}'),
                  trailing: Text(
                    MoneyFormatter.format(net, s),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: net >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class FinancialGoalsPanel extends ConsumerWidget {
  const FinancialGoalsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(financialGoalsProvider);

    return goals.when(
      data: (items) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('الأهداف المالية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (items.isEmpty)
                  const Text('لا توجد أهداف مالية بعد')
                else
                  ...items.map((g) {
                    final target = (g['target_amount'] as num?) ?? 0;
                    final current = (g['current_amount'] as num?) ?? 0;
                    final percent = target <= 0 ? 0.0 : (current / target).clamp(0.0, 1.0);
                    final symbol = g['currency_symbol'].toString();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(g['title'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(value: percent),
                          const SizedBox(height: 4),
                          Text('${MoneyFormatter.format(current, symbol)} من ${MoneyFormatter.format(target, symbol)}'),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('خطأ: $e'),
    );
  }
}

class _GoalForm extends ConsumerStatefulWidget {
  const _GoalForm();

  @override
  ConsumerState<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends ConsumerState<_GoalForm> {
  final title = TextEditingController();
  final target = TextEditingController();
  final current = TextEditingController();

  @override
  void dispose() {
    title.dispose();
    target.dispose();
    current.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final targetAmount = double.tryParse(target.text.trim());
    final currentAmount = double.tryParse(current.text.trim()) ?? 0;
    if (targetAmount == null || targetAmount <= 0 || title.text.trim().isEmpty) return;

    final db = await ref.read(appDatabaseProvider).database;
    final settings = await db.query('app_settings', limit: 1);
    if (settings.isEmpty) return;

    await db.insert('financial_goals', {
      'title': title.text.trim(),
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'currency_code': settings.first['currency_code'],
      'currency_symbol': settings.first['currency_symbol'],
      'target_date': null,
      'is_completed': 0,
      'created_by': settings.first['selected_user_id'],
      'created_at': DateTime.now().toIso8601String(),
    });

    ref.invalidate(financialGoalsProvider);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('هدف مالي جديد', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          TextField(controller: title, decoration: const InputDecoration(labelText: 'اسم الهدف')),
          const SizedBox(height: 10),
          TextField(controller: target, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ المطلوب')),
          const SizedBox(height: 10),
          TextField(controller: current, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ الحالي')),
          const SizedBox(height: 14),
          FilledButton.icon(onPressed: save, icon: const Icon(Icons.save_rounded), label: const Text('حفظ')),
        ],
      ),
    );
  }
}