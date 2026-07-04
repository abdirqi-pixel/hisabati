import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/data/database_providers.dart';
import '../../../core/services/report_export_service.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/widgets/simple_bar_chart.dart';

class AdvancedReportsScreen extends ConsumerWidget {
  const AdvancedReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(advancedReportProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('التقارير المتقدمة')),
      body: settings.when(
        data: (s) {
          final symbol = (s?['currency_symbol'] ?? 'د.ع').toString();

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const _ReportFilters(),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/saved-report-filters'),
                      icon: const Icon(Icons.bookmarks_rounded),
                      label: const Text('الفلاتر المحفوظة'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () => _showSaveFilterDialog(context, ref),
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('حفظ الفلتر'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              report.when(
                data: (data) {
                  final total = (data['total'] as num?) ?? 0;
                  final count = data['count'] ?? 0;
                  final byCategory =
                      (data['byCategory'] as List).cast<Map<String, Object?>>();
                  final byPerson =
                      (data['byPerson'] as List).cast<Map<String, Object?>>();
                  final byProject =
                      (data['byProject'] as List).cast<Map<String, Object?>>();
                  final expenses =
                      (data['expenses'] as List).cast<Map<String, Object?>>();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            const Text('نتيجة التقرير',
                                style: TextStyle(color: Colors.white70)),
                            const SizedBox(height: 8),
                            Text(
                              MoneyFormatter.format(total, symbol),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text('عدد العمليات: $count',
                                style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () async {
                                final file = await ReportExportService()
                                    .exportExpensesPdf(
                                  currencySymbol: symbol,
                                  total: total,
                                  byCategory: byCategory,
                                  byPerson: byPerson,
                                  byDay: byProject,
                                );
                                await Share.shareXFiles([XFile(file.path)],
                                    text: 'تقرير حساباتي المتقدم PDF');
                              },
                              icon: const Icon(Icons.picture_as_pdf_rounded),
                              label: const Text('PDF'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: () async {
                                final file = await ReportExportService()
                                    .exportExpensesExcel(
                                  currencySymbol: symbol,
                                  total: total,
                                  byCategory: byCategory,
                                  byPerson: byPerson,
                                  byDay: byProject,
                                );
                                await Share.shareXFiles([XFile(file.path)],
                                    text: 'تقرير حساباتي المتقدم Excel');
                              },
                              icon: const Icon(Icons.table_chart_rounded),
                              label: const Text('Excel'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SimpleBarChart(
                        title: 'حسب المشروع',
                        items: byProject
                            .map((e) => ChartItem(
                                label: e['name'].toString(),
                                value: (e['total'] as num?) ?? 0))
                            .toList(),
                        valueLabelBuilder: (value) =>
                            MoneyFormatter.format(value, symbol),
                      ),
                      const SizedBox(height: 14),
                      SimpleBarChart(
                        title: 'حسب الشخص',
                        items: byPerson
                            .map((e) => ChartItem(
                                label: e['name'].toString(),
                                value: (e['total'] as num?) ?? 0))
                            .toList(),
                        valueLabelBuilder: (value) =>
                            MoneyFormatter.format(value, symbol),
                      ),
                      const SizedBox(height: 14),
                      SimpleBarChart(
                        title: 'حسب التصنيف',
                        items: byCategory
                            .map((e) => ChartItem(
                                label: e['name'].toString(),
                                value: (e['total'] as num?) ?? 0))
                            .toList(),
                        valueLabelBuilder: (value) =>
                            MoneyFormatter.format(value, symbol),
                      ),
                      const SizedBox(height: 18),
                      const Text('العمليات المطابقة',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      if (expenses.isEmpty)
                        const Card(
                            child: Padding(
                                padding: EdgeInsets.all(18),
                                child: Text('لا توجد عمليات مطابقة')))
                      else
                        ...expenses.take(100).map((e) {
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                  child: Icon(Icons.receipt_long_rounded)),
                              title: Text(
                                  '${e['amount']} ${e['currency_symbol']}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  '${e['project_name'] ?? 'بدون مشروع'} • ${e['person_name'] ?? 'بدون شخص'} • ${e['category_name'] ?? 'بدون تصنيف'}\n${e['description'] ?? ''}'),
                              isThreeLine: true,
                              trailing:
                                  Text((e['expense_date'] ?? '').toString()),
                            ),
                          );
                        }),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('خطأ: $e')),
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

Future<void> _showSaveFilterDialog(BuildContext context, WidgetRef ref) async {
  final nameController = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('حفظ الفلتر'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'اسم الفلتر'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              final filter = ref.read(reportFilterProvider);
              final db = await ref.read(appDatabaseProvider).database;
              final settings = await db.query('app_settings', limit: 1);

              await db.insert('saved_report_filters', {
                'name': name,
                'project_id': filter.projectId,
                'person_id': filter.personId,
                'category_id': filter.categoryId,
                'date_from': filter.dateFrom,
                'date_to': filter.dateTo,
                'amount_from': filter.amountFrom,
                'amount_to': filter.amountTo,
                'created_by': settings.isEmpty
                    ? null
                    : settings.first['selected_user_id'],
                'created_at': DateTime.now().toIso8601String(),
              });

              ref.invalidate(savedReportFiltersProvider);

              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حفظ الفلتر')),
                );
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      );
    },
  );

  nameController.dispose();
}

class _ReportFilters extends ConsumerStatefulWidget {
  const _ReportFilters();

  @override
  ConsumerState<_ReportFilters> createState() => _ReportFiltersState();
}

class _ReportFiltersState extends ConsumerState<_ReportFilters> {
  final amountFrom = TextEditingController();
  final amountTo = TextEditingController();

  @override
  void dispose() {
    amountFrom.dispose();
    amountTo.dispose();
    super.dispose();
  }

  Future<void> pickDate({required bool from}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDate: now,
    );

    if (picked == null) return;

    final value = picked.toIso8601String().split('T').first;
    final filter = ref.read(reportFilterProvider);

    ref.read(reportFilterProvider.notifier).state = from
        ? filter.copyWith(dateFrom: value)
        : filter.copyWith(dateTo: value);
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(reportFilterProvider);
    final projects = ref.watch(projectsProvider);
    final persons = ref.watch(personsProvider);
    final categories = ref.watch(categoriesProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('الفلاتر',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            projects.when(
              data: (items) => DropdownButtonFormField<int>(
                initialValue: filter.projectId,
                decoration: const InputDecoration(labelText: 'المشروع'),
                items: [
                  const DropdownMenuItem<int>(
                      value: null, child: Text('كل المشاريع')),
                  ...items.map((p) => DropdownMenuItem<int>(
                      value: p['id'] as int,
                      child: Text(p['name'].toString()))),
                ],
                onChanged: (value) =>
                    ref.read(reportFilterProvider.notifier).state = ref
                        .read(reportFilterProvider)
                        .copyWith(
                            projectId: value, clearProject: value == null),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('$e'),
            ),
            const SizedBox(height: 10),
            persons.when(
              data: (items) => DropdownButtonFormField<int>(
                initialValue: filter.personId,
                decoration: const InputDecoration(labelText: 'الشخص'),
                items: [
                  const DropdownMenuItem<int>(
                      value: null, child: Text('كل الأشخاص')),
                  ...items.map((p) => DropdownMenuItem<int>(
                      value: p['id'] as int,
                      child: Text(p['name'].toString()))),
                ],
                onChanged: (value) =>
                    ref.read(reportFilterProvider.notifier).state = ref
                        .read(reportFilterProvider)
                        .copyWith(personId: value, clearPerson: value == null),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('$e'),
            ),
            const SizedBox(height: 10),
            categories.when(
              data: (items) => DropdownButtonFormField<int>(
                initialValue: filter.categoryId,
                decoration: const InputDecoration(labelText: 'التصنيف'),
                items: [
                  const DropdownMenuItem<int>(
                      value: null, child: Text('كل التصنيفات')),
                  ...items.map((c) => DropdownMenuItem<int>(
                      value: c['id'] as int,
                      child: Text(c['name'].toString()))),
                ],
                onChanged: (value) =>
                    ref.read(reportFilterProvider.notifier).state = ref
                        .read(reportFilterProvider)
                        .copyWith(
                            categoryId: value, clearCategory: value == null),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('$e'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => pickDate(from: true),
                    icon: const Icon(Icons.date_range_rounded),
                    label: Text(filter.dateFrom ?? 'من تاريخ'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => pickDate(from: false),
                    icon: const Icon(Icons.date_range_rounded),
                    label: Text(filter.dateTo ?? 'إلى تاريخ'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: amountFrom,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'مبلغ من'),
                    onChanged: (value) =>
                        ref.read(reportFilterProvider.notifier).state = ref
                            .read(reportFilterProvider)
                            .copyWith(
                                amountFrom: double.tryParse(value),
                                clearAmounts:
                                    value.isEmpty && amountTo.text.isEmpty),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: amountTo,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'مبلغ إلى'),
                    onChanged: (value) =>
                        ref.read(reportFilterProvider.notifier).state = ref
                            .read(reportFilterProvider)
                            .copyWith(
                                amountTo: double.tryParse(value),
                                clearAmounts:
                                    value.isEmpty && amountFrom.text.isEmpty),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                amountFrom.clear();
                amountTo.clear();
                ref.read(reportFilterProvider.notifier).state =
                    const ReportFilter();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('مسح الفلاتر'),
            ),
          ],
        ),
      ),
    );
  }
}
