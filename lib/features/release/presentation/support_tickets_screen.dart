import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';

class SupportTicketsScreen extends ConsumerWidget {
  const SupportTicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(supportTicketsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الدعم والمشاكل')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const _SupportTicketForm(),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('بلاغ دعم'),
      ),
      body: tickets.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('لا توجد بلاغات دعم بعد'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.support_agent_rounded,
                      color: Colors.blue),
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
                        'support_tickets',
                        {'status': value},
                        where: 'id = ?',
                        whereArgs: [item['id']],
                      );
                      ref.invalidate(supportTicketsProvider);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'مفتوح', child: Text('مفتوح')),
                      PopupMenuItem(
                          value: 'قيد المعالجة', child: Text('قيد المعالجة')),
                      PopupMenuItem(value: 'تم الحل', child: Text('تم الحل')),
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

class _SupportTicketForm extends ConsumerStatefulWidget {
  const _SupportTicketForm();

  @override
  ConsumerState<_SupportTicketForm> createState() => _SupportTicketFormState();
}

class _SupportTicketFormState extends ConsumerState<_SupportTicketForm> {
  final title = TextEditingController();
  final description = TextEditingController();
  final deviceInfo = TextEditingController();
  String priority = 'متوسطة';

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    deviceInfo.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (title.text.trim().isEmpty) return;

    final db = await ref.read(appDatabaseProvider).database;
    await db.insert('support_tickets', {
      'title': title.text.trim(),
      'description': description.text.trim(),
      'priority': priority,
      'status': 'مفتوح',
      'device_info': deviceInfo.text.trim(),
      'created_at': DateTime.now().toIso8601String(),
    });

    ref.invalidate(supportTicketsProvider);
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
            const Text('بلاغ دعم جديد',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'عنوان المشكلة')),
            const SizedBox(height: 10),
            TextField(
                controller: description,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'وصف المشكلة')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: priority,
              decoration: const InputDecoration(labelText: 'الأولوية'),
              items: const [
                DropdownMenuItem(value: 'حرجة', child: Text('حرجة')),
                DropdownMenuItem(value: 'عالية', child: Text('عالية')),
                DropdownMenuItem(value: 'متوسطة', child: Text('متوسطة')),
                DropdownMenuItem(value: 'منخفضة', child: Text('منخفضة')),
              ],
              onChanged: (value) =>
                  setState(() => priority = value ?? 'متوسطة'),
            ),
            const SizedBox(height: 10),
            TextField(
                controller: deviceInfo,
                decoration: const InputDecoration(labelText: 'معلومات الجهاز')),
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
