import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';
import '../../../core/services/recurring_service.dart';
import '../../../core/utils/money_formatter.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  String freqLabel(String value, int interval) {
    final base = switch (value) {
      'daily' => 'يوميًا',
      'weekly' => 'أسبوعيًا',
      'monthly' => 'شهريًا',
      'yearly' => 'سنويًا',
      _ => value,
    };

    return interval <= 1
        ? base
        : 'كل $interval ${value == 'monthly' ? 'أشهر' : value == 'weekly' ? 'أسابيع' : value == 'yearly' ? 'سنوات' : 'أيام'}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurring = ref.watch(recurringTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('العمليات الدورية'),
        actions: [
          IconButton(
            tooltip: 'تشغيل المستحق الآن',
            onPressed: () async {
              final count =
                  await RecurringService(ref.read(appDatabaseProvider))
                      .processDueTransactions();
              ref.invalidate(recurringTransactionsProvider);
              ref.invalidate(expensesProvider);
              ref.invalidate(incomesProvider);
              ref.invalidate(activityLogProvider);
              ref.invalidate(appNotificationsProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم إنشاء $count عملية مستحقة')),
                );
              }
            },
            icon: const Icon(Icons.play_circle_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const _RecurringForm(),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('عملية دورية'),
      ),
      body: recurring.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('لا توجد عمليات دورية بعد'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              final active = item['is_active'] == 1;
              final symbol = item['currency_symbol'].toString();
              final type = item['type'] == 'expense' ? 'مصروف' : 'إيراد';

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(item['type'] == 'expense'
                        ? Icons.trending_down_rounded
                        : Icons.trending_up_rounded),
                  ),
                  title: Text(item['title'].toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '$type • ${MoneyFormatter.format((item['amount'] as num?) ?? 0, symbol)} • ${item['project_name'] ?? ''}\n'
                    '${freqLabel(item['frequency'].toString(), (item['interval_value'] as int?) ?? 1)} • القادم: ${item['next_run_date']}',
                  ),
                  isThreeLine: true,
                  trailing: Switch(
                    value: active,
                    onChanged: (value) async {
                      final db = await ref.read(appDatabaseProvider).database;
                      await db.update(
                        'recurring_transactions',
                        {'is_active': value ? 1 : 0},
                        where: 'id = ?',
                        whereArgs: [item['id']],
                      );
                      ref.invalidate(recurringTransactionsProvider);
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
      ),
    );
  }
}

class _RecurringForm extends ConsumerStatefulWidget {
  const _RecurringForm();

  @override
  ConsumerState<_RecurringForm> createState() => _RecurringFormState();
}

class _RecurringFormState extends ConsumerState<_RecurringForm> {
  final title = TextEditingController();
  final amount = TextEditingController();
  final description = TextEditingController();

  String type = 'expense';
  String frequency = 'monthly';
  int interval = 1;
  int? projectId;
  int? personId;
  int? categoryId;
  DateTime startDate = DateTime.now();
  DateTime? endDate;

