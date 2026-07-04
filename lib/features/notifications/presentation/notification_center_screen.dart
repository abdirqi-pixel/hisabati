import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';
import '../../../core/services/app_notification_service.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  IconData iconForType(String type) {
    switch (type) {
      case 'budget_warning':
        return Icons.warning_amber_rounded;
      case 'budget_exceeded':
        return Icons.error_rounded;
      case 'treasury_low':
        return Icons.account_balance_wallet_rounded;
      case 'advance_due':
        return Icons.handshake_rounded;
      case 'reminder':
        return Icons.notifications_active_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color colorForType(String type) {
    switch (type) {
      case 'budget_exceeded':
        return Colors.red;
      case 'budget_warning':
        return Colors.orange;
      case 'treasury_low':
        return Colors.blue;
      case 'advance_due':
        return Colors.purple;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(appNotificationsProvider);
    final service = AppNotificationService(ref.read(appDatabaseProvider));

    return Scaffold(
      appBar: AppBar(
        title: const Text('مركز الإشعارات'),
        actions: [
          IconButton(
            tooltip: 'تعليم الكل كمقروء',
            onPressed: () async {
              await service.markAllAsRead();
              ref.invalidate(appNotificationsProvider);
              ref.invalidate(unreadNotificationsCountProvider);
            },
            icon: const Icon(Icons.done_all_rounded),
          ),
          IconButton(
            tooltip: 'حذف المقروء',
            onPressed: () async {
              await service.clearRead();
              ref.invalidate(appNotificationsProvider);
              ref.invalidate(unreadNotificationsCountProvider);
            },
            icon: const Icon(Icons.cleaning_services_rounded),
          ),
        ],
      ),
      body: notifications.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('لا توجد إشعارات بعد'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              final isRead = item['is_read'] == 1;
              final type = item['type'].toString();

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorForType(type).withOpacity(.15),
                    child: Icon(iconForType(type), color: colorForType(type)),
                  ),
                  title: Text(
                    item['title'].toString(),
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text('${item['message']}\n${item['created_at']}'),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'read') {
                        await service.markAsRead(item['id'] as int);
                      }
                      if (value == 'delete') {
                        await service.delete(item['id'] as int);
                      }

                      ref.invalidate(appNotificationsProvider);
                      ref.invalidate(unreadNotificationsCountProvider);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'read', child: Text('تعليم كمقروء')),
                      PopupMenuItem(value: 'delete', child: Text('حذف')),
                    ],
                  ),
                  onTap: () async {
                    await service.markAsRead(item['id'] as int);
                    ref.invalidate(appNotificationsProvider);
                    ref.invalidate(unreadNotificationsCountProvider);
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