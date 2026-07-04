import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/database_providers.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/services/report_export_service.dart';
import '../../../core/widgets/simple_bar_chart.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(reportsSummaryProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('التقارير')),
      body: settings.when(
        data: (s) {
          final symbol = (s?['currency_symbol'] ?? 'د.ع').toString();

          return reports.when(
            data: (data) {
              final byCategory = (data['byCategory'] as List).cast<Map<String, Object?>>();
              final byPerson = (data['byPerson'] as List).cast<Map<String, Object?>>();
              final byDay = (data['byDay'] as List).cast<Map<String, Object?>>();
              final total = (data['total'] as num?) ?? 0;
              final count = (data['count'] as num?) ?? 0;

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
                        const Text('إجمالي المصروفات', style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),
                        Text(
                          MoneyFormatter.format(total, symbol),
                          style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('عدد العمليات: $count', style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: () => context.go('/advanced-reports'),
                    icon: const Icon(Icons.analytics_rounded),
                    label: const Text('فتح التقارير المتقدمة'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            final file = await ReportExportService().exportExpensesPdf(
                              currencySymbol: symbol,
                              total: total,
                              byCategory: byCategory,
                              byPerson: byPerson,
                              byDay: byDay,
                            );
                            await Share.shareXFiles([XFile(file.path)], text: 'تقرير حساباتي PDF');
                          },
                          icon: const Icon(Icons.picture_as_pdf_rounded),
                          label: const Text('تصدير PDF'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () async {
                            final file = await ReportExportService().exportExpensesExcel(
                              currencySymbol: symbol,
                              total: total,
                              byCategory: byCategory,
                              byPerson: byPerson,
                              byDay: byDay,
                            );
                            await Share.shareXFiles([XFile(file.path)], text: 'تقرير حساباتي Excel');
                          },
                          icon: const Icon(Icons.table_chart_rounded),
                          label: const Text('Excel'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SimpleBarChart(
                    title: 'مخطط التصنيفات',
                    items: byCategory
                        .map((e) => ChartItem(
                              label: e['name'].toString(),
                              value: (e['total'] as num?) ?? 0,
                            ))
                        .toList(),
                    valueLabelBuilder: (value) => MoneyFormatter.format(value, symbol),
                  ),
                  const SizedBox(height: 14),
                  SimpleBarChart(
                    title: 'مخطط الأشخاص',
                    items: byPerson
                        .map((e) => ChartItem(
                              label: e['name'].toString(),
                              value: (e['total'] as num?) ?? 0,
                            ))
                        .toList(),
                    valueLabelBuilder: (value) => MoneyFormatter.format(value, symbol),
                  ),
                  const SizedBox(height: 14),
                  SimpleBarChart(
                    title: 'مخطط الأيام',
                    items: byDay
                        .map((e) => ChartItem(
                              label: e['date'].toString(),
                              value: (e['total'] as num?) ?? 0,
                            ))
                        .toList(),
                    valueLabelBuilder: (value) => MoneyFormatter.format(value, symbol),
                  ),
                  const SizedBox(height: 18),
                  _Section(title: 'حسب التصنيف', items: byCategory, symbol: symbol),
                  const SizedBox(height: 18),
                  _Section(title: 'حسب الشخص', items: byPerson, symbol: symbol),
                  const SizedBox(height: 18),
                  _DaySection(items: byDay, symbol: symbol),
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

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.items,
    required this.symbol,
  });

  final String title;
  final List<Map<String, Object?>> items;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (items.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('لا توجد بيانات')))
        else
          ...items.map((item) {
            final total = (item['total'] as num?) ?? 0;
            final count = item['count'] ?? 0;
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.pie_chart_rounded)),
                title: Text(item['name'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('عدد العمليات: $count'),
                trailing: Text(
                  MoneyFormatter.format(total, symbol),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.items,
    required this.symbol,
  });

  final List<Map<String, Object?>> items;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('حسب اليوم', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (items.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('لا توجد بيانات')))
        else
          ...items.map((item) {
            final total = (item['total'] as num?) ?? 0;
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.calendar_today_rounded)),
                title: Text(item['date'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('عدد العمليات: ${item['count']}'),
                trailing: Text(MoneyFormatter.format(total, symbol), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            );
          }),
      ],
    );
  }
}