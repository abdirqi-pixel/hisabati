import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/settings_controller.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.light;
    final actions = ref.read(settingsActionsProvider);

    String currentValue() {
      switch (themeMode) {
        case ThemeMode.dark:
          return 'dark';
        case ThemeMode.system:
          return 'system';
        case ThemeMode.light:
          return 'light';
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('المظهر')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'اختر مظهر التطبيق',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: RadioListTile<String>(
              value: 'light',
              groupValue: currentValue(),
              onChanged: (_) => actions.updateThemeMode('light'),
              title: const Text('الوضع النهاري'),
              subtitle: const Text('واجهة فاتحة وواضحة'),
              secondary: const Icon(Icons.light_mode_rounded),
            ),
          ),
          Card(
            child: RadioListTile<String>(
              value: 'dark',
              groupValue: currentValue(),
              onChanged: (_) => actions.updateThemeMode('dark'),
              title: const Text('الوضع الليلي'),
              subtitle: const Text('واجهة داكنة مريحة للعين'),
              secondary: const Icon(Icons.dark_mode_rounded),
            ),
          ),
          Card(
            child: RadioListTile<String>(
              value: 'system',
              groupValue: currentValue(),
              onChanged: (_) => actions.updateThemeMode('system'),
              title: const Text('حسب النظام'),
              subtitle: const Text('يتبع إعدادات الجهاز'),
              secondary: const Icon(Icons.phone_android_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
