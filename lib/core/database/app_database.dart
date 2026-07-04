import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'hisabati.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE countries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name_ar TEXT NOT NULL,
        code TEXT NOT NULL UNIQUE,
        currency_code TEXT NOT NULL,
        currency_symbol TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE app_users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        color TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        country_code TEXT NOT NULL DEFAULT 'IQ',
        currency_code TEXT NOT NULL DEFAULT 'IQD',
        currency_symbol TEXT NOT NULL DEFAULT 'د.ع',
        selected_user_id INTEGER,
        is_pin_enabled INTEGER NOT NULL DEFAULT 0,
        pin_code TEXT,
        lock_on_start INTEGER NOT NULL DEFAULT 0,
        biometric_enabled INTEGER NOT NULL DEFAULT 0,
        auto_lock_enabled INTEGER NOT NULL DEFAULT 0,
        auto_lock_minutes INTEGER NOT NULL DEFAULT 5,
        is_onboarding_completed INTEGER NOT NULL DEFAULT 0,
        theme_mode TEXT NOT NULL DEFAULT 'light',
        daily_reminder_enabled INTEGER NOT NULL DEFAULT 0,
        daily_reminder_hour INTEGER NOT NULL DEFAULT 20,
        daily_reminder_minute INTEGER NOT NULL DEFAULT 0,
        budget_alert_enabled INTEGER NOT NULL DEFAULT 1,
        budget_alert_percent REAL NOT NULL DEFAULT 0.8,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT,
        icon TEXT,
        color TEXT,
        country_code TEXT NOT NULL,
        currency_code TEXT NOT NULL,
        currency_symbol TEXT NOT NULL,
        budget REAL NOT NULL DEFAULT 0,
        opening_balance REAL NOT NULL DEFAULT 0,
        is_archived INTEGER NOT NULL DEFAULT 0,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        created_by INTEGER,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE persons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        color TEXT,
        image_path TEXT,
        phone TEXT,
        notes TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY(project_id) REFERENCES projects(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER,
        name TEXT NOT NULL,
        icon TEXT,
        color TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        is_default INTEGER NOT NULL DEFAULT 0,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY(project_id) REFERENCES projects(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        serial_number TEXT NOT NULL UNIQUE,
        project_id INTEGER NOT NULL,
        person_id INTEGER,
        category_id INTEGER,
        amount REAL NOT NULL,
        currency_code TEXT NOT NULL,
        currency_symbol TEXT NOT NULL,
        description TEXT,
        expense_date TEXT NOT NULL,
        expense_time TEXT NOT NULL,
        notes TEXT,
        latitude REAL,
        longitude REAL,
        created_by INTEGER,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY(project_id) REFERENCES projects(id),
        FOREIGN KEY(person_id) REFERENCES persons(id),
        FOREIGN KEY(category_id) REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE expense_attachments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        expense_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        file_path TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(expense_id) REFERENCES expenses(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE treasury_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        currency_code TEXT NOT NULL,
        currency_symbol TEXT NOT NULL,
        note TEXT,
        transaction_date TEXT NOT NULL,
        created_by INTEGER,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY(project_id) REFERENCES projects(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE modified_file_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        file_path TEXT NOT NULL,
        reason TEXT,
        status TEXT NOT NULL DEFAULT 'مفتوح',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE build_fix_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        command TEXT NOT NULL,
        error_text TEXT,
        fix_text TEXT,
        status TEXT NOT NULL DEFAULT 'مفتوح',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE flutter_command_checks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        command TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'لم يتم',
        notes TEXT,
        checked_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE app_releases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        version TEXT NOT NULL,
        title TEXT NOT NULL,
        notes TEXT,
        release_date TEXT NOT NULL,
        is_current INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE support_tickets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        priority TEXT NOT NULL DEFAULT 'متوسطة',
        status TEXT NOT NULL DEFAULT 'مفتوح',
        device_info TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE feature_requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        priority TEXT NOT NULL DEFAULT 'متوسطة',
        status TEXT NOT NULL DEFAULT 'مقترحة',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tester_feedback (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tester_name TEXT,
        screen_name TEXT,
        issue TEXT NOT NULL,
        priority TEXT NOT NULL DEFAULT 'متوسطة',
        status TEXT NOT NULL DEFAULT 'جديد',
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE financial_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL NOT NULL DEFAULT 0,
        currency_code TEXT NOT NULL,
        currency_symbol TEXT NOT NULL,
        target_date TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        created_by INTEGER,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE recurring_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL,
        person_id INTEGER,
        category_id INTEGER,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        currency_code TEXT NOT NULL,
        currency_symbol TEXT NOT NULL,
        description TEXT,
        frequency TEXT NOT NULL,
        interval_value INTEGER NOT NULL DEFAULT 1,
        start_date TEXT NOT NULL,
        end_date TEXT,
        next_run_date TEXT NOT NULL,
        last_run_date TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_by INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY(project_id) REFERENCES projects(id),
        FOREIGN KEY(person_id) REFERENCES persons(id),
        FOREIGN KEY(category_id) REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE recurring_runs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recurring_id INTEGER NOT NULL,
        generated_entity_type TEXT NOT NULL,
        generated_entity_id INTEGER NOT NULL,
        run_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(recurring_id) REFERENCES recurring_transactions(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE security_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_type TEXT NOT NULL,
        message TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cloud_sync_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        is_enabled INTEGER NOT NULL DEFAULT 0,
        auto_sync_enabled INTEGER NOT NULL DEFAULT 0,
        provider TEXT NOT NULL DEFAULT 'local_folder',
        folder_path TEXT,
        include_attachments INTEGER NOT NULL DEFAULT 1,
        last_sync_at TEXT,
        last_sync_status TEXT,
        last_sync_message TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cloud_backup_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        provider TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_size INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL,
        message TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE app_notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        entity_type TEXT,
        entity_id INTEGER,
        is_read INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        currency_code TEXT NOT NULL,
        currency_symbol TEXT NOT NULL,
        period_year INTEGER NOT NULL,
        period_month INTEGER,
        alert_percent REAL NOT NULL DEFAULT 0.8,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_by INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY(project_id) REFERENCES projects(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE dashboard_preferences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL,
        is_visible INTEGER NOT NULL DEFAULT 1,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE saved_report_filters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        project_id INTEGER,
        person_id INTEGER,
        category_id INTEGER,
        date_from TEXT,
        date_to TEXT,
        amount_from REAL,
        amount_to REAL,
        created_by INTEGER,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE incomes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        currency_code TEXT NOT NULL,
        currency_symbol TEXT NOT NULL,
        source TEXT,
        description TEXT,
        income_date TEXT NOT NULL,
        created_by INTEGER,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY(project_id) REFERENCES projects(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE advances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL,
        person_id INTEGER,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        currency_code TEXT NOT NULL,
        currency_symbol TEXT NOT NULL,
        note TEXT,
        advance_date TEXT NOT NULL,
        created_by INTEGER,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY(project_id) REFERENCES projects(id),
        FOREIGN KEY(person_id) REFERENCES persons(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE activity_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        action TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id INTEGER,
        details TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await _seed(db);
  }

  Future<void> _seed(Database db) async {
    final now = DateTime.now().toIso8601String();

    final countries = [
      ['العراق', 'IQ', 'IQD', 'د.ع'],
      ['السعودية', 'SA', 'SAR', 'ر.س'],
      ['الكويت', 'KW', 'KWD', 'د.ك'],
      ['الإمارات', 'AE', 'AED', 'د.إ'],
      ['قطر', 'QA', 'QAR', 'ر.ق'],
      ['البحرين', 'BH', 'BHD', 'د.ب'],
      ['عُمان', 'OM', 'OMR', 'ر.ع'],
      ['الأردن', 'JO', 'JOD', 'د.أ'],
      ['مصر', 'EG', 'EGP', 'ج.م'],
      ['تركيا', 'TR', 'TRY', '₺'],
      ['الولايات المتحدة', 'US', 'USD', r'$'],
    ];

    for (final c in countries) {
      await db.insert('countries', {
        'name_ar': c[0],
        'code': c[1],
        'currency_code': c[2],
        'currency_symbol': c[3],
      });
    }

    final adminId = await db.insert('app_users', {
      'name': 'المدير',
      'role': 'admin',
      'color': '#10B981',
      'is_active': 1,
      'created_at': now,
    });

    await db.insert('app_settings', {
      'country_code': 'IQ',
      'currency_code': 'IQD',
      'currency_symbol': 'د.ع',
      'selected_user_id': adminId,
      'is_pin_enabled': 0,
      'pin_code': null,
      'lock_on_start': 0,
      'biometric_enabled': 0,
      'auto_lock_enabled': 0,
      'auto_lock_minutes': 5,
      'is_onboarding_completed': 0,
      'theme_mode': 'light',
      'daily_reminder_enabled': 0,
      'daily_reminder_hour': 20,
      'daily_reminder_minute': 0,
      'budget_alert_enabled': 1,
      'budget_alert_percent': 0.8,
      'created_at': now,
    });

    final projectId = await db.insert('projects', {
      'name': 'مشروع البناء',
      'code': 'BUILD',
      'icon': '🏗️',
      'color': '#10B981',
      'country_code': 'IQ',
      'currency_code': 'IQD',
      'currency_symbol': 'د.ع',
      'budget': 20000000,
      'opening_balance': 5000000,
      'created_by': adminId,
      'created_at': now,
    });

    final defaultCategories = [
      ['مواد', 'inventory_2_rounded', '#10B981'],
      ['نقل', 'local_shipping_rounded', '#3B82F6'],
      ['أجور', 'engineering_rounded', '#F59E0B'],
      ['ضيافة', 'local_cafe_rounded', '#8B5CF6'],
      ['وقود', 'local_gas_station_rounded', '#EF4444'],
    ];

    for (var i = 0; i < defaultCategories.length; i++) {
      await db.insert('categories', {
        'project_id': projectId,
        'name': defaultCategories[i][0],
        'icon': defaultCategories[i][1],
        'color': defaultCategories[i][2],
        'sort_order': i,
        'is_default': 1,
        'created_at': now,
      });
    }

    await db.insert('persons', {
      'project_id': projectId,
      'name': 'أحمد',
      'color': '#10B981',
      'created_at': now,
    });

    final dashboardPrefs = [
      ['balance_card', 'بطاقة الرصيد', 1, 0],
      ['budget_alert', 'مؤشر الميزانية', 1, 1],
      ['quick_actions', 'الاختصارات السريعة', 1, 2],
      ['projects', 'المشاريع النشطة', 1, 3],
      ['latest_expenses', 'آخر العمليات', 1, 4],
      ['top_categories', 'أعلى التصنيفات', 1, 5],
      ['top_persons', 'أعلى الأشخاص', 1, 6],
    ];

    for (final pref in dashboardPrefs) {
      await db.insert('dashboard_preferences', {
        'key': pref[0],
        'title': pref[1],
        'is_visible': pref[2],
        'sort_order': pref[3],
      });
    }

    await db.insert('cloud_sync_settings', {
      'is_enabled': 0,
      'auto_sync_enabled': 0,
      'provider': 'local_folder',
      'folder_path': null,
      'include_attachments': 1,
      'created_at': now,
    });

    await db.insert('app_releases', {
      'version': '1.0.0',
      'title': 'الإصدار الأول',
      'notes':
          'الإصدار الأول من تطبيق حساباتي مع إدارة مالية وتقارير ونسخ احتياطي وأمان.',
      'release_date': DateTime.now().toIso8601String().split('T').first,
      'is_current': 1,
    });
  }

  Future<List<Map<String, Object?>>> all(String table) async {
    final db = await database;
    return db.query(table);
  }

  Future<int> insert(String table, Map<String, Object?> values) async {
    final db = await database;
    return db.insert(table, values);
  }
}
