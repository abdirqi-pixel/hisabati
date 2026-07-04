import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';
import '../../../core/services/performance_service.dart';

class PerformanceScreen extends ConsumerStatefulWidget {
  const PerformanceScreen({super.key});

  @override
  ConsumerState<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends ConsumerState<PerformanceScreen> {
  bool working = false;

  Future<void> optimize() async {
    setState(() => working = true);
    try {
      await PerformanceService(ref.read(appDatabaseProvider)).optimize();
      ref.invalidate(performanceInfoProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحسين قاعدة البيانات')),
        );
      }
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(performanceInfoProvider);
    final selectedUser = ref.watch(selectedUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الأداء والإصدار التجريبي')),
      body: selectedUser.when(
        data: (user) {
          final role = (user?['role'] ?? 'viewer').toString();
          if (!roleCanManageSettings(role)) {
            return const Center(child: Text('هذه الصفحة متاحة للمدير فقط'));
          }

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
                    Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 44),
                    SizedBox(height: 12),
                    Text(
                      'تحسين الأداء',
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'فهرسة وتحسينات لتجهيز التطبيق للإصدار التجريبي.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              info.when(
                data: (data) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('معلومات الأداء', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        _RowInfo('المصروفات', data['expenses']),
                        _RowInfo('الإيرادات', data['incomes']),
                        _RowInfo('السلف', data['advances']),
                        _RowInfo('المشاريع', data['projects']),
                        _RowInfo('الأشخاص', data['persons']),
                        _RowInfo('سجل النشاط', data['activityLog']),
                        _RowInfo('الإشعارات', data['notifications']),
                        _RowInfo('صفحات قاعدة البيانات', data['pageCount']),
                        _RowInfo('حجم الصفحة', data['pageSize']),
                      ],
                    ),
                  ),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('خطأ: $e'),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: working ? null : optimize,
                icon: const Icon(Icons.speed_rounded),
                label: const Text('تحسين قاعدة البيانات الآن'),
              ),
              const SizedBox(height: 18),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'تمت إضافة فهارس لتسريع البحث والتقارير، وتجهيز تحميل السجلات على دفعات للشاشات الكبيرة.',
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

class _RowInfo extends StatelessWidget {
  const _RowInfo(this.label, this.value);

  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text('${value ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}