import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';

class FeatureFreezeScreen extends ConsumerWidget {
  const FeatureFreezeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(featureFreezeProvider);
    final allowed = (data['allowed'] as List).cast<String>();
    final notAllowed = (data['notAllowed'] as List).cast<String>();

    return Scaffold(
      appBar: AppBar(title: const Text('تجميد الميزات')),
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
                const Icon(Icons.lock_clock_rounded,
                    color: Colors.white, size: 44),
                const SizedBox(height: 12),
                Text(
                  'تجميد الميزات ${data['version']}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(data['message'].toString(),
                    style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('المسموح الآن',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ...allowed.map((e) => Card(
              child: ListTile(
                  leading: const Icon(Icons.check_circle_rounded,
                      color: Colors.green),
                  title: Text(e)))),
          const SizedBox(height: 12),
          const Text('مؤجل لما بعد الإطلاق',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ...notAllowed.map((e) => Card(
              child: ListTile(
                  leading: const Icon(Icons.pause_circle_rounded,
                      color: Colors.orange),
                  title: Text(e)))),
        ],
      ),
    );
  }
}
