import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';
import '../../../core/services/maintenance_service.dart';

class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
  bool working = false;

  Future<void> runAction(Future<String> Function() action) async {
    setState(() => working = true);
    try {
      final message = await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
      ref.invalidate(maintenanceStatsProvider);
      ref.invalidate(activityLogProvider);
      ref.invalidate(trashProvider);
      ref.invalidate(dashboardSummaryProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(maintenanceStatsProvider);
    final selectedUser = ref.watch(selectedUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('صيانة البيانات')),
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
                    Icon(Icons.speed_rounded, color: Colors.white, size: 44),
                    SizedBox(height: 12),
                    Text(
                      'تحسين الأداء',
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'أدوات لتنظيف البيانات القديمة وضغط قاعدة البيانات.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              stats.when(
                data: (data) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('إحصائيات قاعدة البيانات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        _StatLine('المشاريع النشطة', data['projects']),
                        _StatLine('المشاريع المؤرشفة', data['archivedProjects']),
                        _StatLine('الأشخاص', data['persons']),
                        _StatLine('المصروفات', data['expenses']),
                        _StatLine('الإيرادات', data['incomes']),
                        _StatLine('السلف', data['advances']),
                        _StatLine('حركات الصندوق', data['treasury']),
                        _StatLine('المرفقات', data['attachments']),
                        _StatLine('سجل النشاط', data['activityLog']),
                        _StatLine('عناصر محذوفة', ((data['deletedProjects'] as int? ?? 0) + (data['deletedPersons'] as int? ?? 0) + (data['deletedExpenses'] as int? ?? 0))),
                      ],
                    ),
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('خطأ: $e'),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.compress_rounded),
                  title: const Text('ضغط قاعدة البيانات'),
                  subtitle: const Text('تحسين حجم وأداء قاعدة البيانات'),
                  trailing: const Icon(Icons.arrow_back_ios_new_rounded),
                  onTap: working
                      ? null
                      : () => runAction(() async {
                            await MaintenanceService(ref.read(appDatabaseProvider)).vacuumDatabase();
                            return 'تم ضغط قاعدة البيانات';
                          }),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.cleaning_services_rounded),
                  title: const Text('تنظيف سجل النشاط القديم'),
                  subtitle: const Text('يبقي آخر 500 عملية في سجل النشاط'),
                  trailing: const Icon(Icons.arrow_back_ios_new_rounded),
                  onTap: working
                      ? null
                      : () => runAction(() async {
                            final count = await MaintenanceService(ref.read(appDatabaseProvider)).cleanOldActivityLogs();
                            return 'تم حذف $count سجل قديم';
                          }),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.delete_forever_rounded),
                  title: const Text('تفريغ سلة المحذوفات'),
                  subtitle: const Text('حذف نهائي للعناصر الموجودة في السلة'),
                  trailing: const Icon(Icons.arrow_back_ios_new_rounded),
                  onTap: working
                      ? null
                      : () => runAction(() async {
                            final count = await MaintenanceService(ref.read(appDatabaseProvider)).emptyTrash();
                            return 'تم حذف $count عنصر نهائيًا';
                          }),
                ),
              ),
              if (working)
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Center(child: CircularProgressIndicator()),
                ),
              const SizedBox(height: 14),
              const Text(
                'مهم: يفضل إنشاء نسخة احتياطية قبل تفريغ سلة المحذوفات.',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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

class _StatLine extends StatelessWidget {
  const _StatLine(this.label, this.value);

  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            '${value ?? 0}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}