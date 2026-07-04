import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/database_providers.dart';
import '../application/security_controller.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends ConsumerState<SecuritySettingsScreen> {
  final pin = TextEditingController();
  final confirmPin = TextEditingController();

  @override
  void dispose() {
    pin.dispose();
    confirmPin.dispose();
    super.dispose();
  }

  Future<void> savePin() async {
    final value = pin.text.trim();
    final confirm = confirmPin.text.trim();

    if (value.length < 4 || value.length > 6) {
      showMessage('يجب أن يكون الرمز من 4 إلى 6 أرقام');
      return;
    }

    if (value != confirm) {
      showMessage('الرمزان غير متطابقين');
      return;
    }

    await ref.read(securityActionsProvider).setPin(value);
    pin.clear();
    confirmPin.clear();
    showMessage('تم تفعيل رمز PIN');
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الأمان')),
      body: settings.when(
        data: (s) {
          final pinEnabled = s?['is_pin_enabled'] == 1;
          final biometricEnabled = s?['biometric_enabled'] == 1;
          final autoLockEnabled = s?['auto_lock_enabled'] == 1;
          final autoLockMinutes = (s?['auto_lock_minutes'] as int?) ?? 5;

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF3B82F6)]),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.security_rounded, color: Colors.white, size: 42),
                    const SizedBox(height: 12),
                    const Text(
                      'حماية التطبيق',
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pinEnabled ? 'رمز PIN مفعّل' : 'رمز PIN غير مفعّل',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: pin,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'رمز PIN الجديد',
                  prefixIcon: Icon(Icons.pin_rounded),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmPin,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'تأكيد رمز PIN',
                  prefixIcon: Icon(Icons.lock_rounded),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: savePin,
                icon: const Icon(Icons.save_rounded),
                label: const Text('حفظ وتفعيل PIN'),
              ),
              const SizedBox(height: 10),
              if (pinEnabled)
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(securityActionsProvider).disablePin();
                    showMessage('تم إيقاف رمز PIN');
                  },
                  icon: const Icon(Icons.lock_open_rounded),
                  label: const Text('إيقاف رمز PIN'),
                ),
              const SizedBox(height: 18),
              Card(
                child: SwitchListTile(
                  secondary: const Icon(Icons.fingerprint_rounded),
                  title: const Text('فتح بالبصمة أو Face ID'),
                  subtitle: const Text('يتطلب أن يكون الجهاز يدعم المصادقة الحيوية'),
                  value: biometricEnabled,
                  onChanged: pinEnabled
                      ? (value) async {
                          final canUse = await ref.read(securityActionsProvider).canUseBiometrics();
                          if (!canUse && mounted) {
                            showMessage('الجهاز لا يدعم البصمة أو Face ID أو لم يتم تفعيلها');
                            return;
                          }

                          await ref.read(securityActionsProvider).setBiometricEnabled(value);
                          showMessage(value ? 'تم تفعيل المصادقة الحيوية' : 'تم إيقاف المصادقة الحيوية');
                        }
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: SwitchListTile(
                  secondary: const Icon(Icons.timer_rounded),
                  title: const Text('القفل التلقائي'),
                  subtitle: Text('بعد $autoLockMinutes دقيقة من الخمول'),
                  value: autoLockEnabled,
                  onChanged: pinEnabled
                      ? (value) => ref.read(securityActionsProvider).updateAutoLock(
                            enabled: value,
                            minutes: autoLockMinutes,
                          )
                      : null,
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.schedule_rounded),
                  title: const Text('مدة القفل التلقائي'),
                  subtitle: Text('$autoLockMinutes دقيقة'),
                  trailing: const Icon(Icons.arrow_back_ios_new_rounded),
                  onTap: pinEnabled
                      ? () async {
                          final selected = await showModalBottomSheet<int>(
                            context: context,
                            builder: (context) => SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [1, 5, 10, 15, 30].map((m) {
                                  return ListTile(
                                    title: Text('$m دقيقة'),
                                    onTap: () => Navigator.pop(context, m),
                                  );
                                }).toList(),
                              ),
                            ),
                          );

                          if (selected != null) {
                            await ref.read(securityActionsProvider).updateAutoLock(
                                  enabled: autoLockEnabled,
                                  minutes: selected,
                                );
                          }
                        }
                      : null,
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.lock_rounded),
                  title: const Text('قفل التطبيق الآن'),
                  subtitle: const Text('العودة إلى شاشة القفل'),
                  trailing: const Icon(Icons.arrow_back_ios_new_rounded),
                  onTap: pinEnabled
                      ? () async {
                          await ref.read(securityActionsProvider).lockNow();
                          if (context.mounted) context.go('/lock');
                        }
                      : null,
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.history_rounded),
                  title: const Text('سجل الأمان'),
                  subtitle: const Text('عرض أحداث القفل والحماية'),
                  trailing: const Icon(Icons.arrow_back_ios_new_rounded),
                  onTap: () => context.go('/security-log'),
                ),
              ),
              const SizedBox(height: 12),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'نصيحة: فعّل رمز PIN أولاً، ثم فعّل البصمة أو Face ID من هذه الصفحة.',
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