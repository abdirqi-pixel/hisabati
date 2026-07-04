import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';

class BuildReadinessScreen extends ConsumerWidget {
  const BuildReadinessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readiness = ref.watch(buildReadinessProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('تجهيز البناء والنشر')),
      body: readiness.when(
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
                    const Icon(Icons.android_rounded, color: Colors.white, size: 44),
                    const SizedBox(height: 12),
                    const Text(
                      'تجهيز APK و AAB',
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('جاهزية البناء: ${(percent * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: percent, color: Colors.white, backgroundColor: Colors.white24),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text('قائمة البناء', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...items.map((item) {
                final ok = item['ok'] == true;
                return Card(
                  child: ListTile(
                    leading: Icon(ok ? Icons.check_circle_rounded : Icons.pending_rounded, color: ok ? Colors.green : Colors.orange),
                    title: Text(item['title'].toString()),
                    subtitle: Text(item['note'].toString()),
                  ),
                );
              }),
              const SizedBox(height: 18),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'تمت إضافة ANDROID_RELEASE_GUIDE.md و IOS_RELEASE_GUIDE.md وسكربتات البناء داخل مجلد scripts.',
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