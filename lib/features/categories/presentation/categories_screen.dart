import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('التصنيفات')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const _CategoryForm(),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('تصنيف جديد'),
      ),
      body: categories.when(
        data: (items) => ListView.separated(
          padding: const EdgeInsets.all(18),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final c = items[index];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.category_rounded)),
                title: Text(c['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(c['is_default'] == 1 ? 'تصنيف افتراضي' : 'تصنيف مخصص'),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'delete') {
                      final db = await ref.read(appDatabaseProvider).database;
                      await db.update('categories', {'is_deleted': 1}, where: 'id = ?', whereArgs: [c['id']]);
                      ref.invalidate(categoriesProvider);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'delete', child: Text('حذف')),
                  ],
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
      ),
    );
  }
}

class _CategoryForm extends ConsumerStatefulWidget {
  const _CategoryForm();

  @override
  ConsumerState<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends ConsumerState<_CategoryForm> {
  final name = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty) return;

    final db = await ref.read(appDatabaseProvider).database;
    final projects = await db.query('projects', limit: 1);
    await db.insert('categories', {
      'project_id': projects.isEmpty ? null : projects.first['id'],
      'name': name.text.trim(),
      'icon': 'category_rounded',
      'color': '#10B981',
      'sort_order': 99,
      'is_default': 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    ref.invalidate(categoriesProvider);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('إضافة تصنيف', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم التصنيف')),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: save, icon: const Icon(Icons.save_rounded), label: const Text('حفظ')),
        ],
      ),
    );
  }
}