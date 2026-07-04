import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';
import '../../../core/services/activity_log_service.dart';
import '../../../core/utils/money_formatter.dart';

class IncomesScreen extends ConsumerWidget {
  const IncomesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomes = ref.watch(incomesProvider);
    final total = ref.watch(incomesTotalProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الإيرادات')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const _IncomeForm(),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('إيراد جديد'),
      ),
      body: settings.when(
        data: (s) {
          final symbol = (s?['currency_symbol'] ?? 'د.ع').toString();

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              total.when(
                data: (value) => Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF3B82F6)]),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('إجمالي الإيرادات',
                          style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 8),
                      Text(
                        MoneyFormatter.format(value, symbol),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('خطأ: $e'),
              ),
              const SizedBox(height: 18),
              const Text('آخر الإيرادات',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              incomes.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text('لا توجد إيرادات بعد'),
                      ),
                    );
                  }

                  return Column(
                    children: items.map((income) {
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                              child: Icon(Icons.trending_up_rounded)),
                          title: Text(
                            '${income['amount']} ${income['currency_symbol']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                              '${income['source'] ?? 'مصدر غير محدد'}\n${income['description'] ?? ''}'),
                          isThreeLine: true,
                          trailing: Text(income['income_date'].toString()),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('خطأ: $e'),
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

class _IncomeForm extends ConsumerStatefulWidget {
  const _IncomeForm();

  @override
  ConsumerState<_IncomeForm> createState() => _IncomeFormState();
}

class _IncomeFormState extends ConsumerState<_IncomeForm> {
  final amount = TextEditingController();
  final source = TextEditingController();
  final description = TextEditingController();

  @override
  void dispose() {
    amount.dispose();
    source.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final parsed = double.tryParse(amount.text.trim());
    if (parsed == null || parsed <= 0) return;

    final db = await ref.read(appDatabaseProvider).database;
    final projects = await db.query('projects', limit: 1);
    final settings = await db.query('app_settings', limit: 1);
    if (projects.isEmpty || settings.isEmpty) return;

    final now = DateTime.now();
    final id = await db.insert('incomes', {
      'project_id': projects.first['id'],
      'amount': parsed,
      'currency_code': settings.first['currency_code'],
      'currency_symbol': settings.first['currency_symbol'],
      'source': source.text.trim(),
      'description': description.text.trim(),
      'income_date': now.toIso8601String().split('T').first,
      'created_by': settings.first['selected_user_id'],
      'created_at': now.toIso8601String(),
    });

    await ActivityLogService(ref.read(appDatabaseProvider)).log(
      action: 'create',
      entityType: 'income',
      entityId: id,
      userId: settings.first['selected_user_id'] as int?,
      details: 'تمت إضافة إيراد بمبلغ $parsed',
    );

    ref.invalidate(incomesProvider);
    ref.invalidate(incomesTotalProvider);
    ref.invalidate(dashboardSummaryProvider);
    ref.invalidate(activityLogProvider);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('إيراد جديد',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'المبلغ', prefixIcon: Icon(Icons.payments_rounded)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: source,
            decoration: const InputDecoration(
                labelText: 'مصدر الإيراد',
                prefixIcon: Icon(Icons.source_rounded)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: description,
            decoration: const InputDecoration(
                labelText: 'التفاصيل', prefixIcon: Icon(Icons.notes_rounded)),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
              onPressed: save,
              icon: const Icon(Icons.save_rounded),
              label: const Text('حفظ')),
        ],
      ),
    );
  }
}
