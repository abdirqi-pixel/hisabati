import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/widgets/simple_bar_chart.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(analyticsProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('التحليلات')),
      body: settings.when(
        data: (s) {
          final symbol = (s?['currency_symbol'] ?? 'د.ع').toString();

          return analytics.when(
            data: (data) {
              final monthlyExpenses = (data['monthlyExpenses'] as List).cast<Map<String, Object?>>();
              final monthlyIncomes = (data['monthlyIncomes'] as List).cast<Map<String, Object?>>();
              final yearlyExpenses = (data['yearlyExpenses'] as List).cast<Map<String, Object?>>();
              final yearlyIncomes = (data['yearlyIncomes'] as List).cast<Map<String, Object?>>();
              final expected = (data['expectedMonthExpense'] as num?) ?? 0;
              final current = (data['currentMonthExpense'] as num?) ?? 0;
              final average = (data['dailyAverage'] as num?) ?? 0;
              final currentVsPrevious = (data['currentVsPrevious'] as List).cast<Map<String, Object?>>();

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
                        const Text('توقع نهاية الشهر', style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),
                        Text(
                          MoneyFormatter.format(expected, symbol),
                          style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text('مصروف هذا الشهر: ${MoneyFormatter.format(current, symbol)}', style: const TextStyle(color: Colors.white)),
                        Text('المعدل اليومي: ${MoneyFormatter.format(average, symbol)}', style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ComparisonCard(
                    rows: currentVsPrevious,
                    symbol: symbol,
                    currentMonth: data['currentMonthKey'].toString(),
                    previousMonth: data['previousMonthKey'].toString(),
                  ),
                  const SizedBox(height: 14),
                  SimpleBarChart(
                    title: 'المصروفات الشهرية',
                    items: monthlyExpenses.reversed
                        .map((e) => ChartItem(label: e['month'].toString(), value: (e['total'] as num?) ?? 0))
                        .toList(),
                    valueLabelBuilder: (value) => MoneyFormatter.format(value, symbol),
                  ),
                  const SizedBox(height: 14),
                  SimpleBarChart(
                    title: 'الإيرادات الشهرية',
                    items: monthlyIncomes.reversed
                        .map((e) => ChartItem(label: e['month'].toString(), value: (e['total'] as num?) ?? 0))
                        .toList(),
                    valueLabelBuilder: (value) => MoneyFormatter.format(value, symbol),
                  ),
                  const SizedBox(height: 14),
                  SimpleBarChart(
                    title: 'المصروفات السنوية',
                    items: yearlyExpenses.reversed
                        .map((e) => ChartItem(label: e['year'].toString(), value: (e['total'] as num?) ?? 0))
                        .toList(),
                    valueLabelBuilder: (value) => MoneyFormatter.format(value, symbol),
                  ),
                  const SizedBox(height: 14),
                  SimpleBarChart(
                    title: 'الإيرادات السنوية',
                    items: yearlyIncomes.reversed
                        .map((e) => ChartItem(label: e['year'].toString(), value: (e['total'] as num?) ?? 0))
                        .toList(),
                    valueLabelBuilder: (value) => MoneyFormatter.format(value, symbol),
                  ),
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

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({
    required this.rows,
    required this.symbol,
    required this.currentMonth,
    required this.previousMonth,
  });

  final List<Map<String, Object?>> rows;
  final String symbol;
  final String currentMonth;
  final String previousMonth;

  num valueFor(String month) {
    for (final row in rows) {
      if (row['month'] == month) return (row['total'] as num?) ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final current = valueFor(currentMonth);
    final previous = valueFor(previousMonth);
    final diff = current - previous;
    final diffPercent = previous == 0 ? 0 : (diff / previous) * 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('مقارنة هذا الشهر بالشهر السابق', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('$currentMonth: ${MoneyFormatter.format(current, symbol)}'),
            Text('$previousMonth: ${MoneyFormatter.format(previous, symbol)}'),
            const SizedBox(height: 8),
            Text(
              'الفرق: ${MoneyFormatter.format(diff, symbol)} (${diffPercent.toStringAsFixed(0)}%)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: diff > 0 ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}