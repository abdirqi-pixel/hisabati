import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/data/database_providers.dart';
import '../../../core/services/backup_service.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool isWorking = false;
  String? lastMessage;

  Future<void> exportBackup() async {
    setState(() {
      isWorking = true;
      lastMessage = null;
    });

    try {
      final service = BackupService(ref.read(appDatabaseProvider));
      final file = await service.exportBackup();

      setState(() => lastMessage = 'تم إنشاء النسخة الاحتياطية:\n${file.path}');

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'نسخة احتياطية من تطبيق حساباتي',
      );
    } catch (e) {
      setState(() => lastMessage = 'حدث خطأ أثناء التصدير: $e');
    } finally {
      setState(() => isWorking = false);
    }
  }

  Future<void> restoreBackup() async {
    setState(() {
      isWorking = true;
      lastMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        setState(() {
          isWorking = false;
          lastMessage = 'لم يتم اختيار ملف';
        });
        return;
      }

      final file = File(result.files.single.path!);
      final service = BackupService(ref.read(appDatabaseProvider));
      await service.restoreBackup(file);

      ref.invalidate(settingsProvider);
      ref.invalidate(projectsProvider);
      ref.invalidate(personsProvider);
      ref.invalidate(categoriesProvider);
      ref.invalidate(expensesProvider);
      ref.invalidate(treasuryTransactionsProvider);
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(reportsSummaryProvider);
      ref.invalidate(appUsersProvider);
      ref.invalidate(selectedUserProvider);

      setState(() => lastMessage = 'تمت استعادة النسخة الاحتياطية بنجاح');
    } catch (e) {
      setState(() => lastMessage = 'حدث خطأ أثناء الاستعادة: $e');
    } finally {
      setState(() => isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedUser = ref.watch(selectedUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('النسخ الاحتياطي')),
      body: selectedUser.when(
        data: (user) {
          final role = (user?['role'] ?? 'viewer').toString();
          if (!roleCanManageSettings(role)) {
            return const Center(
              child: Text('هذه الصفحة متاحة للمدير فقط'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.backup_rounded, color: Colors.white, size: 42),
                    SizedBox(height: 12),
                    Text(
                      'احمِ بياناتك',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'أنشئ نسخة احتياطية من المشاريع والأشخاص والعمليات والصندوق والإعدادات.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.upload_file_rounded),
                  title: const Text('تصدير نسخة احتياطية'),
                  subtitle: const Text('إنشاء ملف JSON ومشاركته أو حفظه'),
                  trailing: const Icon(Icons.arrow_back_ios_new_rounded),
                  onTap: isWorking ? null : exportBackup,
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.restore_rounded),
                  title: const Text('استعادة نسخة احتياطية'),
                  subtitle:
                      const Text('اختيار ملف JSON سابق واستعادة البيانات'),
                  trailing: const Icon(Icons.arrow_back_ios_new_rounded),
                  onTap: isWorking ? null : restoreBackup,
                ),
              ),
              const SizedBox(height: 18),
              if (isWorking) const Center(child: CircularProgressIndicator()),
              if (lastMessage != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(lastMessage!),
                  ),
                ),
              const SizedBox(height: 18),
              const Text(
                'تنبيه: الاستعادة تستبدل البيانات الحالية بالبيانات الموجودة في ملف النسخة الاحتياطية.',
                style: TextStyle(color: Colors.red),
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
