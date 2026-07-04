import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';
import '../application/settings_controller.dart';

class NotificationsSettingsScreen extends ConsumerWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final actions = ref.read(settingsActionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('التنبيهات')),
      body: settings.when(
        data: (s) {
          final reminderEnabled = s?['daily_reminder_enabled'] == 1;
          final hour = (s?['daily_reminder_hour'] as int?) ?? 20;
          final minute = (s?['daily_reminder_minute'] as int?) ?? 0;
          final budgetEnabled = s?['budget_alert_enabled'] != 0;
          final budgetPercent = ((s?['budget_alert_percent'] as num?) ?? .8).toDouble();

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Card(
                child: SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_rounded),
                  title: const Text('تذكير يومي بإدخال المصروفات'),
                  subtitle: Text('الوقت الحالي: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}'),
                  value: reminderEnabled,
                  onChanged: (value) => actions.updateDailyReminder(
                    enabled: value,
                    hour: hour,
                    minute: minute,
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.schedule_rounded),
                  title: const Text('وقت التذكير اليومي'),
                  subtitle: Text('${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}'),
                  trailing: const Icon(Icons.arrow_back_ios_new_rounded),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(hour: hour, minute: minute),
                    );

                    if (picked != null) {
                      await actions.updateDailyReminder(
                        enabled: reminderEnabled,
                        hour: picked.hour,
                        minute: picked.minute,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: SwitchListTile(
                  secondary: const Icon(Icons.warning_amber_rounded),
                  title: const Text('تنبيه الميزانية'),
                  subtitle: Text('تنبيه عند الوصول إلى ${(budgetPercent * 100).toStringAsFixed(0)}% من الميزانية'),
                  value: budgetEnabled,
                  onChanged: (value) => actions.updateBudgetAlert(
                    enabled: value,
                    percent: budgetPercent,
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('نسبة تنبيه الميزانية', style: TextStyle(fontWeight: FontWeight.bold)),
                      Slider(
                        value: budgetPercent,
                        min: .5,
                        max: 1,
                        divisions: 5,
                        label: '${(budgetPercent * 100).toStringAsFixed(0)}%',
                        onChanged: budgetEnabled
                            ? (value) => actions.updateBudgetAlert(
                                  enabled: true,
                                  percent: value,
                                )
                            : null,
                      ),
                    ],
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