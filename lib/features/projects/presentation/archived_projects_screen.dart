import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';

class ArchivedProjectsScreen extends ConsumerWidget {
  const ArchivedProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archived = ref.watch(archivedProjectsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('المشاريع المؤرشفة')),
      body: archived.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('لا توجد مشاريع مؤرشفة'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final p = items[index];

              return Card(
                child: ListTile(
                  leading: Text((p['icon'] ?? '📁').toString(), style: const TextStyle(fontSize: 32)),
                  title: Text(p['name'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('العملة: ${p['currency_symbol']}'),
                  trailing: TextButton(
                    onPressed: () async {
                      final db = await ref.read(appDatabaseProvider).database;
                      await db.update('projects', {'is_archived': 0}, where: 'id = ?', whereArgs: [p['id']]);
                      ref.invalidate(projectsProvider);
                      ref.invalidate(archivedProjectsProvider);
                    },
                    child: const Text('استعادة'),
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