import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';

class TesterFeedbackScreen extends ConsumerWidget {
  const TesterFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedback = ref.watch(testerFeedbackProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ملاحظات المختبرين')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const _FeedbackForm(),
        ),
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('ملاحظة'),
      ),
      body: feedback.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('لا توجد ملاحظات بعد'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              final priority = item['priority'].toString();

              return Card(
                child: ListTile(
                  leading: Icon(
                    priority == 'حرجة'
                        ? Icons.error_rounded
                        : priority == 'عالية'
                            ? Icons.priority_high_rounded
                            : Icons.feedback_rounded,
                    color: priority == 'حرجة'
                        ? Colors.red
                        : priority == 'عالية'
                            ? Colors.orange
                            : Colors.blue,
                  ),
                  title: Text(item['issue'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'الشاشة: ${item['screen_name'] ?? 'غير محدد'}\n'
                    'الأولوية: ${item['priority']} • الحالة: ${item['status']}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      final db = await ref.read(appDatabaseProvider).database;
                      await db.update(
                        'tester_feedback',
                        {'status': value},
                        where: 'id = ?',
                        whereArgs: [item['id']],
                      );
                      ref.invalidate(testerFeedbackProvider);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'جديد', child: Text('جديد')),
                      PopupMenuItem(value: 'قيد المراجعة', child: Text('قيد المراجعة')),
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

class _FeedbackForm extends ConsumerStatefulWidget {
  const _FeedbackForm();

  @override
  ConsumerState<_FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends ConsumerState<_FeedbackForm> {
  final testerName = TextEditingController();
  final screenName = TextEditingController();
  final issue = TextEditingController();
  final notes = TextEditingController();
  String priority = 'متوسطة';

  @override
  void dispose() {
    testerName.dispose();
    screenName.dispose();
    issue.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (issue.text.trim().isEmpty) return;

    final db = await ref.read(appDatabaseProvider).database;
    await db.insert('tester_feedback', {
      'tester_name': testerName.text.trim(),
      'screen_name': screenName.text.trim(),
      'issue': issue.text.trim(),
      'priority': priority,
      'status': 'جديد',
      'notes': notes.text.trim(),
      'created_at': DateTime.now().toIso8601String(),
    });

    ref.invalidate(testerFeedbackProvider);
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
            const Text('إضافة ملاحظة اختبار', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(controller: testerName, decoration: const InputDecoration(labelText: 'اسم المختبر')),
            const SizedBox(height: 10),
            TextField(controller: screenName, decoration: const InputDecoration(labelText: 'اسم الشاشة')),
            const SizedBox(height: 10),
            TextField(controller: issue, maxLines: 3, decoration: const InputDecoration(labelText: 'وصف المشكلة')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: priority,
              decoration: const InputDecoration(labelText: 'الأولوية'),
              items: const [
                DropdownMenuItem(value: 'حرجة', child: Text('حرجة')),
                DropdownMenuItem(value: 'عالية', child: Text('عالية')),
                DropdownMenuItem(value: 'متوسطة', child: Text('متوسطة')),
                DropdownMenuItem(value: 'منخفضة', child: Text('منخفضة')),
              ],
              onChanged: (value) => setState(() => priority = value ?? 'متوسطة'),
            ),
            const SizedBox(height: 10),
            TextField(controller: notes, maxLines: 2, decoration: const InputDecoration(labelText: 'ملاحظات إضافية')),
            const SizedBox(height: 14),
            FilledButton.icon(onPressed: save, icon: const Icon(Icons.save_rounded), label: const Text('حفظ')),
          ],
        ),
      ),
    );
  }
}