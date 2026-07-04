import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/database_providers.dart';

class SavedReportFiltersScreen extends ConsumerWidget {
  const SavedReportFiltersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(savedReportFiltersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الفلاتر المحفوظة')),
      body: filters.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('لا توجد فلاتر محفوظة بعد'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.filter_alt_rounded)),
                  title: Text(item['name'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'مشروع: ${item['project_id'] ?? 'الكل'} • شخص: ${item['person_id'] ?? 'الكل'} • تصنيف: ${item['category_id'] ?? 'الكل'}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      final db = await ref.read(appDatabaseProvider).database;

                      if (value == 'apply') {
                        ref.read(reportFilterProvider.notifier).state = ReportFilter(
                          projectId: item['project_id'] as int?,
                          personId: item['person_id'] as int?,
                          categoryId: item['category_id'] as int?,
                          dateFrom: item['date_from']?.toString(),
                          dateTo: item['date_to']?.toString(),
                          amountFrom: (item['amount_from'] as num?)?.toDouble(),
                          amountTo: (item['amount_to'] as num?)?.toDouble(),
                        );
                        context.go('/advanced-reports');
                      }

                      if (value == 'delete') {
                        await db.delete('saved_report_filters', where: 'id = ?', whereArgs: [item['id']]);
                        ref.invalidate(savedReportFiltersProvider);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'apply', child: Text('تطبيق')),
                      PopupMenuItem(value: 'delete', child: Text('حذف')),
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