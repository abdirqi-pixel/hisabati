import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';

class FeatureRequestsScreen extends ConsumerWidget {
  const FeatureRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(featureRequestsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('طلبات الميزات')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const _FeatureRequestForm(),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('طلب ميزة'),
      ),
      body: requests.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('لا توجد طلبات ميزات بعد'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];

              return Card(
                child: ListTile(
                  leading:
                      const Icon(Icons.lightbulb_rounded, color: Colors.amber),
                  title: Text(item['title'].toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${item['description'] ?? ''}\nالأولوية: ${item['priority']} • الحالة: ${item['status']}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      final db = await ref.read(appDatabaseProvider).database;
                      await db.update(
                        'feature_requests',
                        {'status': value},
                        where: 'id = ?',
                        whereArgs: [item['id']],
                      );
                      ref.invalidate(featureRequestsProvider);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'مقترحة', child: Text('مقترحة')),
                      PopupMenuItem(
                          value: 'قيد الدراسة', child: Text('قيد الدراسة')),
                      PopupMenuItem(value: 'مخطط لها', child: Text('مخطط لها')),
                      PopupMenuItem(value: 'منفذة', child: Text('منفذة')),
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

class _FeatureRequestForm extends ConsumerStatefulWidget {
  const _FeatureRequestForm();

  @override
  ConsumerState<_FeatureRequestForm> createState() =>
      _FeatureRequestFormState();
}

class _FeatureRequestFormState extends ConsumerState<_FeatureRequestForm> {
  final title = TextEditingController();
  final description = TextEditingController();
  String priority = 'متوسطة';

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (title.text.trim().isEmpty) return;

    final db = await ref.read(appDatabaseProvider).database;
    await db.insert('feature_requests', {
      'title': title.text.trim(),
      'description': description.text.trim(),
      'priority': priority,
      'status': 'مقترحة',
      'created_at': DateTime.now().toIso8601String(),
    });

    ref.invalidate(featureRequestsProvider);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('طلب ميزة جديدة',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'عنوان الميزة')),
            const SizedBox(height: 10),
            TextField(
                controller: description,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'وصف الميزة')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: priority,
              decoration: const InputDecoration(labelText: 'الأولوية'),
              items: const [
                DropdownMenuItem(value: 'عالية', child: Text('عالية')),
                DropdownMenuItem(value: 'متوسطة', child: Text('متوسطة')),
                DropdownMenuItem(value: 'منخفضة', child: Text('منخفضة')),
              ],
              onChanged: (value) =>
                  setState(() => priority = value ?? 'متوسطة'),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
                onPressed: save,
                icon: const Icon(Icons.save_rounded),
                label: const Text('حفظ')),
          ],
        ),
      ),
    );
  }
}
