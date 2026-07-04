import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';
import '../../../core/services/activity_log_service.dart';
import '../../../core/utils/money_formatter.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(budgetOverviewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الميزانيات')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const _BudgetForm(),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('ميزانية جديدة'),
      ),
      body: overview.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('لا توجد ميزانيات بعد'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final b = items[index];
              final symbol = b['currency_symbol'].toString();
              final amount = (b['amount'] as num?) ?? 0;
              final spent = (b['spent'] as num?) ?? 0;
              final percent = (b['percent'] as num?) ?? 0;
              final alertPercent = (b['alert_percent'] as num?) ?? .8;
              final isOverAlert = percent >= alertPercent;
              final isOverBudget = percent >= 1;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              b['name'].toString(),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'disable') {
                                final db = await ref.read(appDatabaseProvider).database;
                                await db.update('budgets', {'is_active': 0}, where: 'id = ?', whereArgs: [b['id']]);
                                ref.invalidate(budgetsProvider);
                                ref.invalidate(budgetOverviewProvider);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'disable', child: Text('إيقاف')),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('${b['project_name']} • ${b['type'] == 'monthly' ? 'شهرية' : 'سنوية'} • ${b['period_year']}${b['period_month'] == null ? '' : '/${b['period_month']}'}'),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(value: percent > 1 ? 1 : percent.toDouble()),
                      const SizedBox(height: 8),
                      Text('المصروف: ${MoneyFormatter.format(spent, symbol)}'),
                      Text('الميزانية: ${MoneyFormatter.format(amount, symbol)}'),
                      Text('النسبة: ${(percent * 100).toStringAsFixed(0)}%'),
                      if (isOverBudget)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text('تم تجاوز الميزانية', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        )
                      else if (isOverAlert)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text('اقتربت من حد التنبيه', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                        ),
                    ],
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

class _BudgetForm extends ConsumerStatefulWidget {
  const _BudgetForm();

  @override
  ConsumerState<_BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends ConsumerState<_BudgetForm> {
  final name = TextEditingController();
  final amount = TextEditingController();
  String type = 'monthly';
  int? projectId;
  int year = DateTime.now().year;
  int month = DateTime.now().month;
  double alertPercent = .8;

  @override
  void dispose() {
    name.dispose();
    amount.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final parsed = double.tryParse(amount.text.trim());
    if (parsed == null || parsed <= 0 || projectId == null) return;

    final db = await ref.read(appDatabaseProvider).database;
    final settings = await db.query('app_settings', limit: 1);
    final projects = await db.query('projects', where: 'id = ?', whereArgs: [projectId], limit: 1);
    if (projects.isEmpty || settings.isEmpty) return;

    final project = projects.first;
    final id = await db.insert('budgets', {
      'project_id': projectId,
      'name': name.text.trim().isEmpty ? 'ميزانية ${type == 'monthly' ? 'شهرية' : 'سنوية'}' : name.text.trim(),
      'type': type,
      'amount': parsed,
      'currency_code': project['currency_code'],
      'currency_symbol': project['currency_symbol'],
      'period_year': year,
      'period_month': type == 'monthly' ? month : null,
      'alert_percent': alertPercent,
      'is_active': 1,
      'created_by': settings.first['selected_user_id'],
      'created_at': DateTime.now().toIso8601String(),
    });

    await ActivityLogService(ref.read(appDatabaseProvider)).log(
      action: 'create',
      entityType: 'budget',
      entityId: id,
      userId: settings.first['selected_user_id'] as int?,
      details: 'تم إنشاء ميزانية بمبلغ $parsed',
    );

    ref.invalidate(budgetsProvider);
    ref.invalidate(budgetOverviewProvider);
    ref.invalidate(activityLogProvider);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('ميزانية جديدة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            projects.when(
              data: (items) => DropdownButtonFormField<int>(
                value: projectId,
                decoration: const InputDecoration(labelText: 'المشروع'),
                items: items.map((p) => DropdownMenuItem<int>(value: p['id'] as int, child: Text(p['name'].toString()))).toList(),
                onChanged: (value) => setState(() => projectId = value),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('$e'),
            ),
            const SizedBox(height: 12),
            TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم الميزانية')),
            const SizedBox(height: 12),
            TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ')),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'monthly', label: Text('شهرية')),
                ButtonSegment(value: 'yearly', label: Text('سنوية')),
              ],
              selected: {type},
              onSelectionChanged: (value) => setState(() => type = value.first),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: year,
                    decoration: const InputDecoration(labelText: 'السنة'),
                    items: List.generate(6, (i) {
                      final y = DateTime.now().year - 2 + i;
                      return DropdownMenuItem(value: y, child: Text('$y'));
                    }),
                    onChanged: (value) => setState(() => year = value ?? DateTime.now().year),
                  ),
                ),
                if (type == 'monthly') ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: month,
                      decoration: const InputDecoration(labelText: 'الشهر'),
                      items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}'))),
                      onChanged: (value) => setState(() => month = value ?? DateTime.now().month),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text('نسبة التنبيه: ${(alertPercent * 100).toStringAsFixed(0)}%'),
            Slider(
              value: alertPercent,
              min: .5,
              max: 1,
              divisions: 5,
              label: '${(alertPercent * 100).toStringAsFixed(0)}%',
              onChanged: (value) => setState(() => alertPercent = value),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: save, icon: const Icon(Icons.save_rounded), label: const Text('حفظ')),
          ],
        ),
      ),
    );
  }
}