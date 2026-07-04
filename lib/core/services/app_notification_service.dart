import '../database/app_database.dart';

class AppNotificationService {
  AppNotificationService(this.database);

  final AppDatabase database;

  Future<int> create({
    required String type,
    required String title,
    required String message,
    String? entityType,
    int? entityId,
  }) async {
    final db = await database.database;

    return db.insert('app_notifications', {
      'type': type,
      'title': title,
      'message': message,
      'entity_type': entityType,
      'entity_id': entityId,
      'is_read': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> markAsRead(int id) async {
    final db = await database.database;
    await db.update(
      'app_notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markAllAsRead() async {
    final db = await database.database;
    await db.update('app_notifications', {'is_read': 1});
  }

  Future<void> delete(int id) async {
    final db = await database.database;
    await db.delete(
      'app_notifications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearRead() async {
    final db = await database.database;
    return db.delete(
      'app_notifications',
      where: 'is_read = ?',
      whereArgs: [1],
    );
  }
}