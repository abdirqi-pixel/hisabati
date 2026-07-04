import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import '../database/app_database.dart';

class BackupService {
  BackupService(this.database);

  final AppDatabase database;

  static const tables = [
    'countries',
    'app_users',
    'app_settings',
    'modified_file_logs',
    'build_fix_logs',
    'flutter_command_checks',
    'app_releases',
    'support_tickets',
    'feature_requests',
    'tester_feedback',
    'financial_goals',
    'recurring_runs',
    'recurring_transactions',
    'security_log',
    'cloud_backup_history',
    'cloud_sync_settings',
    'app_notifications',
    'dashboard_preferences',
    'saved_report_filters',
    'projects',
    'budgets',
    'persons',
    'categories',
    'expenses',
    'expense_attachments',
    'treasury_transactions',
    'incomes',
    'advances',
    'activity_log',
  ];

  Future<File> exportBackup() async {
    final db = await database.database;
    final data = <String, Object?>{
      'app': 'hisabati',
      'version': 1,
      'created_at': DateTime.now().toIso8601String(),
      'tables': {},
    };

    final tablesData = <String, Object?>{};
    for (final table in tables) {
      tablesData[table] = await db.query(table);
    }
    data['tables'] = tablesData;

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'hisabati_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data), encoding: utf8);
    return file;
  }

  Future<void> restoreBackup(File file) async {
    final content = await file.readAsString(encoding: utf8);
    final decoded = jsonDecode(content);

    if (decoded is! Map || decoded['app'] != 'hisabati') {
      throw Exception('ملف النسخة الاحتياطية غير صالح');
    }

    final tablesData = decoded['tables'];
    if (tablesData is! Map) {
      throw Exception('الملف لا يحتوي على جداول صالحة');
    }

    final db = await database.database;

    await db.transaction((txn) async {
      for (final table in tables.reversed) {
        await txn.delete(table);
      }

      for (final table in tables) {
        final rows = tablesData[table];
        if (rows is List) {
          for (final row in rows) {
            if (row is Map) {
              await txn.insert(
                table,
                row.cast<String, Object?>(),
              );
            }
          }
        }
      }
    });
  }
}