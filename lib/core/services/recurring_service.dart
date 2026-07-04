import '../database/app_database.dart';
import 'activity_log_service.dart';
import 'app_notification_service.dart';

class RecurringService {
  RecurringService(this.database);

  final AppDatabase database;

  Future<int> processDueTransactions() async {
    final db = await database.database;
    final today = DateTime.now().toIso8601String().split('T').first;

    final due = await db.query(
      'recurring_transactions',
      where: 'is_active = 1 AND next_run_date <= ? AND (end_date IS NULL OR end_date = "" OR end_date >= ?)',
      whereArgs: [today, today],
      orderBy: 'next_run_date ASC',
    );

    var created = 0;

    for (final item in due) {
      final recurringId = item['id'] as int;
      final runDate = item['next_run_date'].toString();

      final already = await db.query(
        'recurring_runs',
        where: 'recurring_id = ? AND run_date = ?',
        whereArgs: [recurringId, runDate],
        limit: 1,
      );

      if (already.isNotEmpty) {
        await _advanceNextRun(item);
        continue;
      }

      if (item['type'] == 'expense') {
        final expenseId = await db.insert('expenses', {
          'serial_number': await _nextSerialNumber(),
          'project_id': item['project_id'],
          'person_id': item['person_id'],
          'category_id': item['category_id'],
          'amount': item['amount'],
          'currency_code': item['currency_code'],
          'currency_symbol': item['currency_symbol'],
          'description': item['description'] ?? item['title'],
          'expense_date': runDate,
          'expense_time': '00:00',
          'notes': 'تم إنشاؤه تلقائيًا من عملية دورية: ${item['title']}',
          'created_by': item['created_by'],
          'created_at': DateTime.now().toIso8601String(),
        });

        await db.insert('recurring_runs', {
          'recurring_id': recurringId,
          'generated_entity_type': 'expense',
          'generated_entity_id': expenseId,
          'run_date': runDate,
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        final incomeId = await db.insert('incomes', {
          'project_id': item['project_id'],
          'amount': item['amount'],
          'currency_code': item['currency_code'],
          'currency_symbol': item['currency_symbol'],
          'source': item['title'],
          'description': item['description'],
          'income_date': runDate,
          'created_by': item['created_by'],
          'created_at': DateTime.now().toIso8601String(),
        });

        await db.insert('recurring_runs', {
          'recurring_id': recurringId,
          'generated_entity_type': 'income',
          'generated_entity_id': incomeId,
          'run_date': runDate,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      await ActivityLogService(database).log(
        action: 'create',
        entityType: 'recurring',
        entityId: recurringId,
        userId: item['created_by'] as int?,
        details: 'تم إنشاء عملية دورية تلقائيًا: ${item['title']}',
      );

      await AppNotificationService(database).create(
        type: 'recurring_created',
        title: 'تم إنشاء عملية دورية',
        message: 'تم إنشاء ${item['type'] == 'expense' ? 'مصروف' : 'إيراد'}: ${item['title']}',
        entityType: 'recurring',
        entityId: recurringId,
      );

      await _advanceNextRun(item);
      created++;
    }

    return created;
  }

  Future<String> _nextSerialNumber() async {
    final db = await database.database;
    final row = await db.rawQuery('SELECT COUNT(*) AS count FROM expenses');
    final count = (row.first['count'] as int?) ?? 0;
    return '#${(count + 1).toString().padLeft(6, '0')}';
  }

  Future<void> _advanceNextRun(Map<String, Object?> item) async {
    final db = await database.database;
    final current = DateTime.tryParse(item['next_run_date'].toString()) ?? DateTime.now();
    final interval = (item['interval_value'] as int?) ?? 1;
    final frequency = item['frequency'].toString();

    DateTime next;
    switch (frequency) {
      case 'daily':
        next = current.add(Duration(days: interval));
        break;
      case 'weekly':
        next = current.add(Duration(days: 7 * interval));
        break;
      case 'monthly':
        next = DateTime(current.year, current.month + interval, current.day);
        break;
      case 'yearly':
        next = DateTime(current.year + interval, current.month, current.day);
        break;
      default:
        next = current.add(Duration(days: interval));
    }

    await db.update(
      'recurring_transactions',
      {
        'last_run_date': item['next_run_date'],
        'next_run_date': next.toIso8601String().split('T').first,
      },
      where: 'id = ?',
      whereArgs: [item['id']],
    );
  }
}