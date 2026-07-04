import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';

class StoreReadinessScreen extends ConsumerWidget {
  const StoreReadinessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(storeReadinessProvider);
    final passed = items.where((e) => e['ok'] == true).length;
    final percent = items.isEmpty ? 0.0 : passed / items.length;

    return Scaffold(
      appBar: AppBar(title: const Text('جاهزية المتجر')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF3B82F6)]),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.store_rounded, color: Colors.white, size: 44),
                const SizedBox(height: 12),
                const Text(
                  'جاهزية النشر في المتجر',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('الجاهزية: ${(percent * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                    value: percent,
                    color: Colors.white,
                    backgroundColor: Colors.white24),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ...items.map((item) {
            final ok = item['ok'] == true;
            return Card(
              child: ListTile(
                leading: Icon(
                    ok ? Icons.check_circle_rounded : Icons.pending_rounded,
                    color: ok ? Colors.green : Colors.orange),
                title: Text(item['title'].toString()),
                subtitle: Text(ok ? 'جاهز' : 'يحتاج تجهيز قبل النشر'),
              ),
            );
          }),
          const SizedBox(height: 18),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'تمت إضافة ملفات وصف المتجر وسياسة الخصوصية وقائمة مواد النشر داخل المشروع.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
