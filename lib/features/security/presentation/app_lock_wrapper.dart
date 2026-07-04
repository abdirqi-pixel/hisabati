import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';
import '../application/security_controller.dart';
import 'lock_screen.dart';

class AppLockWrapper extends ConsumerStatefulWidget {
  const AppLockWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends ConsumerState<AppLockWrapper> {
  Timer? timer;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void resetTimer({
    required bool enabled,
    required int minutes,
    required bool pinEnabled,
  }) {
    timer?.cancel();

    if (!enabled || !pinEnabled) return;

    timer = Timer(Duration(minutes: minutes), () {
      ref.read(appUnlockedProvider.notifier).state = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value;
    final unlocked = ref.watch(appUnlockedProvider);

    final pinEnabled = settings?['is_pin_enabled'] == 1;
    final autoLockEnabled = settings?['auto_lock_enabled'] == 1;
    final minutes = (settings?['auto_lock_minutes'] as int?) ?? 5;

    if (pinEnabled && !unlocked && settings?['lock_on_start'] == 1) {
      return const LockScreen();
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => resetTimer(
        enabled: autoLockEnabled,
        minutes: minutes,
        pinEnabled: pinEnabled,
      ),
      onPointerMove: (_) => resetTimer(
        enabled: autoLockEnabled,
        minutes: minutes,
        pinEnabled: pinEnabled,
      ),
      child: widget.child,
    );
  }
}
