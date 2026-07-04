import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';

class DeveloperHandoffScreen extends ConsumerWidget {
  const DeveloperHandoffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(developerHandoffChecklistProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('تسليم المطور')),
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.engineering_rounded, color: Colors.white, size: 44),
                SizedBox(height: 12),
                Text(
                  'حزمة تسليم المطور',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'ملفات إرشادية تساعد المطور على فحص المشروع وبناء النسخة النهائية.',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ...items.map((item) {
            return Card(
              child: ListTile(
                leading: const Icon(Icons.task_alt_rounded, color: Colors.blue),
                title: Text(item['title'].toString()),
                subtitle: const Text('ينفذ على جهاز المطور'),
              ),
            );
          }),
          const SizedBox(height: 18),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'تمت إضافة مجلد developer_handoff وفيه شرح بنية المشروع وخريطة الميزات وحدود معروفة وأول قائمة إصلاحات.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
