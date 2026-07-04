import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';

class FlutterChecksScreen extends ConsumerWidget {
  const FlutterChecksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checks = ref.watch(flutterCommandChecksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('فحص أوامر Flutter')),
      body: checks.when(
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
                    Icon(Icons.terminal_rounded, color: Colors.white, size: 44),
                    SizedBox(height: 12),
                    Text(
                      'فحص البناء والتشغيل',
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'تابع نتائج أوامر Flutter الأساسية قبل النشر.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ...items.map((item) {
                final status = item['status'].toString();
                final ok = status == 'نجح';
                return Card(
                  child: ListTile(
                    leading: Icon(ok ? Icons.check_circle_rounded : Icons.terminal_rounded, color: ok ? Colors.green : Colors.blue),
                    title: Text(item['command'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('الحالة: $status\n${item['notes'] ?? ''}'),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        final db = await ref.read(appDatabaseProvider).database;
                        await db.update(
                          'flutter_command_checks',
                          {
                            'status': value,
                            'checked_at': DateTime.now().toIso8601String(),
                          },
                          where: 'id = ?',
                          whereArgs: [item['id']],
                        );
                        ref.invalidate(flutterCommandChecksProvider);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'لم يتم', child: Text('لم يتم')),
                        PopupMenuItem(value: 'نجح', child: Text('نجح')),
                        PopupMenuItem(value: 'فشل', child: Text('فشل')),
                        PopupMenuItem(value: 'يحتاج إصلاح', child: Text('يحتاج إصلاح')),
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
                    'تمت إضافة مجلد flutter_checks وفيه قائمة أوامر Flutter وملف لتسجيل النتائج يدويًا.',
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