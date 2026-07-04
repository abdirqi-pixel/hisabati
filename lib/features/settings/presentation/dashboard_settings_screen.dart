import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';

class DashboardSettingsScreen extends ConsumerWidget {
  const DashboardSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(dashboardPreferencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('تخصيص لوحة التحكم')),
      body: prefs.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('لا توجد خيارات تخصيص'));
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: items.length,
            onReorder: (oldIndex, newIndex) async {
              if (newIndex > oldIndex) newIndex -= 1;
              final updated = [...items];
              final item = updated.removeAt(oldIndex);
              updated.insert(newIndex, item);

              final db = await ref.read(appDatabaseProvider).database;
              for (var i = 0; i < updated.length; i++) {
                await db.update(
                  'dashboard_preferences',
                  {'sort_order': i},
                  where: 'id = ?',
                  whereArgs: [updated[i]['id']],
                );
              }

              ref.invalidate(dashboardPreferencesProvider);
              ref.invalidate(dashboardVisibleKeysProvider);
            },
            itemBuilder: (context, index) {
              final item = items[index];
              final visible = item['is_visible'] == 1;

              return Card(
                key: ValueKey(item['id']),
                child: SwitchListTile(
                  secondary: const Icon(Icons.drag_handle_rounded),
                  title: Text(item['title'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(visible ? 'ظاهر في الرئيسية' : 'مخفي من الرئيسية'),
                  value: visible,
                  onChanged: (value) async {
                    final db = await ref.read(appDatabaseProvider).database;
                    await db.update(
                      'dashboard_preferences',
                      {'is_visible': value ? 1 : 0},
                      where: 'id = ?',
                      whereArgs: [item['id']],
                    );

                    ref.invalidate(dashboardPreferencesProvider);
                    ref.invalidate(dashboardVisibleKeysProvider);
                  },
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