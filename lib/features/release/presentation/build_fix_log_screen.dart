import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';

class BuildFixLogScreen extends ConsumerWidget {
  const BuildFixLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(buildFixLogsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('إصلاحات البناء')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const _BuildFixForm(),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('إضافة خطأ'),
      ),
      body: logs.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('لا توجد أخطاء بناء مسجلة بعد'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              final fixed = item['status'] == 'تم الإصلاح';

              return Card(
                child: ListTile(
                  leading: Icon(
                    fixed ? Icons.check_circle_rounded : Icons.bug_report_rounded,
                    color: fixed ? Colors.green : Colors.red,
                  ),
                  title: Text(item['command'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'الحالة: ${item['status']}\n'
                    'الخطأ: ${item['error_text'] ?? ''}\n'
                    'الحل: ${item['fix_text'] ?? ''}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      final db = await ref.read(appDatabaseProvider).database;
                      await db.update(
                        'build_fix_logs',
                        {'status': value},
                        where: 'id = ?',
                        whereArgs: [item['id']],
                      );
                      ref.invalidate(buildFixLogsProvider);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'مفتوح', child: Text('مفتوح')),
                      PopupMenuItem(value: 'قيد الإصلاح', child: Text('قيد الإصلاح')),
                      PopupMenuItem(value: 'تم الإصلاح', child: Text('تم الإصلاح')),
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

class _BuildFixForm extends ConsumerStatefulWidget {
  const _BuildFixForm();

  @override
  ConsumerState<_BuildFixForm> createState() => _BuildFixFormState();
}

class _BuildFixFormState extends ConsumerState<_BuildFixForm> {
  final command = TextEditingController();
  final error = TextEditingController();
  final fix = TextEditingController();

  @override
  void dispose() {
    command.dispose();
    error.dispose();
    fix.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (command.text.trim().isEmpty) return;

    final db = await ref.read(appDatabaseProvider).database;
    await db.insert('build_fix_logs', {
      'command': command.text.trim(),
      'error_text': error.text.trim(),
      'fix_text': fix.text.trim(),
      'status': 'مفتوح',
      'created_at': DateTime.now().toIso8601String(),
    });

    ref.invalidate(buildFixLogsProvider);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('تسجيل خطأ بناء', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(controller: command, decoration: const InputDecoration(labelText: 'الأمر')),
            const SizedBox(height: 10),
            TextField(controller: error, maxLines: 4, decoration: const InputDecoration(labelText: 'نص الخطأ')),
            const SizedBox(height: 10),
            TextField(controller: fix, maxLines: 3, decoration: const InputDecoration(labelText: 'الحل')),
            const SizedBox(height: 14),
            FilledButton.icon(onPressed: save, icon: const Icon(Icons.save_rounded), label: const Text('حفظ')),
          ],
        ),
      ),
    );
  }
}