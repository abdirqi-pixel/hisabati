import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';

class StabilizationScreen extends ConsumerWidget {
  const StabilizationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checklist = ref.watch(stabilizationChecklistProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('التثبيت النهائي')),
      body: checklist.when(
        data: (items) {
          final passed = items.where((e) => e['ok'] == true).length;
          final percent = items.isEmpty ? 0.0 : passed / items.length;

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF3B82F6)]),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.fact_check_rounded, color: Colors.white, size: 44),
                    const SizedBox(height: 12),
                    const Text(
                      'v1.0 Release Candidate',
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('نسبة اجتياز الفحوصات: ${(percent * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: percent, backgroundColor: Colors.white24, color: Colors.white),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text('فحوصات الاستقرار', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...items.map((item) {
                final ok = item['ok'] == true;
                return Card(
                  child: ListTile(
                    leading: Icon(ok ? Icons.check_circle_rounded : Icons.error_rounded, color: ok ? Colors.green : Colors.red),
                    title: Text(item['title'].toString()),
                    subtitle: Text(ok ? 'جاهز' : 'يحتاج مراجعة'),
                  ),
                );
              }),
              const SizedBox(height: 18),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'تمت إضافة ملفات STABILIZATION_PLAN_v1.0_RC.md و QA_TEST_CASES_v1.0.md داخل المشروع لمساعدة الاختبار قبل النشر.',
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