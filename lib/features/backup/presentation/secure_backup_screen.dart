import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/data/database_providers.dart';
import '../../../core/services/secure_backup_service.dart';

class SecureBackupScreen extends ConsumerStatefulWidget {
  const SecureBackupScreen({super.key});

  @override
  ConsumerState<SecureBackupScreen> createState() => _SecureBackupScreenState();
}

class _SecureBackupScreenState extends ConsumerState<SecureBackupScreen> {
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  bool working = false;

  @override
  void dispose() {
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  void message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> exportSecure() async {
    if (password.text.length < 6) {
      message('كلمة المرور يجب أن تكون 6 أحرف أو أكثر');
      return;
    }

    if (password.text != confirmPassword.text) {
      message('كلمتا المرور غير متطابقتين');
      return;
    }

    setState(() => working = true);

    try {
      final file = await SecureBackupService(ref.read(appDatabaseProvider))
          .exportEncryptedBackup(password.text);
      await Share.shareXFiles([XFile(file.path)],
          text: 'نسخة احتياطية مشفرة من حساباتي');
      message('تم إنشاء النسخة المشفرة');
    } catch (e) {
      message('حدث خطأ: $e');
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> restoreSecure() async {
    if (password.text.length < 6) {
      message('اكتب كلمة مرور النسخة المشفرة');
      return;
    }

    setState(() => working = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['hbak', 'json'],
      );

      if (result == null || result.files.single.path == null) {
        message('لم يتم اختيار ملف');
        return;
      }

      await SecureBackupService(ref.read(appDatabaseProvider))
          .restoreEncryptedBackup(
        encryptedFile: File(result.files.single.path!),
        password: password.text,
      );

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
      ref.invalidate(appNotificationsProvider);
      ref.invalidate(unreadNotificationsCountProvider);

      message('تمت استعادة النسخة المشفرة بنجاح');
    } catch (e) {
      message('فشل الاستعادة: $e');
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedUser = ref.watch(selectedUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('نسخة احتياطية مشفرة')),
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
                    Icon(Icons.enhanced_encryption_rounded,
                        color: Colors.white, size: 44),
                    SizedBox(height: 12),
                    Text(
                      'حماية النسخة الاحتياطية',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'صدّر نسخة احتياطية بكلمة مرور لحماية بياناتك.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  prefixIcon: Icon(Icons.password_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'تأكيد كلمة المرور للتصدير فقط',
                  prefixIcon: Icon(Icons.lock_rounded),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: working ? null : exportSecure,
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('تصدير نسخة مشفرة'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: working ? null : restoreSecure,
                icon: const Icon(Icons.restore_rounded),
                label: const Text('استعادة نسخة مشفرة'),
              ),
              if (working)
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Center(child: CircularProgressIndicator()),
                ),
              const SizedBox(height: 18),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'مهم: إذا نسيت كلمة المرور فلن يمكن استعادة النسخة المشفرة. احتفظ بها في مكان آمن.',
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
