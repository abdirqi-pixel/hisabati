import '../database/app_database.dart';

class MaintenanceService {
  MaintenanceService(this.database);

  final AppDatabase database;

  Future<Map<String, Object?>> getDatabaseStats() async {
    final db = await database.database;

    Future<int> count(String table, {String? where}) async {
      final rows = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM $table ${where == null ? '' : 'WHERE $where'}',
      );
      return (rows.first['count'] as int?) ?? 0;
    }

    return {
      'projects': await count('projects', where: 'is_deleted = 0'),
      'archivedProjects': await count('projects', where: 'is_archived = 1 AND is_deleted = 0'),
      'persons': await count('persons', where: 'is_deleted = 0'),
      'expenses': await count('expenses', where: 'is_deleted = 0'),
      'incomes': await count('incomes', where: 'is_deleted = 0'),
      'advances': await count('advances', where: 'is_deleted = 0'),
      'treasury': await count('treasury_transactions', where: 'is_deleted = 0'),
      'attachments': await count('expense_attachments'),
      'activityLog': await count('activity_log'),
      'deletedProjects': await count('projects', where: 'is_deleted = 1'),
      'deletedPersons': await count('persons', where: 'is_deleted = 1'),
      'deletedExpenses': await count('expenses', where: 'is_deleted = 1'),
    };
  }

  Future<void> vacuumDatabase() async {
    final db = await database.database;
    await db.execute('VACUUM');
  }

  Future<int> cleanOldActivityLogs({int keepLatest = 500}) async {
    final db = await database.database;
    final rows = await db.rawQuery('''
      SELECT id FROM activity_log
      ORDER BY id DESC
      LIMIT 1 OFFSET ?
    ''', [keepLatest]);

    if (rows.isEmpty) return 0;

    final thresholdId = rows.first['id'] as int;
    return db.delete(
      'activity_log',
      where: 'id < ?',
      whereArgs: [thresholdId],
    );
  }

  Future<int> emptyTrash() async {
    final db = await database.database;
    var deleted = 0;

    await db.transaction((txn) async {
      deleted += await txn.delete('expenses', where: 'is_deleted = 1');
      deleted += await txn.delete('incomes', where: 'is_deleted = 1');
      deleted += await txn.delete('advances', where: 'is_deleted = 1');
      deleted += await txn.delete('treasury_transactions', where: 'is_deleted = 1');
      deleted += await txn.delete('categories', where: 'is_deleted = 1');
      deleted += await txn.delete('persons', where: 'is_deleted = 1');
      deleted += await txn.delete('projects', where: 'is_deleted = 1');
    });

    return deleted;
  }
}