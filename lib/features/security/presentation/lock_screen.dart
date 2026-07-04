import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/security_controller.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String pin = '';
  String? error;

  @override
  void initState() {
    super.initState();
    Future.microtask(tryBiometric);
  }

  Future<void> tryBiometric() async {
    final ok =
        await ref.read(securityActionsProvider).authenticateWithBiometrics();
    if (ok && mounted) {
      context.go('/dashboard');
    }
  }

  Future<void> submit() async {
    if (pin.length < 4) return;

    final ok = await ref.read(securityActionsProvider).verifyPin(pin);
    if (ok && mounted) {
      context.go('/dashboard');
    } else {
      setState(() {
        pin = '';
        error = 'رمز PIN غير صحيح';
      });
    }
  }

  void addDigit(String value) {
    if (pin.length >= 6) return;
    setState(() {
      pin += value;
      error = null;
    });

    if (pin.length >= 4) {
      submit();
    }
  }

  void removeDigit() {
    if (pin.isEmpty) return;
    setState(() => pin = pin.substring(0, pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_rounded,
                  size: 72, color: Color(0xFF10B981)),
              const SizedBox(height: 20),
              const Text('أدخل رمز الحماية',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('لحماية بيانات حساباتي'),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  final filled = index < pin.length;
                  return Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? const Color(0xFF10B981)
                          : Colors.grey.shade300,
                    ),
                  );
                }),
              ),
              if (error != null) ...[
                const SizedBox(height: 14),
                Text(error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: tryBiometric,
                icon: const Icon(Icons.fingerprint_rounded),
                label: const Text('فتح بالبصمة أو Face ID'),
              ),
              const SizedBox(height: 18),
              _Keypad(
                onDigit: addDigit,
                onBackspace: removeDigit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onDigit,
    required this.onBackspace,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'back'];

    return GridView.builder(
      shrinkWrap: true,
      itemCount: keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, index) {
        final key = keys[index];
        if (key.isEmpty) return const SizedBox.shrink();

        return FilledButton.tonal(
          onPressed: key == 'back' ? onBackspace : () => onDigit(key),
          child: key == 'back'
              ? const Icon(Icons.backspace_rounded)
              : Text(key,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
        );
      },
    );
  }
}
