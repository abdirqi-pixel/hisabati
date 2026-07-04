import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';

class AboutAppScreen extends ConsumerWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final about = ref.watch(aboutAppProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('حول التطبيق')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF3B82F6)]),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 42,
                  child: Icon(Icons.account_balance_wallet_rounded, size: 42),
                ),
                const SizedBox(height: 16),
                Text(
                  about['name'].toString(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  about['description'].toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.verified_rounded),
                  title: const Text('الإصدار'),
                  subtitle:
                      Text('${about['version']} - Build ${about['build']}'),
                ),
                ListTile(
                  leading: const Icon(Icons.rocket_launch_rounded),
                  title: const Text('مرحلة الإصدار'),
                  subtitle: Text(about['stage'].toString()),
                ),
                const ListTile(
                  leading: Icon(Icons.language_rounded),
                  title: Text('اللغة'),
                  subtitle: Text('العربية'),
                ),
                const ListTile(
                  leading: Icon(Icons.lock_rounded),
                  title: Text('الخصوصية'),
                  subtitle: Text(
                      'البيانات تُحفظ محليًا داخل جهاز المستخدم افتراضيًا'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'حساباتي مصمم لمساعدة المستخدمين على تنظيم المصروفات والإيرادات والمشاريع والسلف والتقارير بواجهة عربية سهلة.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
