import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';
import '../../../core/services/cloud_sync_service.dart';

class CloudSyncScreen extends ConsumerStatefulWidget {
  const CloudSyncScreen({super.key});

  @override
  ConsumerState<CloudSyncScreen> createState() => _CloudSyncScreenState();
}

class _CloudSyncScreenState extends ConsumerState<CloudSyncScreen> {
  final password = TextEditingController();
  bool working = false;

  @override
  void dispose() {
    password.dispose();
    super.dispose();
  }

  void message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> chooseFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null) return;

    await CloudSyncService(ref.read(appDatabaseProvider)).updateSettings(
      isEnabled: true,
      provider: 'local_folder',
      folderPath: path,
    );

    ref.invalidate(cloudSyncSettingsProvider);
    ref.invalidate(availableCloudBackupsProvider);
    message('تم اختيار مجلد المزامنة');
  }

  Future<void> uploadBackup() async {
    if (password.text.length < 6) {
      message('اكتب كلمة مرور 6 أحرف أو أكثر');
      return;
    }

    setState(() => working = true);
    try {
      final file = await CloudSyncService(ref.read(appDatabaseProvider))
          .uploadBackupToSyncFolder(
        password: password.text,
      );

      ref.invalidate(cloudSyncSettingsProvider);
      ref.invalidate(cloudBackupHistoryProvider);
      ref.invalidate(availableCloudBackupsProvider);
      message('تم رفع النسخة: ${file.path}');
    } catch (e) {
      message('فشل الرفع: $e');
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> restoreBackup(File file) async {
    if (password.text.length < 6) {
      message('اكتب كلمة مرور النسخة');
      return;
    }

    setState(() => working = true);
    try {
      await CloudSyncService(ref.read(appDatabaseProvider)).restoreFromBackup(
        file: file,
        password: password.text,
      );

      ref.invalidate(cloudSyncSettingsProvider);
      ref.invalidate(cloudBackupHistoryProvider);
      ref.invalidate(projectsProvider);
      ref.invalidate(expensesProvider);
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(appNotificationsProvider);
      message('تمت الاستعادة بنجاح');
    } catch (e) {
      message('فشل الاستعادة: $e');
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(cloudSyncSettingsProvider);
    final backups = ref.watch(availableCloudBackupsProvider);
    final history = ref.watch(cloudBackupHistoryProvider);
    final selectedUser = ref.watch(selectedUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('المزامنة السحابية')),
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
                  gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF3B82F6)]),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.cloud_sync_rounded,
                        color: Colors.white, size: 44),
                    SizedBox(height: 12),
                    Text(
                      'مزامنة اختيارية',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'اختر مجلد Google Drive أو iCloud Drive أو أي مجلد متزامن على جهازك.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              settings.when(
                data: (s) {
                  final enabled = s?['is_enabled'] == 1;
                  final auto = s?['auto_sync_enabled'] == 1;

                  return Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('تفعيل المزامنة'),
                          subtitle: Text(s?['folder_path']?.toString() ??
                              'لم يتم اختيار مجلد'),
                          value: enabled,
                          onChanged: (value) async {
                            await CloudSyncService(
                                    ref.read(appDatabaseProvider))
                                .updateSettings(isEnabled: value);
                            ref.invalidate(cloudSyncSettingsProvider);
                          },
                        ),
                        SwitchListTile(
                          title: const Text('مزامنة تلقائية'),
                          subtitle: const Text(
                              'سيتم استخدامها لاحقًا عند إغلاق التطبيق أو يوميًا'),
                          value: auto,
                          onChanged: enabled
                              ? (value) async {
                                  await CloudSyncService(
                                          ref.read(appDatabaseProvider))
                                      .updateSettings(autoSyncEnabled: value);
                                  ref.invalidate(cloudSyncSettingsProvider);
                                }
                              : null,
                        ),
                        ListTile(
                          leading: const Icon(Icons.folder_rounded),
                          title: const Text('اختيار مجلد المزامنة'),
                          subtitle: Text(s?['last_sync_at'] == null
                              ? 'لا توجد مزامنة سابقة'
                              : 'آخر مزامنة: ${s?['last_sync_at']}'),
                          trailing:
                              const Icon(Icons.arrow_back_ios_new_rounded),
                          onTap: chooseFolder,
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('خطأ: $e'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة مرور النسخة',
                  prefixIcon: Icon(Icons.password_rounded),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: working ? null : uploadBackup,
                icon: const Icon(Icons.cloud_upload_rounded),
                label: const Text('رفع نسخة مشفرة الآن'),
              ),
              const SizedBox(height: 18),
              const Text('النسخ المتوفرة في مجلد المزامنة',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              backups.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text('لا توجد نسخ في مجلد المزامنة'),
                      ),
                    );
                  }

                  return Column(
                    children: items.map((entity) {
                      final file = File(entity.path);
                      final stat = file.statSync();

                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.backup_rounded),
                          title: Text(
                              entity.path.split(Platform.pathSeparator).last),
                          subtitle: Text(
                              'الحجم: ${stat.size} بايت\\nآخر تعديل: ${stat.modified}'),
                          isThreeLine: true,
                          trailing: TextButton(
                            onPressed:
                                working ? null : () => restoreBackup(file),
                            child: const Text('استعادة'),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('خطأ: $e'),
              ),
              const SizedBox(height: 18),
              const Text('سجل المزامنة',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              history.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text('لا يوجد سجل مزامنة بعد'),
                      ),
                    );
                  }

                  return Column(
                    children: items.take(10).map((h) {
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.history_rounded),
                          title: Text(h['status'].toString()),
                          subtitle: Text(
                              '${h['message'] ?? ''}\\n${h['created_at']}'),
                          isThreeLine: true,
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('خطأ: $e'),
              ),
              if (working)
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Center(child: CircularProgressIndicator()),
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
