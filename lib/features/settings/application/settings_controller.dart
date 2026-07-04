import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';
import '../../../core/services/notification_service.dart';

final themeModeProvider = FutureProvider<ThemeMode>((ref) async {
  final settings = await ref.watch(settingsProvider.future);
  final value = settings?['theme_mode']?.toString() ?? 'light';

  switch (value) {
    case 'dark':
      return ThemeMode.dark;
    case 'system':
      return ThemeMode.system;
    default:
      return ThemeMode.light;
  }
});

final settingsActionsProvider = Provider<SettingsActions>((ref) {
  return SettingsActions(ref);
});

class SettingsActions {
  SettingsActions(this.ref);

  final Ref ref;

  Future<void> updateThemeMode(String mode) async {
    final db = await ref.read(appDatabaseProvider).database;
    await db.update(
      'app_settings',
      {'theme_mode': mode},
      where: 'id = ?',
      whereArgs: [1],
    );

    ref.invalidate(settingsProvider);
    ref.invalidate(themeModeProvider);
  }

  Future<void> updateDailyReminder({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    final db = await ref.read(appDatabaseProvider).database;
    await db.update(
      'app_settings',
      {
        'daily_reminder_enabled': enabled ? 1 : 0,
        'daily_reminder_hour': hour,
        'daily_reminder_minute': minute,
      },
      where: 'id = ?',
      whereArgs: [1],
    );

    if (enabled) {
      await NotificationService.instance
          .scheduleDailyExpenseReminder(hour: hour, minute: minute);
    } else {
      await NotificationService.instance.cancelDailyExpenseReminder();
    }

    ref.invalidate(settingsProvider);
  }

  Future<void> updateBudgetAlert({
    required bool enabled,
    required double percent,
  }) async {
    final db = await ref.read(appDatabaseProvider).database;
    await db.update(
      'app_settings',
      {
        'budget_alert_enabled': enabled ? 1 : 0,
        'budget_alert_percent': percent,
      },
      where: 'id = ?',
      whereArgs: [1],
    );

    ref.invalidate(settingsProvider);
  }
}
