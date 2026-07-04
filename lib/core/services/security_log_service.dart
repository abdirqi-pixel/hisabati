import '../database/app_database.dart';

class SecurityLogService {
  SecurityLogService(this.database);

  final AppDatabase database;

  Future<void> log({
    required String eventType,
    required String message,
  }) async {
    final db = await database.database;
    await db.insert('security_log', {
      'event_type': eventType,
      'message': message,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}