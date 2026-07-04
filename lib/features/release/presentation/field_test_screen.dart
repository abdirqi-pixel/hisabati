import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';

class FieldTestScreen extends ConsumerWidget {
  const FieldTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(fieldTestChecklistProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الاختبار الميداني')),
      body: ListView(
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
                Icon(Icons.groups_rounded, color: Colors.white, size: 44),
                SizedBox(height: 12),
                Text(
                  'اختبار المستخدمين',
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'قائمة مهام لاختبار التطبيق مع مستخدمين حقيقيين قبل النشر.',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ...items.map((item) {
            final high = item['priority'] == 'عالي';
            return Card(
              child: ListTile(
                leading: Icon(high ? Icons.priority_high_rounded : Icons.checklist_rounded, color: high ? Colors.red : Colors.blue),
                title: Text(item['title'].toString()),
                subtitle: Text('الأولوية: ${item['priority']}'),
              ),
            );
          }),
          const SizedBox(height: 18),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'تمت إضافة ملفات FIELD_TEST_PLAN_AR و BUG_REPORT_TEMPLATE_AR و TESTER_FEEDBACK_FORM_AR داخل مجلد field_testing.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}