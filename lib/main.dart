import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/application/settings_controller.dart';
import 'core/services/notification_service.dart';
import 'features/security/presentation/app_lock_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await NotificationService.instance.init();
  } catch (error, stackTrace) {
    debugPrint('Notification initialization skipped: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  runApp(const ProviderScope(child: HisabatiApp()));
}

class HisabatiApp extends ConsumerWidget {
  const HisabatiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.light;

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'حساباتي',
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AppLockWrapper(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}