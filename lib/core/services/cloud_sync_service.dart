import 'dart:io';

import 'package:path/path.dart' as p;

import '../database/app_database.dart';
import 'secure_backup_service.dart';

class CloudSyncService {
  CloudSyncService(this.database);

  final AppDatabase database;

  Future<Map<String, Object?>?> getSettings() async {
    final db = await database.database;
    final rows = await db.query('cloud_sync_settings', limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> updateSettings({
    bool? isEnabled,
    bool? autoSyncEnabled,
    String? provider,
    String? folderPath,
    bool? includeAttachments,
  }) async {
    final db = await database.database;
    final rows = await db.query('cloud_sync_settings', limit: 1);

    final values = <String, Object?>{
      if (isEnabled != null) 'is_enabled': isEnabled ? 1 : 0,
      if (autoSyncEnabled != null) 'auto_sync_enabled': autoSyncEnabled ? 1 : 0,
      if (provider != null) 'provider': provider,
      if (folderPath != null) 'folder_path': folderPath,
      if (includeAttachments != null)
        'include_attachments': includeAttachments ? 1 : 0,
    };

    if (rows.isEmpty) {
      await db.insert('cloud_sync_settings', {
        'is_enabled': values['is_enabled'] ?? 0,
        'auto_sync_enabled': values['auto_sync_enabled'] ?? 0,
        'provider': values['provider'] ?? 'local_folder',
        'folder_path': values['folder_path'],
        'include_attachments': values['include_attachments'] ?? 1,
        'created_at': DateTime.now().toIso8601String(),
      });
    } else {
      await db.update(
        'cloud_sync_settings',
        values,
        where: 'id = ?',
        whereArgs: [rows.first['id']],
      );
    }
  }

  Future<File> uploadBackupToSyncFolder({
    required String password,
  }) async {
    final settings = await getSettings();
    if (settings == null || settings['is_enabled'] != 1) {
      throw Exception('المزامنة غير مفعّلة');
    }

    final folderPath = settings['folder_path']?.toString();
    if (folderPath == null || folderPath.isEmpty) {
      throw Exception('لم يتم اختيار مجلد المزامنة');
    }

    final folder = Directory(folderPath);
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final backupFile =
        await SecureBackupService(database).exportEncryptedBackup(password);
    final target = File(p.join(folder.path, p.basename(backupFile.path)));
    final copied = await backupFile.copy(target.path);
    final size = await copied.length();

    await _updateLastSync(
      status: 'success',
      message: 'تم رفع النسخة إلى مجلد المزامنة',
    );

    await _addHistory(
      provider: settings['provider']?.toString() ?? 'local_folder',
      filePath: copied.path,
      fileSize: size,
      status: 'success',
      message: 'تم إنشاء نسخة مزامنة',
    );

    return copied;
  }

  Future<List<FileSystemEntity>> listBackups() async {
    final settings = await getSettings();
    final folderPath = settings?['folder_path']?.toString();
    if (folderPath == null || folderPath.isEmpty) return [];

    final dir = Directory(folderPath);
    if (!await dir.exists()) return [];

    final files = dir
        .listSync()
        .where((e) =>
            e is File && (e.path.endsWith('.hbak') || e.path.endsWith('.json')))
        .toList();

    files.sort((a, b) {
      final am = File(a.path).lastModifiedSync();
      final bm = File(b.path).lastModifiedSync();
      return bm.compareTo(am);
    });

    return files;
  }

  Future<void> restoreFromBackup({
    required File file,
    required String password,
  }) async {
    await SecureBackupService(database).restoreEncryptedBackup(
      encryptedFile: file,
      password: password,
    );

    await _updateLastSync(
      status: 'success',
      message: 'تمت الاستعادة من نسخة مزامنة',
    );

    await _addHistory(
      provider: 'local_folder',
      filePath: file.path,
      fileSize: await file.length(),
      status: 'restored',
      message: 'تمت استعادة النسخة',
    );
  }

  Future<void> _updateLastSync({
    required String status,
    required String message,
  }) async {
    final db = await database.database;
    final rows = await db.query('cloud_sync_settings', limit: 1);
    if (rows.isEmpty) return;

    await db.update(
      'cloud_sync_settings',
      {
        'last_sync_at': DateTime.now().toIso8601String(),
        'last_sync_status': status,
        'last_sync_message': message,
      },
      where: 'id = ?',
      whereArgs: [rows.first['id']],
    );
  }

  Future<void> _addHistory({
    required String provider,
    required String filePath,
    required int fileSize,
    required String status,
    String? message,
  }) async {
    final db = await database.database;
    await db.insert('cloud_backup_history', {
      'provider': provider,
      'file_path': filePath,
      'file_size': fileSize,
      'status': status,
      'message': message,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
