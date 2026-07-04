import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';
import '../../../core/services/activity_log_service.dart';
import '../../../core/utils/money_formatter.dart';

class AdvancesScreen extends ConsumerWidget {
  const AdvancesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final advances = ref.watch(advancesProvider);
    final summary = ref.watch(advancesSummaryProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الديون والسلف')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const _AdvanceForm(),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('حركة جديدة'),
      ),
      body: settings.when(
        data: (s) {
          final symbol = (s?['currency_symbol'] ?? 'د.ع').toString();

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Text('ملخص السلف', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              summary.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text('لا توجد سلف أو تسديدات'),
                      ),
                    );
                  }

                  return Column(
                    children: items.map((item) {
                      final remaining = (item['remaining'] as num?) ?? 0;
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
                          title: Text(item['person_name'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            'السلف: ${MoneyFormatter.format((item['total_advances'] as num?) ?? 0, symbol)}\n'
                            'المسدد: ${MoneyFormatter.format((item['total_payments'] as num?) ?? 0, symbol)}',
                          ),
                          isThreeLine: true,
                          trailing: Text(
                            MoneyFormatter.format(remaining, symbol),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: remaining > 0 ? Colors.red : Colors.green,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('خطأ: $e'),
              ),
              const SizedBox(height: 22),
              const Text('آخر الحركات', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              advances.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text('لا توجد حركات بعد'),
                      ),
                    );
                  }

                  return Column(
                    children: items.map((a) {
                      final isAdvance = a['type'] == 'advance';
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Icon(isAdvance ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded),
                          ),
                          title: Text(
                            '${a['amount']} ${a['currency_symbol']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('${isAdvance ? 'سلفة' : 'تسديد'} • ${a['person_name'] ?? 'بدون شخص'}\n${a['note'] ?? ''}'),
                          isThreeLine: true,
                          trailing: Text(a['advance_date'].toString()),
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

class _AdvanceForm extends ConsumerStatefulWidget {
  const _AdvanceForm();

  @override
  ConsumerState<_AdvanceForm> createState() => _AdvanceFormState();
}

class _AdvanceFormState extends ConsumerState<_AdvanceForm> {
  final amount = TextEditingController();
  final note = TextEditingController();
  String type = 'advance';
  int? selectedPersonId;

  @override
  void dispose() {
    amount.dispose();
    note.dispose();
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
    final id = await db.insert('advances', {
      'project_id': projects.first['id'],
      'person_id': selectedPersonId,
      'type': type,
      'amount': parsed,
      'currency_code': settings.first['currency_code'],
      'currency_symbol': settings.first['currency_symbol'],
      'note': note.text.trim(),
      'advance_date': now.toIso8601String().split('T').first,
      'created_by': settings.first['selected_user_id'],
      'created_at': now.toIso8601String(),
    });

    await ActivityLogService(ref.read(appDatabaseProvider)).log(
      action: 'create',
      entityType: 'advance',
      entityId: id,
      userId: settings.first['selected_user_id'] as int?,
      details: type == 'advance' ? 'تمت إضافة سلفة بمبلغ $parsed' : 'تم تسجيل تسديد بمبلغ $parsed',
    );

    ref.invalidate(advancesProvider);
    ref.invalidate(advancesSummaryProvider);
    ref.invalidate(activityLogProvider);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final persons = ref.watch(personsProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('حركة سلفة جديدة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'advance', label: Text('سلفة'), icon: Icon(Icons.arrow_upward_rounded)),
              ButtonSegment(value: 'payment', label: Text('تسديد'), icon: Icon(Icons.arrow_downward_rounded)),
            ],
            selected: {type},
            onSelectionChanged: (value) => setState(() => type = value.first),
          ),
          const SizedBox(height: 12),
          persons.when(
            data: (items) => DropdownButtonFormField<int>(
              value: selectedPersonId,
              decoration: const InputDecoration(labelText: 'الشخص', prefixIcon: Icon(Icons.person_rounded)),
              items: items.map((p) {
                return DropdownMenuItem<int>(
                  value: p['id'] as int,
                  child: Text(p['name'] as String),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedPersonId = value),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'المبلغ', prefixIcon: Icon(Icons.payments_rounded)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: note,
            decoration: const InputDecoration(labelText: 'ملاحظة', prefixIcon: Icon(Icons.notes_rounded)),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: save, icon: const Icon(Icons.save_rounded), label: const Text('حفظ')),
        ],
      ),
    );
  }
}