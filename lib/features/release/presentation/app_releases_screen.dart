import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';

class AppReleasesScreen extends ConsumerWidget {
  const AppReleasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final releases = ref.watch(appReleasesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('سجل الإصدارات')),
      body: releases.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('لا توجد إصدارات مسجلة'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              final current = item['is_current'] == 1;

              return Card(
                child: ListTile(
                  leading: Icon(
                    current ? Icons.verified_rounded : Icons.history_rounded,
                    color: current ? Colors.green : Colors.blue,
                  ),
                  title: Text('${item['title']} - v${item['version']}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      '${item['notes'] ?? ''}\nتاريخ الإصدار: ${item['release_date']}'),
                  isThreeLine: true,
                  trailing: current ? const Text('الحالي') : null,
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
