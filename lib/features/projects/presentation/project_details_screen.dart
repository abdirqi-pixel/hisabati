import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/database_providers.dart';
import '../../../core/utils/money_formatter.dart';

class ProjectDetailsScreen extends ConsumerWidget {
  const ProjectDetailsScreen({
    super.key,
    required this.projectId,
  });

  final int projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(projectDetailsProvider(projectId));

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل المشروع')),
      body: details.when(
        data: (data) {
          final project = data['project'] as Map<String, Object?>;
          if (project.isEmpty) {
            return const Center(child: Text('المشروع غير موجود'));
          }

          final symbol = (project['currency_symbol'] ?? '').toString();
          final budget = (project['budget'] as num?) ?? 0;
          final budgetPercent = (data['budgetPercent'] as num?) ?? 0;

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
                    Text((project['icon'] ?? '📁').toString(), style: const TextStyle(fontSize: 42)),
                    const SizedBox(height: 10),
                    Text(
                      project['name'].toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('الرصيد: ${MoneyFormatter.format((data['balance'] as num?) ?? 0, symbol)}',
                        style: const TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('الميزانية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(value: budgetPercent > 1 ? 1 : budgetPercent.toDouble()),
                      const SizedBox(height: 8),
                      Text('الميزانية: ${MoneyFormatter.format(budget, symbol)}'),
                      Text('المصروف: ${MoneyFormatter.format((data['expensesTotal'] as num?) ?? 0, symbol)}'),
                      Text('نسبة الصرف: ${(budgetPercent * 100).toStringAsFixed(0)}%'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('إضافة للمشروع', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => context.go('/add-expense'),
                              icon: const Icon(Icons.receipt_long_rounded),
                              label: const Text('مصروف'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: () => context.go('/incomes'),
                              icon: const Icon(Icons.trending_up_rounded),
                              label: const Text('إيراد'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _GridStats(symbol: symbol, data: data),
              const SizedBox(height: 18),
              const Text('آخر العمليات', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _LatestExpenses(
                expenses: (data['latestExpenses'] as List).cast<Map<String, Object?>>(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
      ),
    );
  }
}

class _GridStats extends StatelessWidget {
  const _GridStats({
    required this.symbol,
    required this.data,
  });

  final String symbol;
  final Map<String, Object?> data;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('المصروفات', data['expensesTotal'] as num? ?? 0, Icons.trending_down_rounded),
      ('الإيرادات', data['incomesTotal'] as num? ?? 0, Icons.trending_up_rounded),
      ('الإيداعات', data['deposits'] as num? ?? 0, Icons.add_card_rounded),
      ('السحوبات', data['withdrawals'] as num? ?? 0, Icons.remove_circle_rounded),
      ('السلف المتبقية', data['remainingAdvances'] as num? ?? 0, Icons.handshake_rounded),
      ('الأشخاص', data['personsCount'] as num? ?? 0, Icons.people_rounded),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final isMoney = index != 5;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.$3),
                const Spacer(),
                Text(item.$1),
                const SizedBox(height: 4),
                Text(
                  isMoney ? MoneyFormatter.format(item.$2, symbol) : item.$2.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LatestExpenses extends StatelessWidget {
  const _LatestExpenses({
    required this.expenses,
  });

  final List<Map<String, Object?>> expenses;

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text('لا توجد عمليات في هذا المشروع'),
        ),
      );
    }

    return Column(
      children: expenses.map((e) {
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.receipt_long_rounded)),
            title: Text('${e['amount']} ${e['currency_symbol']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${e['serial_number']} • ${e['person_name'] ?? 'بدون شخص'} • ${e['category_name'] ?? 'بدون تصنيف'}'),
            trailing: Text((e['expense_date'] ?? '').toString()),
          ),
        );
      }).toList(),
    );
  }
}