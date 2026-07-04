import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/database_providers.dart';
import '../../../core/services/activity_log_service.dart';

class ProjectFormScreen extends ConsumerStatefulWidget {
  const ProjectFormScreen({
    super.key,
    this.projectId,
  });

  final int? projectId;

  @override
  ConsumerState<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends ConsumerState<ProjectFormScreen> {
  final name = TextEditingController();
  final code = TextEditingController();
  final budget = TextEditingController();
  final openingBalance = TextEditingController();
  String icon = '📁';
  String color = '#10B981';
  String? selectedCountryCode;

  bool loaded = false;

  @override
  void dispose() {
    name.dispose();
    code.dispose();
    budget.dispose();
    openingBalance.dispose();
    super.dispose();
  }

  Future<void> loadProject() async {
    if (loaded || widget.projectId == null) return;
    loaded = true;

    final db = await ref.read(appDatabaseProvider).database;
    final rows = await db.query('projects',
        where: 'id = ?', whereArgs: [widget.projectId], limit: 1);
    if (rows.isEmpty) return;

    final p = rows.first;
    name.text = p['name']?.toString() ?? '';
    code.text = p['code']?.toString() ?? '';
    budget.text = (p['budget'] ?? 0).toString();
    openingBalance.text = (p['opening_balance'] ?? 0).toString();
    icon = p['icon']?.toString() ?? '📁';
    color = p['color']?.toString() ?? '#10B981';
    selectedCountryCode = p['country_code']?.toString();
    if (mounted) setState(() {});
  }

  Future<void> save(List<Map<String, Object?>> countries) async {
    if (name.text.trim().isEmpty) return;

    final country = countries.firstWhere(
      (c) => c['code'] == (selectedCountryCode ?? 'IQ'),
      orElse: () => countries.first,
    );

    final db = await ref.read(appDatabaseProvider).database;
    final settingsRows = await db.query('app_settings', limit: 1);
    final userId =
        settingsRows.isEmpty ? null : settingsRows.first['selected_user_id'];
    final now = DateTime.now().toIso8601String();

    final values = {
      'name': name.text.trim(),
      'code': code.text.trim().isEmpty ? null : code.text.trim(),
      'icon': icon,
      'color': color,
      'country_code': country['code'],
      'currency_code': country['currency_code'],
      'currency_symbol': country['currency_symbol'],
      'budget': double.tryParse(budget.text.trim()) ?? 0,
      'opening_balance': double.tryParse(openingBalance.text.trim()) ?? 0,
      'created_by': userId,
    };

    if (widget.projectId == null) {
      final projectId = await db.insert('projects', {
        ...values,
        'is_archived': 0,
        'is_deleted': 0,
        'created_at': now,
      });
      await ActivityLogService(ref.read(appDatabaseProvider)).log(
        action: 'create',
        entityType: 'project',
        entityId: projectId,
        userId: userId as int?,
        details: 'تم إنشاء مشروع ${name.text.trim()}',
      );
    } else {
      await db.update('projects', values,
          where: 'id = ?', whereArgs: [widget.projectId]);
      await ActivityLogService(ref.read(appDatabaseProvider)).log(
        action: 'update',
        entityType: 'project',
        entityId: widget.projectId,
        userId: userId as int?,
        details: 'تم تعديل مشروع ${name.text.trim()}',
      );
    }

    ref.invalidate(activityLogProvider);
    ref.invalidate(projectsProvider);
    ref.invalidate(archivedProjectsProvider);
    ref.invalidate(dashboardSummaryProvider);

    if (mounted) context.go('/projects');
  }

  @override
  Widget build(BuildContext context) {
    final countries = ref.watch(countriesProvider);
    loadProject();

    return Scaffold(
      appBar: AppBar(
          title: Text(widget.projectId == null ? 'مشروع جديد' : 'تعديل مشروع')),
      body: countries.when(
        data: (items) {
          selectedCountryCode ??= 'IQ';

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 44,
                  child: Text(icon, style: const TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'اسم المشروع',
                  prefixIcon: Icon(Icons.folder_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: code,
                decoration: const InputDecoration(
                  labelText: 'رمز المشروع اختياري',
                  hintText: 'مثلاً BUILD أو HOME',
                  prefixIcon: Icon(Icons.tag_rounded),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedCountryCode,
                decoration: const InputDecoration(
                  labelText: 'بلد المشروع والعملة',
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
              const SizedBox(height: 12),
              TextField(
                controller: budget,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'ميزانية المشروع',
                  prefixIcon: Icon(Icons.savings_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: openingBalance,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'الرصيد الافتتاحي',
                  prefixIcon: Icon(Icons.account_balance_wallet_rounded),
                ),
              ),
              const SizedBox(height: 18),
              const Text('اختر أيقونة المشروع',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  '📁',
                  '🏗️',
                  '🏠',
                  '🚗',
                  '🏢',
                  '🛒',
                  '💼',
                  '🧾',
                  '⚙️',
                  '🌾'
                ].map((value) {
                  return ChoiceChip(
                    label: Text(value, style: const TextStyle(fontSize: 22)),
                    selected: icon == value,
                    onSelected: (_) => setState(() => icon = value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => save(items),
                icon: const Icon(Icons.save_rounded),
                label: const Text('حفظ المشروع'),
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
