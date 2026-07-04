import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';

class ReleaseReadinessScreen extends ConsumerWidget {
  const ReleaseReadinessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readiness = ref.watch(releaseReadinessProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('جاهزية الإصدار')),
      body: readiness.when(
        data: (data) {
          final checks = (data['checks'] as List).cast<Map<String, Object?>>();
          final percent = ((data['readyPercent'] as num?) ?? 0).toDouble();

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
                    const Icon(Icons.verified_rounded, color: Colors.white, size: 44),
                    const SizedBox(height: 12),
                    Text(
                      'حساباتي ${data['version']}',
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Build ${data['build']}', style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(value: percent, backgroundColor: Colors.white24, color: Colors.white),
                    const SizedBox(height: 8),
                    Text(
                      'جاهزية: ${(percent * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text('فحص الجاهزية', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...checks.map((check) {
                final ok = check['ok'] == true;
                return Card(
                  child: ListTile(
                    leading: Icon(ok ? Icons.check_circle_rounded : Icons.error_rounded, color: ok ? Colors.green : Colors.red),
                    title: Text(check['title'].toString()),
                    subtitle: Text(ok ? 'جاهز' : 'يحتاج مراجعة'),
                  ),
                );
              }),
              const SizedBox(height: 18),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'هذه الشاشة تساعد على فحص جاهزية النسخة التجريبية. قبل النشر يجب اختبار التطبيق على أجهزة حقيقية وتحديث الأيقونة وسياسة الخصوصية.',
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