  @override
  void dispose() {
    title.dispose();
    amount.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 10),
      initialDate: isStart ? startDate : (endDate ?? startDate),
    );

    if (picked == null) return;
    setState(() {
      if (isStart) {
        startDate = picked;
      } else {
        endDate = picked;
      }
    });
  }

  Future<void> save() async {
    final parsed = double.tryParse(amount.text.trim());
    if (parsed == null ||
        parsed <= 0 ||
        projectId == null ||
        title.text.trim().isEmpty) return;

    final db = await ref.read(appDatabaseProvider).database;
    final settings = await db.query('app_settings', limit: 1);
    final projects = await db.query('projects',
        where: 'id = ?', whereArgs: [projectId], limit: 1);
    if (settings.isEmpty || projects.isEmpty) return;

    final project = projects.first;
    await db.insert('recurring_transactions', {
      'project_id': projectId,
      'person_id': personId,
      'category_id': categoryId,
      'type': type,
      'title': title.text.trim(),
      'amount': parsed,
      'currency_code': project['currency_code'],
      'currency_symbol': project['currency_symbol'],
      'description': description.text.trim(),
      'frequency': frequency,
      'interval_value': interval,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
      'next_run_date': startDate.toIso8601String().split('T').first,
      'is_active': 1,
      'created_by': settings.first['selected_user_id'],
      'created_at': DateTime.now().toIso8601String(),
    });

    ref.invalidate(recurringTransactionsProvider);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider);
    final persons = ref.watch(personsProvider);
    final categories = ref.watch(categoriesProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
          18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('عملية دورية جديدة',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'expense',
                    label: Text('مصروف'),
                    icon: Icon(Icons.trending_down_rounded)),
                ButtonSegment(
                    value: 'income',
                    label: Text('إيراد'),
                    icon: Icon(Icons.trending_up_rounded)),
              ],
              selected: {type},
              onSelectionChanged: (value) => setState(() => type = value.first),
            ),
            const SizedBox(height: 12),
            TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'العنوان')),
            const SizedBox(height: 12),
            TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'المبلغ')),
            const SizedBox(height: 12),
            projects.when(
              data: (items) => DropdownButtonFormField<int>(
                initialValue: projectId,
                decoration: const InputDecoration(labelText: 'المشروع'),
                items: items
                    .map((p) => DropdownMenuItem<int>(
                        value: p['id'] as int,
                        child: Text(p['name'].toString())))
                    .toList(),
                onChanged: (value) => setState(() => projectId = value),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('$e'),
            ),
            const SizedBox(height: 12),
            if (type == 'expense') ...[
              persons.when(
                data: (items) => DropdownButtonFormField<int>(
                  initialValue: personId,
                  decoration: const InputDecoration(labelText: 'الشخص اختياري'),
                  items: items
                      .map((p) => DropdownMenuItem<int>(
                          value: p['id'] as int,
                          child: Text(p['name'].toString())))
                      .toList(),
                  onChanged: (value) => setState(() => personId = value),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('$e'),
              ),
              const SizedBox(height: 12),
              categories.when(
                data: (items) => DropdownButtonFormField<int>(
                  initialValue: categoryId,
                  decoration:
                      const InputDecoration(labelText: 'التصنيف اختياري'),
                  items: items
                      .map((c) => DropdownMenuItem<int>(
                          value: c['id'] as int,
                          child: Text(c['name'].toString())))
                      .toList(),
                  onChanged: (value) => setState(() => categoryId = value),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('$e'),
              ),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<String>(
              initialValue: frequency,
              decoration: const InputDecoration(labelText: 'التكرار'),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('يومي')),
                DropdownMenuItem(value: 'weekly', child: Text('أسبوعي')),
                DropdownMenuItem(value: 'monthly', child: Text('شهري')),
                DropdownMenuItem(value: 'yearly', child: Text('سنوي')),
              ],
              onChanged: (value) =>
                  setState(() => frequency = value ?? 'monthly'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: interval,
              decoration: const InputDecoration(labelText: 'كل كم فترة؟'),
              items: List.generate(
                  12,
                  (i) =>
                      DropdownMenuItem(value: i + 1, child: Text('${i + 1}'))),
              onChanged: (value) => setState(() => interval = value ?? 1),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => pickDate(isStart: true),
                    icon: const Icon(Icons.date_range_rounded),
                    label: Text(
                        'البداية: ${startDate.toIso8601String().split('T').first}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => pickDate(isStart: false),
                    icon: const Icon(Icons.event_busy_rounded),
                    label: Text(endDate == null
                        ? 'نهاية اختيارية'
                        : 'النهاية: ${endDate!.toIso8601String().split('T').first}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
                controller: description,
                decoration: const InputDecoration(labelText: 'تفاصيل')),
            const SizedBox(height: 16),
            FilledButton.icon(
                onPressed: save,
                icon: const Icon(Icons.save_rounded),
                label: const Text('حفظ')),
          ],
        ),
      ),
    );
  }
}
