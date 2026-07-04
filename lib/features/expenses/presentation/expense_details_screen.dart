import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';
import '../../../core/services/attachment_service.dart';

class ExpenseDetailsScreen extends ConsumerWidget {
  const ExpenseDetailsScreen({
    super.key,
    required this.expenseId,
  });

  final int expenseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachments = ref.watch(expenseAttachmentsProvider(expenseId));

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل العملية')),
      body: FutureBuilder<List<Map<String, Object?>>>(
        future: ref.read(appDatabaseProvider).database.then((db) {
          return db.rawQuery('''
            SELECT 
              expenses.*,
              persons.name AS person_name,
              categories.name AS category_name
            FROM expenses
            LEFT JOIN persons ON persons.id = expenses.person_id
            LEFT JOIN categories ON categories.id = expenses.category_id
            WHERE expenses.id = ?
            LIMIT 1
          ''', [expenseId]);
        }),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.isEmpty) {
            return const Center(child: Text('العملية غير موجودة'));
          }

          final e = snapshot.data!.first;

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e['serial_number'].toString(),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${e['amount']} ${e['currency_symbol']}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e['description']?.toString().isEmpty ?? true
                          ? 'بدون تفاصيل'
                          : e['description'].toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _InfoTile(
                  title: 'الشخص',
                  value: e['person_name']?.toString() ?? 'بدون شخص'),
              _InfoTile(
                  title: 'التصنيف',
                  value: e['category_name']?.toString() ?? 'بدون تصنيف'),
              _InfoTile(title: 'التاريخ', value: e['expense_date'].toString()),
              _InfoTile(title: 'الوقت', value: e['expense_time'].toString()),
              _InfoTile(
                  title: 'ملاحظات',
                  value: e['notes']?.toString().isEmpty ?? true
                      ? 'لا توجد'
                      : e['notes'].toString()),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(
                    child: Text('المرفقات',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        _showAddAttachmentSheet(context, ref, expenseId),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('إضافة مرفق'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              attachments.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text('لا توجد مرفقات'),
                      ),
                    );
                  }

                  return Column(
                    children: items.map((a) {
                      final type = a['type'].toString();
                      final path = a['file_path'].toString();

                      return Card(
                        child: ListTile(
                          leading: Icon(type == 'image'
                              ? Icons.image_rounded
                              : Icons.picture_as_pdf_rounded),
                          title:
                              Text(type == 'image' ? 'صورة فاتورة' : 'ملف PDF'),
                          subtitle: Text(path),
                          trailing: type == 'image' && File(path).existsSync()
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(File(path),
                                      width: 52, height: 52, fit: BoxFit.cover),
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('خطأ: $e'),
              ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _showAddAttachmentSheet(
    BuildContext context, WidgetRef ref, int expenseId) async {
  Future<void> addAttachment(
      String type, Future<File?> Function() pickFile) async {
    final file = await pickFile();
    if (file == null) return;

    final db = await ref.read(appDatabaseProvider).database;
    await db.insert('expense_attachments', {
      'expense_id': expenseId,
      'type': type,
      'file_path': file.path,
      'created_at': DateTime.now().toIso8601String(),
    });

    ref.invalidate(expenseAttachmentsProvider(expenseId));
    ref.invalidate(expensesProvider);
    ref.invalidate(filteredExpensesProvider);

    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إضافة المرفق')),
      );
    }
  }

  await showModalBottomSheet<void>(
    context: context,
    builder: (_) {
      final service = AttachmentService();

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('تصوير فاتورة'),
              onTap: () => addAttachment('image', service.captureInvoiceImage),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('اختيار صورة'),
              onTap: () =>
                  addAttachment('image', service.pickInvoiceImageFromGallery),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_rounded),
              title: const Text('إرفاق PDF'),
              onTap: () => addAttachment('pdf', service.pickPdfFile),
            ),
          ],
        ),
      );
    },
  );
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      ),
    );
  }
}
