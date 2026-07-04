import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';

class FinalLaunchScreen extends ConsumerWidget {
  const FinalLaunchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(finalLaunchChecklistProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الإطلاق النهائي')),
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
                Icon(Icons.flag_circle_rounded, color: Colors.white, size: 44),
                SizedBox(height: 12),
                Text(
                  'حساباتي v1.0 Final',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'قائمة الإطلاق النهائي قبل النشر في المتاجر.',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ...items.map((item) {
            return Card(
              child: ListTile(
                leading: const Icon(Icons.pending_actions_rounded,
                    color: Colors.orange),
                title: Text(item['title'].toString()),
                subtitle: const Text('ينفذ على جهاز المطور قبل النشر'),
              ),
            );
          }),
          const SizedBox(height: 18),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'تمت إضافة FINAL_RELEASE_HANDOFF_AR.md و RELEASE_NOTES_v1.0_FINAL.md داخل المشروع.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
