import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/data/database_providers.dart';
import '../../../core/services/activity_log_service.dart';
import '../../../core/services/smart_alerts_service.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({
    super.key,
    this.initialAmount,
    this.initialDescription,
    this.initialNotes,
    this.initialAttachmentPath,
  });

  final String? initialAmount;
  final String? initialDescription;
  final String? initialNotes;
  final String? initialAttachmentPath;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  final notesController = TextEditingController();

  int? selectedPersonId;
  int? selectedCategoryId;

  final List<_PendingAttachment> pendingAttachments = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount != null) {
      amountController.text = widget.initialAmount!;
    }
    if (widget.initialDescription != null) {
      descriptionController.text = widget.initialDescription!;
    }
    if (widget.initialNotes != null) {
      notesController.text = widget.initialNotes!;
    }
    if (widget.initialAttachmentPath != null &&
        widget.initialAttachmentPath!.isNotEmpty) {
      pendingAttachments
          .add({'type': 'image', 'path': widget.initialAttachmentPath!});
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> pickImageFromCamera() async {
    final picker = ImagePicker();
    final image =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (image == null) return;
    setState(() => pendingAttachments
        .add(_PendingAttachment(type: 'image', path: image.path)));
  }

  Future<void> pickImageFromGallery() async {
    final picker = ImagePicker();
    final image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return;
    setState(() => pendingAttachments
        .add(_PendingAttachment(type: 'image', path: image.path)));
  }

  Future<void> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.single.path == null) return;
    setState(() => pendingAttachments
        .add(_PendingAttachment(type: 'pdf', path: result.files.single.path!)));
  }

  Future<void> _save() async {
    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب مبلغ صحيح')),
      );
      return;
    }

    final db = await ref.read(appDatabaseProvider).database;
    final projects = await db.query('projects', limit: 1);
    final settings = await db.query('app_settings', limit: 1);
    if (projects.isEmpty || settings.isEmpty) return;

    final now = DateTime.now();
    final count = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM expenses')) ??
        0;
    final serial = '#${(count + 1).toString().padLeft(6, '0')}';

    final expenseId = await db.insert('expenses', {
      'serial_number': serial,
      'project_id': projects.first['id'],
      'person_id': selectedPersonId,
      'category_id': selectedCategoryId,
      'amount': amount,
      'currency_code': settings.first['currency_code'],
      'currency_symbol': settings.first['currency_symbol'],
      'description': descriptionController.text.trim(),
      'expense_date': now.toIso8601String().split('T').first,
      'expense_time':
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      'notes': notesController.text.trim(),
      'created_by': settings.first['selected_user_id'],
      'created_at': now.toIso8601String(),
    });

    for (final attachment in pendingAttachments) {
      await db.insert('expense_attachments', {
        'expense_id': expenseId,
        'type': attachment.type,
        'file_path': attachment.path,
        'created_at': now.toIso8601String(),
      });
    }

    await ActivityLogService(ref.read(appDatabaseProvider)).log(
      action: 'create',
      entityType: 'expense',
      entityId: expenseId,
      userId: settings.first['selected_user_id'] as int?,
      details: 'تمت إضافة عملية $serial بمبلغ $amount',
    );

    ref.invalidate(activityLogProvider);
    ref.invalidate(expensesProvider);
    ref.invalidate(filteredExpensesProvider);
    ref.invalidate(dashboardSummaryProvider);
    await SmartAlertsService(ref.read(appDatabaseProvider)).runAllChecks();
    ref.invalidate(appNotificationsProvider);
    ref.invalidate(unreadNotificationsCountProvider);
    ref.invalidate(reportsSummaryProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حفظ العملية $serial')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final persons = ref.watch(personsProvider);
    final categories = ref.watch(categoriesProvider);
    final selectedUser = ref.watch(selectedUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('إضافة عملية')),
      body: selectedUser.when(
        data: (user) {
          final role = (user?['role'] ?? 'viewer').toString();
          if (!roleCanEdit(role)) {
            return const Center(child: Text('ليس لديك صلاحية إضافة عمليات'));
          }

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              settings.when(
                data: (s) => Text(
                  'العملة الحالية: ${s?['currency_symbol'] ?? 'د.ع'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('$e'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: 'المبلغ',
                  prefixIcon: Icon(Icons.payments_rounded),
                ),
              ),
              const SizedBox(height: 14),
              persons.when(
                data: (items) => DropdownButtonFormField<int>(
                  initialValue: selectedPersonId,
                  decoration: const InputDecoration(
                    labelText: 'الشخص',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                  items: items.map((p) {
                    return DropdownMenuItem<int>(
                      value: p['id'] as int,
                      child: Text(p['name'] as String),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => selectedPersonId = value),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('$e'),
              ),
              const SizedBox(height: 14),
              categories.when(
                data: (items) => DropdownButtonFormField<int>(
                  initialValue: selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'التصنيف',
                    prefixIcon: Icon(Icons.category_rounded),
                  ),
                  items: items.map((c) {
                    return DropdownMenuItem<int>(
                      value: c['id'] as int,
                      child: Text(c['name'] as String),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => selectedCategoryId = value),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('$e'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'تفاصيل هذا المبلغ',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات إضافية',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
              ),
              const SizedBox(height: 18),
              const Text('المرفقات',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.camera_alt_rounded),
                      title: const Text('تصوير فاتورة'),
                      onTap: pickImageFromCamera,
                    ),
                    ListTile(
                      leading: const Icon(Icons.photo_library_rounded),
                      title: const Text('اختيار صورة'),
                      onTap: pickImageFromGallery,
                    ),
                    ListTile(
                      leading: const Icon(Icons.picture_as_pdf_rounded),
                      title: const Text('إرفاق PDF'),
                      onTap: pickPdf,
                    ),
                  ],
                ),
              ),
              if (pendingAttachments.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...pendingAttachments.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Card(
                    child: ListTile(
                      leading: Icon(item.type == 'image'
                          ? Icons.image_rounded
                          : Icons.picture_as_pdf_rounded),
                      title: Text(item.type == 'image' ? 'صورة' : 'PDF'),
                      subtitle: Text(item.path),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_rounded),
                        onPressed: () =>
                            setState(() => pendingAttachments.removeAt(index)),
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_rounded),
                label: const Text('حفظ العملية'),
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

class _PendingAttachment {
  const _PendingAttachment({
    required this.type,
    required this.path,
  });

  final String type;
  final String path;
}
