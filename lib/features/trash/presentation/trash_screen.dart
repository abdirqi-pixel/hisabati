import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';

class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  Future<void> restore({
    required WidgetRef ref,
    required String table,
    required int id,
  }) async {
    final db = await ref.read(appDatabaseProvider).database;
    await db.update(table, {'is_deleted': 0}, where: 'id = ?', whereArgs: [id]);

    ref.invalidate(trashProvider);
    ref.invalidate(projectsProvider);
    ref.invalidate(personsProvider);
    ref.invalidate(categoriesProvider);
    ref.invalidate(expensesProvider);
    ref.invalidate(treasuryTransactionsProvider);
    ref.invalidate(advancesProvider);
    ref.invalidate(advancesSummaryProvider);
    ref.invalidate(incomesProvider);
    ref.invalidate(incomesTotalProvider);
    ref.invalidate(dashboardSummaryProvider);
    ref.invalidate(reportsSummaryProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trash = ref.watch(trashProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('سلة المحذوفات')),
      body: trash.when(
        data: (data) {
          final sections = [
            _SectionData('المشاريع', 'projects', data['projects'] ?? []),
            _SectionData('الأشخاص', 'persons', data['persons'] ?? []),
            _SectionData('التصنيفات', 'categories', data['categories'] ?? []),
            _SectionData('العمليات', 'expenses', data['expenses'] ?? []),
            _SectionData('الصندوق', 'treasury_transactions', data['treasury_transactions'] ?? []),
            _SectionData('الديون والسلف', 'advances', data['advances'] ?? []),
            _SectionData('الإيرادات', 'incomes', data['incomes'] ?? []),
          ];

          final hasItems = sections.any((s) => s.items.isNotEmpty);
          if (!hasItems) {
            return const Center(child: Text('سلة المحذوفات فارغة'));
          }

          return ListView(
            padding: const EdgeInsets.all(18),
            children: sections.where((s) => s.items.isNotEmpty).map((section) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(section.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...section.items.map((item) {
                    final title = item['name'] ?? item['serial_number'] ?? item['note'] ?? 'عنصر محذوف';
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.delete_rounded),
                        title: Text(title.toString()),
                        subtitle: Text('ID: ${item['id']}'),
                        trailing: TextButton(
                          onPressed: () => restore(
                            ref: ref,
                            table: section.table,
                            id: item['id'] as int,
                          ),
                          child: const Text('استعادة'),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 18),
                ],
              );
            }).toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
      ),
    );
  }
}

class _SectionData {
  const _SectionData(this.title, this.table, this.items);

  final String title;
  final String table;
  final List<Map<String, Object?>> items;
}