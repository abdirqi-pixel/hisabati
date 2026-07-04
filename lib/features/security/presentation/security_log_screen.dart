import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';

class SecurityLogScreen extends ConsumerWidget {
  const SecurityLogScreen({super.key});

  IconData iconFor(String type) {
    switch (type) {
      case 'manual_lock':
        return Icons.lock_rounded;
      case 'auto_lock_updated':
        return Icons.timer_rounded;
      case 'biometric_enabled':
        return Icons.fingerprint_rounded;
      case 'biometric_disabled':
        return Icons.fingerprint_rounded;
      default:
        return Icons.security_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(securityLogProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('سجل الأمان')),
      body: logs.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('لا يوجد سجل أمان بعد'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                      child: Icon(iconFor(item['event_type'].toString()))),
                  title: Text(item['message'].toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(item['event_type'].toString()),
                  trailing:
                      Text(item['created_at'].toString().split('T').first),
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
