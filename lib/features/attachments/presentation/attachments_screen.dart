import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/data/database_providers.dart';

class AttachmentsScreen extends ConsumerWidget {
  const AttachmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachments = ref.watch(allAttachmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('المرفقات')),
      body: attachments.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('لا توجد مرفقات بعد'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              final path = item['file_path'].toString();
              final type = item['type'].toString();
              final file = File(path);
              final exists = file.existsSync();

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(type == 'image'
                        ? Icons.image_rounded
                        : type == 'pdf'
                            ? Icons.picture_as_pdf_rounded
                            : Icons.attach_file_rounded),
                  ),
                  title: Text(type == 'image' ? 'صورة فاتورة' : type == 'pdf' ? 'ملف PDF' : 'مرفق'),
                  subtitle: Text(
                    'عملية: ${item['expense_serial'] ?? 'غير معروف'} • ${item['expense_amount'] ?? ''} ${item['currency_symbol'] ?? ''}\n'
                    '${exists ? path : 'الملف غير موجود في الجهاز'}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'open' && exists) {
                        await OpenFilex.open(path);
                      }
                      if (value == 'share' && exists) {
                        await Share.shareXFiles([XFile(path)], text: 'مرفق من تطبيق حساباتي');
                      }
                      if (value == 'delete') {
                        final db = await ref.read(appDatabaseProvider).database;
                        await db.delete('expense_attachments', where: 'id = ?', whereArgs: [item['id']]);
                        ref.invalidate(allAttachmentsProvider);
                        ref.invalidate(expenseAttachmentsProvider(item['expense_id'] as int));
                        ref.invalidate(expensesProvider);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'open', child: Text('فتح')),
                      const PopupMenuItem(value: 'share', child: Text('مشاركة')),
                      const PopupMenuItem(value: 'delete', child: Text('حذف المرفق')),
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