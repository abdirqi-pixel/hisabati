import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';

class PersonsScreen extends ConsumerWidget {
  const PersonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final persons = ref.watch(personsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الأشخاص')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const _PersonForm(),
        ),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('إضافة شخص'),
      ),
      body: persons.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('لا يوجد أشخاص بعد'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final p = items[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text((p['name'] as String).characters.first),
                  ),
                  title: Text(p['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(p['phone']?.toString().isEmpty ?? true
                      ? 'بدون رقم هاتف'
                      : p['phone'].toString()),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'delete') {
                        final db = await ref.read(appDatabaseProvider).database;
                        await db.update('persons', {'is_deleted': 1},
                            where: 'id = ?', whereArgs: [p['id']]);
                        ref.invalidate(personsProvider);
                      }
                    },
                    itemBuilder: (_) => const [
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

class _PersonForm extends ConsumerStatefulWidget {
  const _PersonForm();

  @override
  ConsumerState<_PersonForm> createState() => _PersonFormState();
}

class _PersonFormState extends ConsumerState<_PersonForm> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final notes = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty) return;

    final db = await ref.read(appDatabaseProvider).database;
    final projects = await db.query('projects', limit: 1);
    if (projects.isEmpty) return;

    await db.insert('persons', {
      'project_id': projects.first['id'],
      'name': name.text.trim(),
      'phone': phone.text.trim(),
      'notes': notes.text.trim(),
      'color': '#10B981',
      'created_at': DateTime.now().toIso8601String(),
    });

    ref.invalidate(personsProvider);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('إضافة شخص',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'اسم الشخص')),
          const SizedBox(height: 10),
          TextField(
              controller: phone,
              decoration:
                  const InputDecoration(labelText: 'رقم الهاتف اختياري')),
          const SizedBox(height: 10),
          TextField(
              controller: notes,
              decoration: const InputDecoration(labelText: 'ملاحظات')),
          const SizedBox(height: 16),
          FilledButton.icon(
              onPressed: save,
              icon: const Icon(Icons.save_rounded),
              label: const Text('حفظ')),
        ],
      ),
    );
  }
}
