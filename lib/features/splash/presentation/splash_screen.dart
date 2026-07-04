import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/recurring_service.dart';
import '../../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), checkStart);
  }

  Future<void> checkStart() async {
    final db = await AppDatabase.instance.database;
    await RecurringService(AppDatabase.instance).processDueTransactions();
    final rows = await db.query('app_settings', limit: 1);
    final completed =
        rows.isNotEmpty && rows.first['is_onboarding_completed'] == 1;
    final lockEnabled = rows.isNotEmpty &&
        rows.first['is_pin_enabled'] == 1 &&
        rows.first['lock_on_start'] == 1;

    if (!mounted) return;
    if (!completed) {
      context.go('/onboarding');
      return;
    }

    context.go(lockEnabled ? '/lock' : '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.emerald,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 72,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'حساباتي',
              style: TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'إدارة مشاريعك ومصروفاتك بسهولة',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
