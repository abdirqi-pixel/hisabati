import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';

class ActivityLogScreen extends ConsumerWidget {
  const ActivityLogScreen({super.key});

  String actionLabel(String action) {
    switch (action) {
      case 'create':
        return 'إضافة';
      case 'update':
        return 'تعديل';
      case 'delete':
        return 'حذف';
      case 'archive':
        return 'أرشفة';
      case 'restore':
        return 'استعادة';
      default:
        return action;
    }
  }

  IconData actionIcon(String action) {
    switch (action) {
      case 'create':
        return Icons.add_circle_rounded;
      case 'update':
        return Icons.edit_rounded;
      case 'delete':
        return Icons.delete_rounded;
      case 'archive':
        return Icons.archive_rounded;
      case 'restore':
        return Icons.restore_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(activityLogProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('سجل النشاط')),
      body: logs.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('لا يوجد نشاط مسجل بعد'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final log = items[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Icon(actionIcon(log['action'].toString()))),
                  title: Text(
                    '${actionLabel(log['action'].toString())} • ${log['entity_type']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${log['details'] ?? ''}\nبواسطة: ${log['user_name'] ?? 'غير معروف'}'),
                  isThreeLine: true,
                  trailing: Text((log['created_at'] ?? '').toString().split('T').first),
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