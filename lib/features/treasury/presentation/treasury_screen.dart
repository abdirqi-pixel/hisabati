import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';
import '../../../core/utils/money_formatter.dart';

class TreasuryScreen extends ConsumerWidget {
  const TreasuryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(treasuryTransactionsProvider);
    final summary = ref.watch(dashboardSummaryProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الصندوق')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const _TreasuryForm(),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('حركة جديدة'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          settings.when(
            data: (s) {
              final symbol = (s?['currency_symbol'] ?? 'د.ع').toString();
              return summary.when(
                data: (sum) => Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF3B82F6)]),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('الرصيد الحالي', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 8),
                      Text(
                        MoneyFormatter.format(sum['currentBalance'] ?? 0, symbol),
                        style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 14),
                      Text('الإيداعات: ${MoneyFormatter.format(sum['deposits'] ?? 0, symbol)}', style: const TextStyle(color: Colors.white)),
                      Text('السحوبات: ${MoneyFormatter.format(sum['withdrawals'] ?? 0, symbol)}', style: const TextStyle(color: Colors.white)),
                      Text('المصروفات: ${MoneyFormatter.format(sum['expensesTotal'] ?? 0, symbol)}', style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('خطأ: $e'),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('خطأ: $e'),
          ),
          const SizedBox(height: 18),
          const Text('آخر حركات الصندوق', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          transactions.when(
            data: (items) {
              if (items.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('لا توجد حركات صندوق بعد'),
                  ),
                );
              }
              return Column(
                children: items.map((t) {
                  final isDeposit = t['type'] == 'deposit';
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(isDeposit ? Icons.add_rounded : Icons.remove_rounded),
                      ),
                      title: Text(
                        '${t['amount']} ${t['currency_symbol']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${isDeposit ? 'إيداع' : 'سحب'} • ${t['note'] ?? ''}'),
                      trailing: Text((t['transaction_date'] ?? '').toString()),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('خطأ: $e')),
          ),
        ],
      ),
    );
  }
}

class _TreasuryForm extends ConsumerStatefulWidget {
  const _TreasuryForm();

  @override
  ConsumerState<_TreasuryForm> createState() => _TreasuryFormState();
}

class _TreasuryFormState extends ConsumerState<_TreasuryForm> {
  final amount = TextEditingController();
  final note = TextEditingController();
  String type = 'deposit';

  @override
  void dispose() {
    amount.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final parsedAmount = double.tryParse(amount.text.trim());
    if (parsedAmount == null || parsedAmount <= 0) return;

    final db = await ref.read(appDatabaseProvider).database;
    final projects = await db.query('projects', limit: 1);
    final settings = await db.query('app_settings', limit: 1);
    if (projects.isEmpty || settings.isEmpty) return;

    final now = DateTime.now();
    await db.insert('treasury_transactions', {
      'project_id': projects.first['id'],
      'type': type,
      'amount': parsedAmount,
      'currency_code': settings.first['currency_code'],
      'currency_symbol': settings.first['currency_symbol'],
      'note': note.text.trim(),
      'transaction_date': now.toIso8601String().split('T').first,
      'created_by': settings.first['selected_user_id'],
      'created_at': now.toIso8601String(),
    });

    ref.invalidate(treasuryTransactionsProvider);
    ref.invalidate(dashboardSummaryProvider);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('حركة صندوق جديدة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'deposit', label: Text('إيداع'), icon: Icon(Icons.add_rounded)),
              ButtonSegment(value: 'withdraw', label: Text('سحب'), icon: Icon(Icons.remove_rounded)),
            ],
            selected: {type},
            onSelectionChanged: (value) => setState(() => type = value.first),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'المبلغ', prefixIcon: Icon(Icons.payments_rounded)),
          ),
          const SizedBox(height: 10),
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