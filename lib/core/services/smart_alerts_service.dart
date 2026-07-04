import '../database/app_database.dart';
import 'app_notification_service.dart';
import 'notification_service.dart';

class SmartAlertsService {
  SmartAlertsService(this.database);

  final AppDatabase database;

  Future<void> checkBudgetAlerts() async {
    final db = await database.database;
    final rows = await db.rawQuery('''
      SELECT 
        budgets.id,
        budgets.name,
        budgets.amount,
        budgets.alert_percent,
        budgets.currency_symbol,
        projects.name AS project_name,
        COALESCE(SUM(expenses.amount), 0) AS spent
      FROM budgets
      LEFT JOIN projects ON projects.id = budgets.project_id
      LEFT JOIN expenses ON expenses.project_id = budgets.project_id
        AND expenses.is_deleted = 0
        AND strftime('%Y', expenses.expense_date) = CAST(budgets.period_year AS TEXT)
        AND (
          budgets.type = 'yearly'
          OR strftime('%m', expenses.expense_date) = printf('%02d', budgets.period_month)
        )
      WHERE budgets.is_active = 1
      GROUP BY budgets.id
    ''');

    for (final row in rows) {
      final amount = (row['amount'] as num?) ?? 0;
      final spent = (row['spent'] as num?) ?? 0;
      final alertPercent = (row['alert_percent'] as num?) ?? .8;
      if (amount <= 0) continue;

      final percent = spent / amount;
      final budgetName = row['name'].toString();
      final projectName = row['project_name']?.toString() ?? '';
      final symbol = row['currency_symbol']?.toString() ?? '';

      if (percent >= 1) {
        await _createUniqueToday(
          type: 'budget_exceeded',
          title: 'تم تجاوز الميزانية',
          message:
              'ميزانية $budgetName في $projectName تجاوزت الحد. المصروف: ${spent.toStringAsFixed(0)} $symbol',
          entityType: 'budget',
          entityId: row['id'] as int?,
        );
      } else if (percent >= alertPercent) {
        await _createUniqueToday(
          type: 'budget_warning',
          title: 'اقتراب من حد الميزانية',
          message:
              'ميزانية $budgetName وصلت إلى ${(percent * 100).toStringAsFixed(0)}%',
          entityType: 'budget',
          entityId: row['id'] as int?,
        );
      }
    }
  }

  Future<void> checkTreasuryLow({num minimum = 0}) async {
    final db = await database.database;
    final rows = await db.rawQuery('''
      SELECT
        COALESCE(SUM(opening_balance), 0)
        + (SELECT COALESCE(SUM(amount), 0) FROM incomes WHERE is_deleted = 0)
        + (SELECT COALESCE(SUM(amount), 0) FROM treasury_transactions WHERE is_deleted = 0 AND type = 'deposit')
        - (SELECT COALESCE(SUM(amount), 0) FROM treasury_transactions WHERE is_deleted = 0 AND type = 'withdraw')
        - (SELECT COALESCE(SUM(amount), 0) FROM expenses WHERE is_deleted = 0)
        AS balance
      FROM projects
      WHERE is_deleted = 0 AND is_archived = 0
    ''');

    final balance = (rows.first['balance'] as num?) ?? 0;
    if (balance <= minimum) {
      await _createUniqueToday(
        type: 'treasury_low',
        title: 'رصيد الصندوق منخفض',
        message: 'الرصيد الحالي أصبح ${balance.toStringAsFixed(0)}',
        entityType: 'treasury',
      );
    }
  }

  Future<void> checkAdvancesDue() async {
    final db = await database.database;
    final rows = await db.rawQuery('''
      SELECT 
        persons.name AS person_name,
        advances.person_id,
        COALESCE(SUM(CASE WHEN advances.type = 'advance' THEN advances.amount ELSE -advances.amount END), 0) AS remaining
      FROM advances
      LEFT JOIN persons ON persons.id = advances.person_id
      WHERE advances.is_deleted = 0
      GROUP BY advances.person_id
      HAVING remaining > 0
      ORDER BY remaining DESC
      LIMIT 10
    ''');

    for (final row in rows) {
      await _createUniqueToday(
        type: 'advance_due',
        title: 'سلفة غير مسددة',
        message:
            '${row['person_name'] ?? 'شخص'} لديه متبقي ${row['remaining']}',
        entityType: 'advance',
        entityId: row['person_id'] as int?,
      );
    }
  }

  Future<void> runAllChecks() async {
    await checkBudgetAlerts();
    await checkTreasuryLow();
    await checkAdvancesDue();
  }

  Future<void> _createUniqueToday({
    required String type,
    required String title,
    required String message,
    String? entityType,
    int? entityId,
  }) async {
    final db = await database.database;
    final today = DateTime.now().toIso8601String().split('T').first;

    final existing = await db.query(
      'app_notifications',
      where:
          'type = ? AND entity_type IS ? AND entity_id IS ? AND created_at LIKE ?',
      whereArgs: [type, entityType, entityId, '$today%'],
      limit: 1,
    );

    if (existing.isNotEmpty) return;

    await AppNotificationService(database).create(
      type: type,
      title: title,
      message: message,
      entityType: entityType,
      entityId: entityId,
    );

    await NotificationService.instance.showBudgetAlert(
      title: title,
      body: message,
    );
  }
}
