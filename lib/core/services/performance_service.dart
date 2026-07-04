import '../database/app_database.dart';

class PerformanceService {
  PerformanceService(this.database);

  final AppDatabase database;

  Future<void> optimize() async {
    final db = await database.database;
    await db.execute('ANALYZE');
    await db.execute('PRAGMA optimize');
  }

  Future<Map<String, Object?>> getPerformanceInfo() async {
    final db = await database.database;

    final pageCount = await db.rawQuery('PRAGMA page_count');
    final pageSize = await db.rawQuery('PRAGMA page_size');

    Future<int> count(String table) async {
      final rows = await db.rawQuery('SELECT COUNT(*) AS count FROM $table');
      return (rows.first['count'] as int?) ?? 0;
    }

    return {
      'pageCount': pageCount.first.values.first,
      'pageSize': pageSize.first.values.first,
      'expenses': await count('expenses'),
      'incomes': await count('incomes'),
      'advances': await count('advances'),
      'projects': await count('projects'),
      'persons': await count('persons'),
      'activityLog': await count('activity_log'),
      'notifications': await count('app_notifications'),
    };
  }
}