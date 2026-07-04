import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/security_log_service.dart';

final appUnlockedProvider = StateProvider<bool>((ref) => false);

final securityActionsProvider = Provider<SecurityActions>((ref) {
  return SecurityActions(ref);
});

class SecurityActions {
  SecurityActions(this.ref);

  final Ref ref;

  Future<bool> isPinEnabled() async {
    final settings = await ref.read(settingsProvider.future);
    return settings?['is_pin_enabled'] == 1;
  }

  Future<bool> shouldLockOnStart() async {
    final settings = await ref.read(settingsProvider.future);
    return settings?['lock_on_start'] == 1 && settings?['is_pin_enabled'] == 1;
  }

  Future<void> setPin(String pin) async {
    final db = await ref.read(appDatabaseProvider).database;
    await db.update(
      'app_settings',
      {
        'pin_code': pin,
        'is_pin_enabled': 1,
        'lock_on_start': 1,
      },
      where: 'id = ?',
      whereArgs: [1],
    );

    ref.invalidate(settingsProvider);
  }

  Future<void> disablePin() async {
    final db = await ref.read(appDatabaseProvider).database;
    await db.update(
      'app_settings',
      {
        'pin_code': null,
        'is_pin_enabled': 0,
        'lock_on_start': 0,
      },
      where: 'id = ?',
      whereArgs: [1],
    );

    ref.read(appUnlockedProvider.notifier).state = true;
    ref.invalidate(settingsProvider);
  }

  Future<bool> verifyPin(String pin) async {
    final settings = await ref.read(settingsProvider.future);
    final storedPin = settings?['pin_code']?.toString();

    final ok = storedPin != null && storedPin == pin;
    if (ok) {
      ref.read(appUnlockedProvider.notifier).state = true;
    }
    return ok;
  }

  Future<bool> authenticateWithBiometrics() async {
    final settings = await ref.read(settingsProvider.future);
    final enabled = settings?['biometric_enabled'] == 1;
    if (!enabled) return false;

    final ok = await BiometricService().authenticate();
    if (ok) {
      ref.read(appUnlockedProvider.notifier).state = true;
    }
    return ok;
  }

  Future<bool> canUseBiometrics() {
    return BiometricService().canUseBiometrics();
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final db = await ref.read(appDatabaseProvider).database;
    await db.update(
      'app_settings',
      {'biometric_enabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [1],
    );

    await SecurityLogService(ref.read(appDatabaseProvider)).log(
      eventType: enabled ? 'biometric_enabled' : 'biometric_disabled',
      message: enabled ? 'تم تفعيل المصادقة الحيوية' : 'تم إيقاف المصادقة الحيوية',
    );

    ref.invalidate(settingsProvider);
    ref.invalidate(securityLogProvider);
  }

  Future<void> updateAutoLock({
    required bool enabled,
    required int minutes,
  }) async {
    final db = await ref.read(appDatabaseProvider).database;
    await db.update(
      'app_settings',
      {
        'auto_lock_enabled': enabled ? 1 : 0,
        'auto_lock_minutes': minutes,
      },
      where: 'id = ?',
      whereArgs: [1],
    );

    await SecurityLogService(ref.read(appDatabaseProvider)).log(
      eventType: 'auto_lock_updated',
      message: enabled ? 'تم تفعيل القفل التلقائي بعد $minutes دقيقة' : 'تم إيقاف القفل التلقائي',
    );

    ref.invalidate(settingsProvider);
    ref.invalidate(securityLogProvider);
  }

  Future<void> lockNow() async {
    ref.read(appUnlockedProvider.notifier).state = false;
    await SecurityLogService(ref.read(appDatabaseProvider)).log(
      eventType: 'manual_lock',
      message: 'تم قفل التطبيق يدويًا',
    );
    ref.invalidate(securityLogProvider);
  }
}