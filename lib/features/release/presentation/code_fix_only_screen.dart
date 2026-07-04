import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';

class CodeFixOnlyScreen extends ConsumerWidget {
  const CodeFixOnlyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(modifiedFileLogsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('إصلاح الكود فقط')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const _ModifiedFileForm(),
        ),
        icon: const Icon(Icons.edit_document),
        label: const Text('ملف معدل'),
      ),
      body: logs.when(
        data: (items) {
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF3B82F6)]),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.construction_rounded, color: Colors.white, size: 44),
                    SizedBox(height: 12),
                    Text(
                      'مرحلة إصلاح الكود فقط',
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'لا ميزات جديدة قبل نجاح البناء. سجل كل ملف يتم تعديله أثناء الإصلاح.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (items.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('لا توجد ملفات معدلة مسجلة بعد'),
                  ),
                )
              else
                ...items.map((item) {
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.description_rounded, color: Colors.blue),
                      title: Text(item['file_path'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('السبب: ${item['reason'] ?? ''}\nالحالة: ${item['status']}'),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          final db = await ref.read(appDatabaseProvider).database;
                          await db.update(
                            'modified_file_logs',
                            {'status': value},
                            where: 'id = ?',
                            whereArgs: [item['id']],
                          );
                          ref.invalidate(modifiedFileLogsProvider);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'مفتوح', child: Text('مفتوح')),
                          PopupMenuItem(value: 'تم', child: Text('تم')),
                          PopupMenuItem(value: 'يحتاج مراجعة', child: Text('يحتاج مراجعة')),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 18),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'تمت إضافة مجلد code_fix_only وفيه خطة إصلاح الكود فقط وسجل الملفات المعدلة وقاعدة عدم إضافة ميزات جديدة.',
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
      ),
    );
  }
}

class _ModifiedFileForm extends ConsumerStatefulWidget {
  const _ModifiedFileForm();

  @override
  ConsumerState<_ModifiedFileForm> createState() => _ModifiedFileFormState();
}

class _ModifiedFileFormState extends ConsumerState<_ModifiedFileForm> {
  final filePath = TextEditingController();
  final reason = TextEditingController();

  @override
  void dispose() {
    filePath.dispose();
    reason.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (filePath.text.trim().isEmpty) return;

    final db = await ref.read(appDatabaseProvider).database;
    await db.insert('modified_file_logs', {
      'file_path': filePath.text.trim(),
      'reason': reason.text.trim(),
      'status': 'مفتوح',
      'created_at': DateTime.now().toIso8601String(),
    });

    ref.invalidate(modifiedFileLogsProvider);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('تسجيل ملف معدل', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(controller: filePath, decoration: const InputDecoration(labelText: 'مسار الملف')),
          const SizedBox(height: 10),
          TextField(controller: reason, maxLines: 3, decoration: const InputDecoration(labelText: 'سبب التعديل')),
          const SizedBox(height: 14),
          FilledButton.icon(onPressed: save, icon: const Icon(Icons.save_rounded), label: const Text('حفظ')),
        ],
      ),
    );
  }
}