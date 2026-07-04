import '../database/app_database.dart';

class ActivityLogService {
  ActivityLogService(this.database);

  final AppDatabase database;

  Future<void> log({
    required String action,
    required String entityType,
    int? entityId,
    int? userId,
    String? details,
  }) async {
    final db = await database.database;
    await db.insert('activity_log', {
      'user_id': userId,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'details': details,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}