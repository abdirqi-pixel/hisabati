import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  String roleName(String role) {
    switch (role) {
      case 'admin':
        return 'مدير';
      case 'accountant':
        return 'محاسب';
      case 'employee':
        return 'موظف';
      case 'viewer':
        return 'مشاهد';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(appUsersProvider);
    final selectedUser = ref.watch(selectedUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المستخدمين')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const _UserForm(),
        ),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('مستخدم جديد'),
      ),
      body: users.when(
        data: (items) => selectedUser.when(
          data: (current) => ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final u = items[index];
              final isSelected = current?['id'] == u['id'];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text((u['name'] as String).characters.first)),
                  title: Text(u['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${roleName(u['role'] as String)}${isSelected ? ' • المستخدم الحالي' : ''}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      final db = await ref.read(appDatabaseProvider).database;
                      if (value == 'select') {
                        await db.update('app_settings', {'selected_user_id': u['id']}, where: 'id = ?', whereArgs: [1]);
                        ref.invalidate(selectedUserProvider);
                        ref.invalidate(settingsProvider);
                      }
                      if (value == 'delete') {
                        await db.update('app_users', {'is_active': 0}, where: 'id = ?', whereArgs: [u['id']]);
                        ref.invalidate(appUsersProvider);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'select', child: Text('اجعله المستخدم الحالي')),
                      if (!isSelected) const PopupMenuItem(value: 'delete', child: Text('تعطيل')),
                    ],
                  ),
                ),
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('خطأ: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
      ),
    );
  }
}

class _UserForm extends ConsumerStatefulWidget {
  const _UserForm();

  @override
  ConsumerState<_UserForm> createState() => _UserFormState();
}

class _UserFormState extends ConsumerState<_UserForm> {
  final name = TextEditingController();
  String role = 'employee';

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty) return;
    final db = await ref.read(appDatabaseProvider).database;

    await db.insert('app_users', {
      'name': name.text.trim(),
      'role': role,
      'color': '#10B981',
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    ref.invalidate(appUsersProvider);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('إضافة مستخدم', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'اسم المستخدم'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: role,
            decoration: const InputDecoration(labelText: 'الصلاحية'),
            items: const [
              DropdownMenuItem(value: 'admin', child: Text('مدير')),
              DropdownMenuItem(value: 'accountant', child: Text('محاسب')),
              DropdownMenuItem(value: 'employee', child: Text('موظف')),
              DropdownMenuItem(value: 'viewer', child: Text('مشاهد')),
            ],
            onChanged: (value) => setState(() => role = value ?? 'employee'),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: save, icon: const Icon(Icons.save_rounded), label: const Text('حفظ')),
        ],
      ),
    );
  }
}