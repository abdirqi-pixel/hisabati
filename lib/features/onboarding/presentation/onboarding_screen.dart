import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/database_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final userName = TextEditingController(text: 'المدير');
  final projectName = TextEditingController(text: 'مشروعي الأول');
  String? selectedCountryCode;

  @override
  void dispose() {
    userName.dispose();
    projectName.dispose();
    super.dispose();
  }

  Future<void> complete(List<Map<String, Object?>> countries) async {
    final country = countries.firstWhere(
      (c) => c['code'] == (selectedCountryCode ?? 'IQ'),
      orElse: () => countries.first,
    );

    final db = await ref.read(appDatabaseProvider).database;
    final now = DateTime.now().toIso8601String();

    final users = await db.query('app_users', limit: 1);
    int userId;
    if (users.isEmpty) {
      userId = await db.insert('app_users', {
        'name': userName.text.trim().isEmpty ? 'المدير' : userName.text.trim(),
        'role': 'admin',
        'color': '#10B981',
        'is_active': 1,
        'created_at': now,
      });
    } else {
      userId = users.first['id'] as int;
      await db.update(
        'app_users',
        {
          'name': userName.text.trim().isEmpty ? 'المدير' : userName.text.trim()
        },
        where: 'id = ?',
        whereArgs: [userId],
      );
    }

    await db.update(
      'app_settings',
      {
        'country_code': country['code'],
        'currency_code': country['currency_code'],
        'currency_symbol': country['currency_symbol'],
        'selected_user_id': userId,
        'is_onboarding_completed': 1,
      },
      where: 'id = ?',
      whereArgs: [1],
    );

    final projects = await db.query('projects', limit: 1);
    if (projects.isEmpty) {
      await db.insert('projects', {
        'name': projectName.text.trim().isEmpty
            ? 'مشروعي الأول'
            : projectName.text.trim(),
        'code': 'MAIN',
        'icon': '📁',
        'color': '#10B981',
        'country_code': country['code'],
        'currency_code': country['currency_code'],
        'currency_symbol': country['currency_symbol'],
        'budget': 0,
        'opening_balance': 0,
        'created_by': userId,
        'created_at': now,
      });
    }

    ref.invalidate(settingsProvider);
    ref.invalidate(projectsProvider);

    if (mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final countries = ref.watch(countriesProvider);

    return Scaffold(
      body: SafeArea(
        child: countries.when(
          data: (items) {
            selectedCountryCode ??= 'IQ';

            return ListView(
              padding: const EdgeInsets.all(22),
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.account_balance_wallet_rounded,
                    size: 72, color: Color(0xFF10B981)),
                const SizedBox(height: 18),
                const Text(
                  'أهلًا بك في حساباتي',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'سنجهز التطبيق حسب بلدك وعملتك وننشئ أول مستخدم ومشروع.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: userName,
                  decoration: const InputDecoration(
                    labelText: 'اسم المستخدم الرئيسي',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedCountryCode,
                  decoration: const InputDecoration(
                    labelText: 'البلد',
                    prefixIcon: Icon(Icons.public_rounded),
                  ),
                  items: items.map((c) {
                    return DropdownMenuItem<String>(
                      value: c['code'] as String,
                      child: Text('${c['name_ar']} - ${c['currency_symbol']}'),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => selectedCountryCode = value),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: projectName,
                  decoration: const InputDecoration(
                    labelText: 'اسم أول مشروع',
                    prefixIcon: Icon(Icons.folder_rounded),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => complete(items),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('ابدأ استخدام حساباتي'),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('خطأ: $e')),
        ),
      ),
    );
  }
}
