import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/database_providers.dart';
import '../../../core/utils/money_formatter.dart';
import 'project_details_screen.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المشاريع'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            onPressed: () => context.go('/archived-projects'),
            icon: const Icon(Icons.archive_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/project-form'),
        label: const Text('مشروع جديد'),
        icon: const Icon(Icons.add_rounded),
      ),
      body: projects.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('لا توجد مشاريع بعد'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final p = items[index];
              final budget = (p['budget'] as num?) ?? 0;
              final opening = (p['opening_balance'] as num?) ?? 0;
              final symbol = (p['currency_symbol'] ?? '').toString();

              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProjectDetailsScreen(projectId: p['id'] as int),
                      ),
                    );
                  },
                  child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Text((p['icon'] ?? '📁').toString(), style: const TextStyle(fontSize: 38)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p['name'].toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('الرمز: ${p['code'] ?? 'بدون رمز'}'),
                            const SizedBox(height: 6),
                            Text('الميزانية: ${MoneyFormatter.format(budget, symbol)}'),
                            Text('الرصيد الافتتاحي: ${MoneyFormatter.format(opening, symbol)}'),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          final db = await ref.read(appDatabaseProvider).database;

                          if (value == 'edit') {
                            context.go('/project-form?id=${p['id']}');
                          }

                          if (value == 'archive') {
                            await db.update('projects', {'is_archived': 1}, where: 'id = ?', whereArgs: [p['id']]);
                            ref.invalidate(projectsProvider);
                            ref.invalidate(archivedProjectsProvider);
                            ref.invalidate(dashboardSummaryProvider);
                          }

                          if (value == 'delete') {
                            await db.update('projects', {'is_deleted': 1}, where: 'id = ?', whereArgs: [p['id']]);
                            ref.invalidate(projectsProvider);
                            ref.invalidate(dashboardSummaryProvider);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('تعديل')),
                          PopupMenuItem(value: 'archive', child: Text('أرشفة')),
                          PopupMenuItem(value: 'delete', child: Text('حذف')),
                        ],
                      ),
                    ],
                  ),
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