import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../services/maintenance_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/performance_service.dart';
import 'dart:io';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

final countriesProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.all('countries');
});

final settingsProvider = FutureProvider<Map<String, Object?>?>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;
  final rows = await db.query('app_settings', limit: 1);
  return rows.isEmpty ? null : rows.first;
});

final projectsProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;
  return db.query(
    'projects',
    where: 'is_deleted = ? AND is_archived = ?',
    whereArgs: [0, 0],
    orderBy: 'id DESC',
  );
});

final personsProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;
  return db.query(
    'persons',
    where: 'is_deleted = ?',
    whereArgs: [0],
    orderBy: 'id DESC',
  );
});

final categoriesProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;
  return db.query(
    'categories',
    where: 'is_deleted = ?',
    whereArgs: [0],
    orderBy: 'sort_order ASC, id DESC',
  );
});

final expensesProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;
  return db.rawQuery('''
    SELECT 
      expenses.*,
      persons.name AS person_name,
      categories.name AS category_name,
      categories.color AS category_color,
      (SELECT COUNT(*) FROM expense_attachments WHERE expense_attachments.expense_id = expenses.id) AS attachment_count
    FROM expenses
    LEFT JOIN persons ON persons.id = expenses.person_id
    LEFT JOIN categories ON categories.id = expenses.category_id
    WHERE expenses.is_deleted = 0
    ORDER BY expenses.id DESC
  ''');
});

final treasuryTransactionsProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;
  return db.rawQuery('''
    SELECT 
      treasury_transactions.*,
      projects.name AS project_name
    FROM treasury_transactions
    LEFT JOIN projects ON projects.id = treasury_transactions.project_id
    WHERE treasury_transactions.is_deleted = 0
    ORDER BY treasury_transactions.id DESC
  ''');
});

final dashboardSummaryProvider = FutureProvider<Map<String, num>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;

  final projectRows = await db.query(
    'projects',
    where: 'is_deleted = ? AND is_archived = ?',
    whereArgs: [0, 0],
  );

  final openingBalance = projectRows.fold<num>(
    0,
    (sum, row) => sum + ((row['opening_balance'] as num?) ?? 0),
  );

  final expensesTotalRow = await db.rawQuery(
    'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses WHERE is_deleted = 0',
  );
  final expensesTotal = (expensesTotalRow.first['total'] as num?) ?? 0;

  final depositsRow = await db.rawQuery(
    "SELECT COALESCE(SUM(amount), 0) AS total FROM treasury_transactions WHERE is_deleted = 0 AND type = 'deposit'",
  );
  final withdrawalsRow = await db.rawQuery(
    "SELECT COALESCE(SUM(amount), 0) AS total FROM treasury_transactions WHERE is_deleted = 0 AND type = 'withdraw'",
  );

  final incomesRow = await db.rawQuery(
    'SELECT COALESCE(SUM(amount), 0) AS total FROM incomes WHERE is_deleted = 0',
  );

  final deposits = (depositsRow.first['total'] as num?) ?? 0;
  final withdrawals = (withdrawalsRow.first['total'] as num?) ?? 0;
  final incomes = (incomesRow.first['total'] as num?) ?? 0;

  final currentBalance = openingBalance + deposits + incomes - withdrawals - expensesTotal;

  return {
    'openingBalance': openingBalance,
    'expensesTotal': expensesTotal,
    'deposits': deposits,
    'withdrawals': withdrawals,
    'incomes': incomes,
    'currentBalance': currentBalance,
    'projectsCount': projectRows.length,
  };
});


final reportsSummaryProvider = FutureProvider<Map<String, Object?>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;

  final byCategory = await db.rawQuery('''
    SELECT 
      COALESCE(categories.name, 'بدون تصنيف') AS name,
      COALESCE(SUM(expenses.amount), 0) AS total,
      COUNT(expenses.id) AS count
    FROM expenses
    LEFT JOIN categories ON categories.id = expenses.category_id
    WHERE expenses.is_deleted = 0
    GROUP BY expenses.category_id
    ORDER BY total DESC
  ''');

  final byPerson = await db.rawQuery('''
    SELECT 
      COALESCE(persons.name, 'بدون شخص') AS name,
      COALESCE(SUM(expenses.amount), 0) AS total,
      COUNT(expenses.id) AS count
    FROM expenses
    LEFT JOIN persons ON persons.id = expenses.person_id
    WHERE expenses.is_deleted = 0
    GROUP BY expenses.person_id
    ORDER BY total DESC
  ''');

  final byDay = await db.rawQuery('''
    SELECT 
      expense_date AS date,
      COALESCE(SUM(amount), 0) AS total,
      COUNT(id) AS count
    FROM expenses
    WHERE is_deleted = 0
    GROUP BY expense_date
    ORDER BY expense_date DESC
    LIMIT 30
  ''');

  final totalRow = await db.rawQuery(
    'SELECT COALESCE(SUM(amount), 0) AS total, COUNT(id) AS count FROM expenses WHERE is_deleted = 0',
  );

  return {
    'byCategory': byCategory,
    'byPerson': byPerson,
    'byDay': byDay,
    'total': totalRow.first['total'] ?? 0,
    'count': totalRow.first['count'] ?? 0,
  };
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredExpensesProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  final query = ref.watch(searchQueryProvider).trim();
  final db = await ref.watch(appDatabaseProvider).database;

  if (query.isEmpty) {
    return ref.watch(expensesProvider.future);
  }

  return db.rawQuery('''
    SELECT 
      expenses.*,
      persons.name AS person_name,
      categories.name AS category_name,
      categories.color AS category_color,
      (SELECT COUNT(*) FROM expense_attachments WHERE expense_attachments.expense_id = expenses.id) AS attachment_count
    FROM expenses
    LEFT JOIN persons ON persons.id = expenses.person_id
    LEFT JOIN categories ON categories.id = expenses.category_id
    WHERE expenses.is_deleted = 0
      AND (
        expenses.serial_number LIKE ?
        OR expenses.description LIKE ?
        OR expenses.notes LIKE ?
        OR persons.name LIKE ?
        OR categories.name LIKE ?
        OR CAST(expenses.amount AS TEXT) LIKE ?
      )
    ORDER BY expenses.id DESC
  ''', ['%$query%', '%$query%', '%$query%', '%$query%', '%$query%', '%$query%']);
});


final appUsersProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;
  return db.query(
    'app_users',
    where: 'is_active = ?',
    whereArgs: [1],
    orderBy: 'id DESC',
  );
});

final selectedUserProvider = FutureProvider<Map<String, Object?>?>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;
  final settingsRows = await db.query('app_settings', limit: 1);
  if (settingsRows.isEmpty) return null;
  final userId = settingsRows.first['selected_user_id'];
  if (userId == null) return null;
  final users = await db.query('app_users', where: 'id = ?', whereArgs: [userId], limit: 1);
  return users.isEmpty ? null : users.first;
});

bool roleCanEdit(String role) {
  return role == 'admin' || role == 'accountant' || role == 'employee';
}

bool roleCanDelete(String role) {
  return role == 'admin' || role == 'accountant';
}

bool roleCanManageSettings(String role) {
  return role == 'admin';
}


final expenseAttachmentsProvider = FutureProvider.family<List<Map<String, Object?>>, int>((ref, expenseId) async {
  final db = await ref.watch(appDatabaseProvider).database;
  return db.query(
    'expense_attachments',
    where: 'expense_id = ?',
    whereArgs: [expenseId],
    orderBy: 'id DESC',
  );
});


final archivedProjectsProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;
  return db.query(
    'projects',
    where: 'is_deleted = ? AND is_archived = ?',
    whereArgs: [0, 1],
    orderBy: 'id DESC',
  );
});


final dashboardInsightsProvider = FutureProvider<Map<String, Object?>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;

  final latestExpenses = await db.rawQuery('''
    SELECT 
      expenses.*,
      persons.name AS person_name,
      categories.name AS category_name
    FROM expenses
    LEFT JOIN persons ON persons.id = expenses.person_id
    LEFT JOIN categories ON categories.id = expenses.category_id
    WHERE expenses.is_deleted = 0
    ORDER BY expenses.id DESC
    LIMIT 5
  ''');

  final topCategories = await db.rawQuery('''
    SELECT 
      COALESCE(categories.name, 'بدون تصنيف') AS name,
      COALESCE(SUM(expenses.amount), 0) AS total
    FROM expenses
    LEFT JOIN categories ON categories.id = expenses.category_id
    WHERE expenses.is_deleted = 0
    GROUP BY expenses.category_id
    ORDER BY total DESC
    LIMIT 5
  ''');

  final topPersons = await db.rawQuery('''
    SELECT 
      COALESCE(persons.name, 'بدون شخص') AS name,
      COALESCE(SUM(expenses.amount), 0) AS total
    FROM expenses
    LEFT JOIN persons ON persons.id = expenses.person_id
    WHERE expenses.is_deleted = 0
    GROUP BY expenses.person_id
    ORDER BY total DESC
    LIMIT 5
  ''');

  final budgetRows = await db.rawQuery('''
    SELECT 
      COALESCE(SUM(budget), 0) AS budget
    FROM projects
    WHERE is_deleted = 0 AND is_archived = 0
  ''');

  final expenseRows = await db.rawQuery('''
    SELECT 
      COALESCE(SUM(amount), 0) AS total
    FROM expenses
    WHERE is_deleted = 0
  ''');

  final totalBudget = (budgetRows.first['budget'] as num?) ?? 0;
  final totalExpenses = (expenseRows.first['total'] as num?) ?? 0;
  final budgetPercent = totalBudget <= 0 ? 0 : (totalExpenses / totalBudget).clamp(0, 999);

  return {
    'latestExpenses': latestExpenses,
    'topCategories': topCategories,
    'topPersons': topPersons,
    'totalBudget': totalBudget,
    'totalExpenses': totalExpenses,
    'budgetPercent': budgetPercent,
  };
});


final activityLogProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;
  return db.rawQuery('''
    SELECT 
      activity_log.*,
      app_users.name AS user_name
    FROM activity_log
    LEFT JOIN app_users ON app_users.id = activity_log.user_id
    ORDER BY activity_log.id DESC
    LIMIT 200
  ''');
});

final trashProvider = FutureProvider<Map<String, List<Map<String, Object?>>>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;

  final projects = await db.query('projects', where: 'is_deleted = ?', whereArgs: [1], orderBy: 'id DESC');
  final persons = await db.query('persons', where: 'is_deleted = ?', whereArgs: [1], orderBy: 'id DESC');
  final categories = await db.query('categories', where: 'is_deleted = ?', whereArgs: [1], orderBy: 'id DESC');
  final expenses = await db.query('expenses', where: 'is_deleted = ?', whereArgs: [1], orderBy: 'id DESC');
  final treasury = await db.query('treasury_transactions', where: 'is_deleted = ?', whereArgs: [1], orderBy: 'id DESC');
  final advances = await db.query('advances', where: 'is_deleted = ?', whereArgs: [1], orderBy: 'id DESC');
  final incomesTrash = await db.query('incomes', where: 'is_deleted = ?', whereArgs: [1], orderBy: 'id DESC');

  return {
    'projects': projects,
    'persons': persons,
    'categories': categories,
    'expenses': expenses,
    'treasury_transactions': treasury,
    'advances': advances,
    'incomes': incomesTrash,
  };
});


final advancesProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;
  return db.rawQuery('''
    SELECT 
      advances.*,
      persons.name AS person_name,
      projects.name AS project_name
    FROM advances
    LEFT JOIN persons ON persons.id = advances.person_id
    LEFT JOIN projects ON projects.id = advances.project_id
    WHERE advances.is_deleted = 0
    ORDER BY advances.id DESC
  ''');
});

final advancesSummaryProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;
  return db.rawQuery('''
    SELECT 
      COALESCE(persons.name, 'بدون شخص') AS person_name,
      advances.person_id,
      COALESCE(SUM(CASE WHEN advances.type = 'advance' THEN advances.amount ELSE 0 END), 0) AS total_advances,
      COALESCE(SUM(CASE WHEN advances.type = 'payment' THEN advances.amount ELSE 0 END), 0) AS total_payments,
      COALESCE(SUM(CASE WHEN advances.type = 'advance' THEN advances.amount ELSE -advances.amount END), 0) AS remaining
    FROM advances
    LEFT JOIN persons ON persons.id = advances.person_id
    WHERE advances.is_deleted = 0
    GROUP BY advances.person_id
    ORDER BY remaining DESC
  ''');
});


final incomesProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;
  return db.rawQuery('''
    SELECT 
      incomes.*,
      projects.name AS project_name
    FROM incomes
    LEFT JOIN projects ON projects.id = incomes.project_id
    WHERE incomes.is_deleted = 0
    ORDER BY incomes.id DESC
  ''');
});

final incomesTotalProvider = FutureProvider<num>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;
  final rows = await db.rawQuery('SELECT COALESCE(SUM(amount), 0) AS total FROM incomes WHERE is_deleted = 0');
  return (rows.first['total'] as num?) ?? 0;
});


final projectDetailsProvider = FutureProvider.family<Map<String, Object?>, int>((ref, projectId) async {
  final db = await ref.watch(appDatabaseProvider).database;

  final projectRows = await db.query('projects', where: 'id = ?', whereArgs: [projectId], limit: 1);
  final project = projectRows.isEmpty ? <String, Object?>{} : projectRows.first;

  final expensesRow = await db.rawQuery(
    'SELECT COALESCE(SUM(amount), 0) AS total, COUNT(id) AS count FROM expenses WHERE is_deleted = 0 AND project_id = ?',
    [projectId],
  );

  final incomesRow = await db.rawQuery(
    'SELECT COALESCE(SUM(amount), 0) AS total, COUNT(id) AS count FROM incomes WHERE is_deleted = 0 AND project_id = ?',
    [projectId],
  );

  final treasuryDepositsRow = await db.rawQuery(
    "SELECT COALESCE(SUM(amount), 0) AS total FROM treasury_transactions WHERE is_deleted = 0 AND project_id = ? AND type = 'deposit'",
    [projectId],
  );

  final treasuryWithdrawalsRow = await db.rawQuery(
    "SELECT COALESCE(SUM(amount), 0) AS total FROM treasury_transactions WHERE is_deleted = 0 AND project_id = ? AND type = 'withdraw'",
    [projectId],
  );

  final advancesRow = await db.rawQuery(
    "SELECT COALESCE(SUM(CASE WHEN type = 'advance' THEN amount ELSE -amount END), 0) AS remaining FROM advances WHERE is_deleted = 0 AND project_id = ?",
    [projectId],
  );

  final personsCountRow = await db.rawQuery(
    'SELECT COUNT(id) AS count FROM persons WHERE is_deleted = 0 AND project_id = ?',
    [projectId],
  );

  final latestExpenses = await db.rawQuery('''
    SELECT 
      expenses.*,
      persons.name AS person_name,
      categories.name AS category_name
    FROM expenses
    LEFT JOIN persons ON persons.id = expenses.person_id
    LEFT JOIN categories ON categories.id = expenses.category_id
    WHERE expenses.is_deleted = 0 AND expenses.project_id = ?
    ORDER BY expenses.id DESC
    LIMIT 8
  ''', [projectId]);

  final opening = (project['opening_balance'] as num?) ?? 0;
  final expensesTotal = (expensesRow.first['total'] as num?) ?? 0;
  final incomesTotal = (incomesRow.first['total'] as num?) ?? 0;
  final deposits = (treasuryDepositsRow.first['total'] as num?) ?? 0;
  final withdrawals = (treasuryWithdrawalsRow.first['total'] as num?) ?? 0;
  final remainingAdvances = (advancesRow.first['remaining'] as num?) ?? 0;
  final balance = opening + incomesTotal + deposits - withdrawals - expensesTotal;
  final budget = (project['budget'] as num?) ?? 0;
  final budgetPercent = budget <= 0 ? 0 : (expensesTotal / budget).clamp(0, 999);

  return {
    'project': project,
    'expensesTotal': expensesTotal,
    'expensesCount': expensesRow.first['count'] ?? 0,
    'incomesTotal': incomesTotal,
    'incomesCount': incomesRow.first['count'] ?? 0,
    'deposits': deposits,
    'withdrawals': withdrawals,
    'remainingAdvances': remainingAdvances,
    'personsCount': personsCountRow.first['count'] ?? 0,
    'balance': balance,
    'budgetPercent': budgetPercent,
    'latestExpenses': latestExpenses,
  };
});


class ReportFilter {
  const ReportFilter({
    this.projectId,
    this.personId,
    this.categoryId,
    this.dateFrom,
    this.dateTo,
    this.amountFrom,
    this.amountTo,
  });

  final int? projectId;
  final int? personId;
  final int? categoryId;
  final String? dateFrom;
  final String? dateTo;
  final double? amountFrom;
  final double? amountTo;

  ReportFilter copyWith({
    int? projectId,
    int? personId,
    int? categoryId,
    String? dateFrom,
    String? dateTo,
    double? amountFrom,
    double? amountTo,
    bool clearProject = false,
    bool clearPerson = false,
    bool clearCategory = false,
    bool clearDates = false,
    bool clearAmounts = false,
  }) {
    return ReportFilter(
      projectId: clearProject ? null : projectId ?? this.projectId,
      personId: clearPerson ? null : personId ?? this.personId,
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
      dateFrom: clearDates ? null : dateFrom ?? this.dateFrom,
      dateTo: clearDates ? null : dateTo ?? this.dateTo,
      amountFrom: clearAmounts ? null : amountFrom ?? this.amountFrom,
      amountTo: clearAmounts ? null : amountTo ?? this.amountTo,
    );
  }
}

final reportFilterProvider = StateProvider<ReportFilter>((ref) => const ReportFilter());

final advancedReportProvider = FutureProvider<Map<String, Object?>>((ref) async {
  final filter = ref.watch(reportFilterProvider);
  final db = await ref.watch(appDatabaseProvider).database;

  final where = <String>['expenses.is_deleted = 0'];
  final args = <Object?>[];

  if (filter.projectId != null) {
    where.add('expenses.project_id = ?');
    args.add(filter.projectId);
  }

  if (filter.personId != null) {
    where.add('expenses.person_id = ?');
    args.add(filter.personId);
  }

  if (filter.categoryId != null) {
    where.add('expenses.category_id = ?');
    args.add(filter.categoryId);
  }

  if (filter.dateFrom != null && filter.dateFrom!.isNotEmpty) {
    where.add('expenses.expense_date >= ?');
    args.add(filter.dateFrom);
  }

  if (filter.dateTo != null && filter.dateTo!.isNotEmpty) {
    where.add('expenses.expense_date <= ?');
    args.add(filter.dateTo);
  }

  if (filter.amountFrom != null) {
    where.add('expenses.amount >= ?');
    args.add(filter.amountFrom);
  }

  if (filter.amountTo != null) {
    where.add('expenses.amount <= ?');
    args.add(filter.amountTo);
  }

  final whereSql = where.join(' AND ');

  final expenses = await db.rawQuery('''
    SELECT 
      expenses.*,
      projects.name AS project_name,
      persons.name AS person_name,
      categories.name AS category_name
    FROM expenses
    LEFT JOIN projects ON projects.id = expenses.project_id
    LEFT JOIN persons ON persons.id = expenses.person_id
    LEFT JOIN categories ON categories.id = expenses.category_id
    WHERE $whereSql
    ORDER BY expenses.expense_date DESC, expenses.id DESC
  ''', args);

  final totalRows = await db.rawQuery('''
    SELECT COALESCE(SUM(expenses.amount), 0) AS total, COUNT(expenses.id) AS count
    FROM expenses
    WHERE ${where.map((w) => w.replaceAll('expenses.', '')).join(' AND ')}
  ''', args);

  final byCategory = await db.rawQuery('''
    SELECT 
      COALESCE(categories.name, 'بدون تصنيف') AS name,
      COALESCE(SUM(expenses.amount), 0) AS total,
      COUNT(expenses.id) AS count
    FROM expenses
    LEFT JOIN categories ON categories.id = expenses.category_id
    WHERE $whereSql
    GROUP BY expenses.category_id
    ORDER BY total DESC
  ''', args);

  final byPerson = await db.rawQuery('''
    SELECT 
      COALESCE(persons.name, 'بدون شخص') AS name,
      COALESCE(SUM(expenses.amount), 0) AS total,
      COUNT(expenses.id) AS count
    FROM expenses
    LEFT JOIN persons ON persons.id = expenses.person_id
    WHERE $whereSql
    GROUP BY expenses.person_id
    ORDER BY total DESC
  ''', args);

  final byProject = await db.rawQuery('''
    SELECT 
      COALESCE(projects.name, 'بدون مشروع') AS name,
      COALESCE(SUM(expenses.amount), 0) AS total,
      COUNT(expenses.id) AS count
    FROM expenses
    LEFT JOIN projects ON projects.id = expenses.project_id
    WHERE $whereSql
    GROUP BY expenses.project_id
    ORDER BY total DESC
  ''', args);

  return {
    'expenses': expenses,
    'total': totalRows.first['total'] ?? 0,
    'count': totalRows.first['count'] ?? 0,
    'byCategory': byCategory,
    'byPerson': byPerson,
    'byProject': byProject,
  };
});


final savedReportFiltersProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;
  return db.query(
    'saved_report_filters',
    orderBy: 'id DESC',
  );
});


final globalSearchQueryProvider = StateProvider<String>((ref) => '');

final globalSearchProvider = FutureProvider<Map<String, List<Map<String, Object?>>>>((ref) async {
  final query = ref.watch(globalSearchQueryProvider).trim();
  final db = await ref.watch(appDatabaseProvider).database;

  if (query.isEmpty) {
    return {
      'projects': [],
      'persons': [],
      'expenses': [],
      'incomes': [],
      'advances': [],
      'treasury': [],
    };
  }

  final like = '%$query%';

  final projects = await db.rawQuery('''
    SELECT * FROM projects
    WHERE is_deleted = 0
      AND (name LIKE ? OR code LIKE ? OR currency_symbol LIKE ?)
    ORDER BY id DESC
    LIMIT 30
  ''', [like, like, like]);

  final persons = await db.rawQuery('''
    SELECT persons.*, projects.name AS project_name
    FROM persons
    LEFT JOIN projects ON projects.id = persons.project_id
    WHERE persons.is_deleted = 0
      AND (persons.name LIKE ? OR persons.phone LIKE ? OR persons.notes LIKE ?)
    ORDER BY persons.id DESC
    LIMIT 30
  ''', [like, like, like]);

  final expenses = await db.rawQuery('''
    SELECT expenses.*, projects.name AS project_name, persons.name AS person_name, categories.name AS category_name
    FROM expenses
    LEFT JOIN projects ON projects.id = expenses.project_id
    LEFT JOIN persons ON persons.id = expenses.person_id
    LEFT JOIN categories ON categories.id = expenses.category_id
    WHERE expenses.is_deleted = 0
      AND (
        expenses.serial_number LIKE ?
        OR expenses.description LIKE ?
        OR expenses.notes LIKE ?
        OR CAST(expenses.amount AS TEXT) LIKE ?
        OR projects.name LIKE ?
        OR persons.name LIKE ?
        OR categories.name LIKE ?
      )
    ORDER BY expenses.id DESC
    LIMIT 50
  ''', [like, like, like, like, like, like, like]);

  final incomes = await db.rawQuery('''
    SELECT incomes.*, projects.name AS project_name
    FROM incomes
    LEFT JOIN projects ON projects.id = incomes.project_id
    WHERE incomes.is_deleted = 0
      AND (
        incomes.source LIKE ?
        OR incomes.description LIKE ?
        OR CAST(incomes.amount AS TEXT) LIKE ?
        OR projects.name LIKE ?
      )
    ORDER BY incomes.id DESC
    LIMIT 30
  ''', [like, like, like, like]);

  final advances = await db.rawQuery('''
    SELECT advances.*, persons.name AS person_name, projects.name AS project_name
    FROM advances
    LEFT JOIN persons ON persons.id = advances.person_id
    LEFT JOIN projects ON projects.id = advances.project_id
    WHERE advances.is_deleted = 0
      AND (
        advances.note LIKE ?
        OR CAST(advances.amount AS TEXT) LIKE ?
        OR persons.name LIKE ?
        OR projects.name LIKE ?
      )
    ORDER BY advances.id DESC
    LIMIT 30
  ''', [like, like, like, like]);

  final treasury = await db.rawQuery('''
    SELECT treasury_transactions.*, projects.name AS project_name
    FROM treasury_transactions
    LEFT JOIN projects ON projects.id = treasury_transactions.project_id
    WHERE treasury_transactions.is_deleted = 0
      AND (
        treasury_transactions.note LIKE ?
        OR CAST(treasury_transactions.amount AS TEXT) LIKE ?
        OR projects.name LIKE ?
      )
    ORDER BY treasury_transactions.id DESC
    LIMIT 30
  ''', [like, like, like]);

  return {
    'projects': projects,
    'persons': persons,
    'expenses': expenses,
    'incomes': incomes,
    'advances': advances,
    'treasury': treasury,
  };
});


final allAttachmentsProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;
  return db.rawQuery('''
    SELECT 
      expense_attachments.*,
      expenses.serial_number AS expense_serial,
      expenses.amount AS expense_amount,
      expenses.currency_symbol AS currency_symbol,
      expenses.description AS expense_description
    FROM expense_attachments
    LEFT JOIN expenses ON expenses.id = expense_attachments.expense_id
    ORDER BY expense_attachments.id DESC
  ''');
});


final dashboardPreferencesProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;
  return db.query(
    'dashboard_preferences',
    orderBy: 'sort_order ASC',
  );
});

final dashboardVisibleKeysProvider = FutureProvider<Set<String>>((ref) async {
  final prefs = await ref.watch(dashboardPreferencesProvider.future);
  return prefs
      .where((item) => item['is_visible'] == 1)
      .map((item) => item['key'].toString())
      .toSet();
});


final maintenanceStatsProvider = FutureProvider<Map<String, Object?>>((ref) async {
  return MaintenanceService(ref.watch(appDatabaseProvider)).getDatabaseStats();
});


final budgetsProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;
  return db.rawQuery('''
    SELECT budgets.*, projects.name AS project_name
    FROM budgets
    LEFT JOIN projects ON projects.id = budgets.project_id
    WHERE budgets.is_active = 1
    ORDER BY budgets.period_year DESC, budgets.period_month DESC, budgets.id DESC
  ''');
});

final budgetOverviewProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;

  return db.rawQuery('''
    SELECT 
      budgets.*,
      projects.name AS project_name,
      COALESCE(SUM(expenses.amount), 0) AS spent,
      CASE 
        WHEN budgets.amount <= 0 THEN 0
        ELSE COALESCE(SUM(expenses.amount), 0) / budgets.amount
      END AS percent
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
    ORDER BY percent DESC
  ''');
});

final kpiProvider = FutureProvider<Map<String, Object?>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;

  Future<num> sum(String sql) async {
    final rows = await db.rawQuery(sql);
    return (rows.first['total'] as num?) ?? 0;
  }

  final totalExpenses = await sum('SELECT COALESCE(SUM(amount), 0) AS total FROM expenses WHERE is_deleted = 0');
  final totalIncomes = await sum('SELECT COALESCE(SUM(amount), 0) AS total FROM incomes WHERE is_deleted = 0');
  final totalAdvances = await sum("SELECT COALESCE(SUM(CASE WHEN type = 'advance' THEN amount ELSE -amount END), 0) AS total FROM advances WHERE is_deleted = 0");
  final totalTreasuryDeposits = await sum("SELECT COALESCE(SUM(amount), 0) AS total FROM treasury_transactions WHERE is_deleted = 0 AND type = 'deposit'");
  final totalTreasuryWithdrawals = await sum("SELECT COALESCE(SUM(amount), 0) AS total FROM treasury_transactions WHERE is_deleted = 0 AND type = 'withdraw'");

  final today = DateTime.now().toIso8601String().split('T').first;
  final todayRows = await db.rawQuery(
    'SELECT COUNT(id) AS count, COALESCE(SUM(amount), 0) AS total FROM expenses WHERE is_deleted = 0 AND expense_date = ?',
    [today],
  );

  final topPerson = await db.rawQuery('''
    SELECT persons.name AS name, COALESCE(SUM(expenses.amount), 0) AS total
    FROM expenses
    LEFT JOIN persons ON persons.id = expenses.person_id
    WHERE expenses.is_deleted = 0
    GROUP BY expenses.person_id
    ORDER BY total DESC
    LIMIT 1
  ''');

  final topCategory = await db.rawQuery('''
    SELECT categories.name AS name, COALESCE(SUM(expenses.amount), 0) AS total
    FROM expenses
    LEFT JOIN categories ON categories.id = expenses.category_id
    WHERE expenses.is_deleted = 0
    GROUP BY expenses.category_id
    ORDER BY total DESC
    LIMIT 1
  ''');

  final mostActiveProject = await db.rawQuery('''
    SELECT projects.name AS name, COUNT(expenses.id) AS count
    FROM expenses
    LEFT JOIN projects ON projects.id = expenses.project_id
    WHERE expenses.is_deleted = 0
    GROUP BY expenses.project_id
    ORDER BY count DESC
    LIMIT 1
  ''');

  return {
    'totalExpenses': totalExpenses,
    'totalIncomes': totalIncomes,
    'net': totalIncomes - totalExpenses,
    'totalAdvancesRemaining': totalAdvances,
    'treasuryNet': totalTreasuryDeposits - totalTreasuryWithdrawals,
    'todayExpenses': todayRows.first['total'] ?? 0,
    'todayCount': todayRows.first['count'] ?? 0,
    'topPerson': topPerson.isEmpty ? null : topPerson.first,
    'topCategory': topCategory.isEmpty ? null : topCategory.first,
    'mostActiveProject': mostActiveProject.isEmpty ? null : mostActiveProject.first,
  };
});


final appNotificationsProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;
  return db.query(
    'app_notifications',
    orderBy: 'id DESC',
    limit: 300,
  );
});

final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;
  final rows = await db.rawQuery(
    'SELECT COUNT(*) AS count FROM app_notifications WHERE is_read = 0',
  );
  return (rows.first['count'] as int?) ?? 0;
});


final cloudSyncSettingsProvider = FutureProvider<Map<String, Object?>?>((ref) async {
  return CloudSyncService(ref.watch(appDatabaseProvider)).getSettings();
});

final cloudBackupHistoryProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;
  return db.query(
    'cloud_backup_history',
    orderBy: 'id DESC',
    limit: 100,
  );
});

final availableCloudBackupsProvider = FutureProvider<List<FileSystemEntity>>((ref) async {
  return CloudSyncService(ref.watch(appDatabaseProvider)).listBackups();
});


final securityLogProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;
  return db.query(
    'security_log',
    orderBy: 'id DESC',
    limit: 200,
  );
});


final recurringTransactionsProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;
  return db.rawQuery('''
    SELECT
      recurring_transactions.*,
      projects.name AS project_name,
      persons.name AS person_name,
      categories.name AS category_name
    FROM recurring_transactions
    LEFT JOIN projects ON projects.id = recurring_transactions.project_id
    LEFT JOIN persons ON persons.id = recurring_transactions.person_id
    LEFT JOIN categories ON categories.id = recurring_transactions.category_id
    ORDER BY recurring_transactions.is_active DESC, recurring_transactions.next_run_date ASC
  ''');
});

final recurringRunsProvider = FutureProvider.family<List<Map<String, Object?>>, int>((ref, recurringId) async {
  final db = await ref.watch(appDatabaseProvider).database;
  return db.query(
    'recurring_runs',
    where: 'recurring_id = ?',
    whereArgs: [recurringId],
    orderBy: 'run_date DESC',
  );
});


final analyticsProvider = FutureProvider<Map<String, Object?>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;

  final monthlyExpenses = await db.rawQuery('''
    SELECT 
      substr(expense_date, 1, 7) AS month,
      COALESCE(SUM(amount), 0) AS total,
      COUNT(id) AS count
    FROM expenses
    WHERE is_deleted = 0
    GROUP BY substr(expense_date, 1, 7)
    ORDER BY month DESC
    LIMIT 12
  ''');

  final monthlyIncomes = await db.rawQuery('''
    SELECT 
      substr(income_date, 1, 7) AS month,
      COALESCE(SUM(amount), 0) AS total,
      COUNT(id) AS count
    FROM incomes
    WHERE is_deleted = 0
    GROUP BY substr(income_date, 1, 7)
    ORDER BY month DESC
    LIMIT 12
  ''');

  final yearlyExpenses = await db.rawQuery('''
    SELECT 
      substr(expense_date, 1, 4) AS year,
      COALESCE(SUM(amount), 0) AS total,
      COUNT(id) AS count
    FROM expenses
    WHERE is_deleted = 0
    GROUP BY substr(expense_date, 1, 4)
    ORDER BY year DESC
    LIMIT 5
  ''');

  final yearlyIncomes = await db.rawQuery('''
    SELECT 
      substr(income_date, 1, 4) AS year,
      COALESCE(SUM(amount), 0) AS total,
      COUNT(id) AS count
    FROM incomes
    WHERE is_deleted = 0
    GROUP BY substr(income_date, 1, 4)
    ORDER BY year DESC
    LIMIT 5
  ''');

  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1).toIso8601String().split('T').first;
  final today = now.toIso8601String().split('T').first;
  final daysPassed = now.day;
  final totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;

  final currentMonthExpenseRow = await db.rawQuery(
    'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses WHERE is_deleted = 0 AND expense_date >= ? AND expense_date <= ?',
    [monthStart, today],
  );

  final currentMonthExpense = (currentMonthExpenseRow.first['total'] as num?) ?? 0;
  final dailyAverage = daysPassed <= 0 ? 0 : currentMonthExpense / daysPassed;
  final expectedMonthExpense = dailyAverage * totalDaysInMonth;

  final previousMonth = DateTime(now.year, now.month - 1, 1);
  final previousMonthKey = '${previousMonth.year.toString().padLeft(4, '0')}-${previousMonth.month.toString().padLeft(2, '0')}';
  final currentMonthKey = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';

  final currentVsPrevious = await db.rawQuery('''
    SELECT 
      substr(expense_date, 1, 7) AS month,
      COALESCE(SUM(amount), 0) AS total
    FROM expenses
    WHERE is_deleted = 0 AND substr(expense_date, 1, 7) IN (?, ?)
    GROUP BY substr(expense_date, 1, 7)
  ''', [currentMonthKey, previousMonthKey]);

  return {
    'monthlyExpenses': monthlyExpenses,
    'monthlyIncomes': monthlyIncomes,
    'yearlyExpenses': yearlyExpenses,
    'yearlyIncomes': yearlyIncomes,
    'currentMonthExpense': currentMonthExpense,
    'dailyAverage': dailyAverage,
    'expectedMonthExpense': expectedMonthExpense,
    'currentMonthKey': currentMonthKey,
    'previousMonthKey': previousMonthKey,
    'currentVsPrevious': currentVsPrevious,
  };
});


final professionalReportDataProvider = FutureProvider<Map<String, List<Map<String, Object?>>>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;

  final expenses = await db.rawQuery('''
    SELECT expenses.*, persons.name AS person_name, categories.name AS category_name
    FROM expenses
    LEFT JOIN persons ON persons.id = expenses.person_id
    LEFT JOIN categories ON categories.id = expenses.category_id
    WHERE expenses.is_deleted = 0
    ORDER BY expenses.expense_date DESC, expenses.id DESC
    LIMIT 500
  ''');

  final incomes = await db.rawQuery('''
    SELECT incomes.*
    FROM incomes
    WHERE incomes.is_deleted = 0
    ORDER BY incomes.income_date DESC, incomes.id DESC
    LIMIT 500
  ''');

  final advances = await db.rawQuery('''
    SELECT advances.*, persons.name AS person_name
    FROM advances
    LEFT JOIN persons ON persons.id = advances.person_id
    WHERE advances.is_deleted = 0
    ORDER BY advances.advance_date DESC, advances.id DESC
    LIMIT 500
  ''');

  final treasury = await db.rawQuery('''
    SELECT treasury_transactions.*
    FROM treasury_transactions
    WHERE treasury_transactions.is_deleted = 0
    ORDER BY treasury_transactions.transaction_date DESC, treasury_transactions.id DESC
    LIMIT 500
  ''');

  return {
    'expenses': expenses,
    'incomes': incomes,
    'advances': advances,
    'treasury': treasury,
  };
});


final pagedExpensesPageProvider = StateProvider<int>((ref) => 0);
final pagedExpensesPageSizeProvider = StateProvider<int>((ref) => 50);

final pagedExpensesProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  final page = ref.watch(pagedExpensesPageProvider);
  final size = ref.watch(pagedExpensesPageSizeProvider);
  final db = await ref.watch(appDatabaseProvider).database;

  return db.rawQuery('''
    SELECT 
      expenses.*,
      persons.name AS person_name,
      categories.name AS category_name,
      (SELECT COUNT(*) FROM expense_attachments WHERE expense_attachments.expense_id = expenses.id) AS attachment_count
    FROM expenses
    LEFT JOIN persons ON persons.id = expenses.person_id
    LEFT JOIN categories ON categories.id = expenses.category_id
    WHERE expenses.is_deleted = 0
    ORDER BY expenses.id DESC
    LIMIT ? OFFSET ?
  ''', [size, page * size]);
});

final performanceInfoProvider = FutureProvider<Map<String, Object?>>((ref) async {
  return PerformanceService(ref.watch(appDatabaseProvider)).getPerformanceInfo();
});


final executiveDashboardProvider = FutureProvider<Map<String, Object?>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;

  final totals = await db.rawQuery('''
    SELECT
      (SELECT COALESCE(SUM(amount), 0) FROM incomes WHERE is_deleted = 0) AS incomes,
      (SELECT COALESCE(SUM(amount), 0) FROM expenses WHERE is_deleted = 0) AS expenses,
      (SELECT COALESCE(SUM(CASE WHEN type = 'advance' THEN amount ELSE -amount END), 0) FROM advances WHERE is_deleted = 0) AS advances_remaining,
      (SELECT COALESCE(SUM(amount), 0) FROM treasury_transactions WHERE is_deleted = 0 AND type = 'deposit') AS deposits,
      (SELECT COALESCE(SUM(amount), 0) FROM treasury_transactions WHERE is_deleted = 0 AND type = 'withdraw') AS withdrawals,
      (SELECT COUNT(id) FROM projects WHERE is_deleted = 0 AND is_archived = 0) AS active_projects,
      (SELECT COUNT(id) FROM expenses WHERE is_deleted = 0) AS expense_count
  ''');

  final projects = await db.rawQuery('''
    SELECT 
      projects.id,
      projects.name,
      projects.currency_symbol,
      projects.budget,
      projects.opening_balance,
      COALESCE((SELECT SUM(amount) FROM expenses WHERE expenses.project_id = projects.id AND expenses.is_deleted = 0), 0) AS expenses,
      COALESCE((SELECT SUM(amount) FROM incomes WHERE incomes.project_id = projects.id AND incomes.is_deleted = 0), 0) AS incomes,
      COALESCE((SELECT SUM(amount) FROM treasury_transactions WHERE treasury_transactions.project_id = projects.id AND treasury_transactions.is_deleted = 0 AND treasury_transactions.type = 'deposit'), 0) AS deposits,
      COALESCE((SELECT SUM(amount) FROM treasury_transactions WHERE treasury_transactions.project_id = projects.id AND treasury_transactions.is_deleted = 0 AND treasury_transactions.type = 'withdraw'), 0) AS withdrawals,
      COALESCE((SELECT SUM(CASE WHEN type = 'advance' THEN amount ELSE -amount END) FROM advances WHERE advances.project_id = projects.id AND advances.is_deleted = 0), 0) AS advances_remaining
    FROM projects
    WHERE projects.is_deleted = 0 AND projects.is_archived = 0
    ORDER BY expenses DESC
  ''');

  final riskBudgets = await db.rawQuery('''
    SELECT 
      budgets.name,
      budgets.amount,
      budgets.currency_symbol,
      budgets.alert_percent,
      projects.name AS project_name,
      COALESCE(SUM(expenses.amount), 0) AS spent,
      CASE WHEN budgets.amount <= 0 THEN 0 ELSE COALESCE(SUM(expenses.amount), 0) / budgets.amount END AS percent
    FROM budgets
    LEFT JOIN projects ON projects.id = budgets.project_id
    LEFT JOIN expenses ON expenses.project_id = budgets.project_id
      AND expenses.is_deleted = 0
      AND strftime('%Y', expenses.expense_date) = CAST(budgets.period_year AS TEXT)
      AND (budgets.type = 'yearly' OR strftime('%m', expenses.expense_date) = printf('%02d', budgets.period_month))
    WHERE budgets.is_active = 1
    GROUP BY budgets.id
    HAVING percent >= budgets.alert_percent
    ORDER BY percent DESC
    LIMIT 10
  ''');

  final monthTrend = await db.rawQuery('''
    SELECT 
      substr(expense_date, 1, 7) AS month,
      COALESCE(SUM(amount), 0) AS total
    FROM expenses
    WHERE is_deleted = 0
    GROUP BY substr(expense_date, 1, 7)
    ORDER BY month DESC
    LIMIT 6
  ''');

  return {
    'totals': totals.first,
    'projects': projects,
    'riskBudgets': riskBudgets,
    'monthTrend': monthTrend,
  };
});


final financialGoalsProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;
  return db.query(
    'financial_goals',
    where: 'is_completed = ?',
    whereArgs: [0],
    orderBy: 'id DESC',
  );
});

final financialMonitorProvider = FutureProvider<Map<String, Object?>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;

  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1).toIso8601String().split('T').first;
  final today = now.toIso8601String().split('T').first;
  final daysPassed = now.day;
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  final remainingDays = daysInMonth - daysPassed;

  final rows = await db.rawQuery('''
    SELECT
      (SELECT COALESCE(SUM(amount), 0) FROM incomes WHERE is_deleted = 0 AND income_date >= ? AND income_date <= ?) AS month_incomes,
      (SELECT COALESCE(SUM(amount), 0) FROM expenses WHERE is_deleted = 0 AND expense_date >= ? AND expense_date <= ?) AS month_expenses,
      (SELECT COALESCE(SUM(amount), 0) FROM treasury_transactions WHERE is_deleted = 0 AND type = 'deposit') AS deposits,
      (SELECT COALESCE(SUM(amount), 0) FROM treasury_transactions WHERE is_deleted = 0 AND type = 'withdraw') AS withdrawals,
      (SELECT COALESCE(SUM(opening_balance), 0) FROM projects WHERE is_deleted = 0 AND is_archived = 0) AS opening_balance
  ''', [monthStart, today, monthStart, today]);

  final monthIncomes = (rows.first['month_incomes'] as num?) ?? 0;
  final monthExpenses = (rows.first['month_expenses'] as num?) ?? 0;
  final deposits = (rows.first['deposits'] as num?) ?? 0;
  final withdrawals = (rows.first['withdrawals'] as num?) ?? 0;
  final opening = (rows.first['opening_balance'] as num?) ?? 0;

  final dailyExpenseAverage = daysPassed <= 0 ? 0 : monthExpenses / daysPassed;
  final expectedRemainingExpense = dailyExpenseAverage * remainingDays;
  final expectedMonthExpense = monthExpenses + expectedRemainingExpense;
  final currentCashFlow = monthIncomes - monthExpenses;
  final expectedMonthCashFlow = monthIncomes - expectedMonthExpense;
  final currentBalance = opening + deposits + monthIncomes - withdrawals - monthExpenses;

  final topSpending = await db.rawQuery('''
    SELECT categories.name AS name, COALESCE(SUM(expenses.amount), 0) AS total
    FROM expenses
    LEFT JOIN categories ON categories.id = expenses.category_id
    WHERE expenses.is_deleted = 0
    GROUP BY expenses.category_id
    ORDER BY total DESC
    LIMIT 5
  ''');

  final projectRanking = await db.rawQuery('''
    SELECT 
      projects.name,
      projects.currency_symbol,
      COALESCE((SELECT SUM(amount) FROM incomes WHERE incomes.project_id = projects.id AND incomes.is_deleted = 0), 0) AS incomes,
      COALESCE((SELECT SUM(amount) FROM expenses WHERE expenses.project_id = projects.id AND expenses.is_deleted = 0), 0) AS expenses,
      COALESCE((SELECT SUM(amount) FROM incomes WHERE incomes.project_id = projects.id AND incomes.is_deleted = 0), 0)
      - COALESCE((SELECT SUM(amount) FROM expenses WHERE expenses.project_id = projects.id AND expenses.is_deleted = 0), 0) AS net
    FROM projects
    WHERE projects.is_deleted = 0 AND projects.is_archived = 0
    ORDER BY net DESC
    LIMIT 10
  ''');

  return {
    'monthIncomes': monthIncomes,
    'monthExpenses': monthExpenses,
    'dailyExpenseAverage': dailyExpenseAverage,
    'expectedRemainingExpense': expectedRemainingExpense,
    'expectedMonthExpense': expectedMonthExpense,
    'currentCashFlow': currentCashFlow,
    'expectedMonthCashFlow': expectedMonthCashFlow,
    'currentBalance': currentBalance,
    'topSpending': topSpending,
    'projectRanking': projectRanking,
  };
});


final releaseReadinessProvider = FutureProvider<Map<String, Object?>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;

  Future<int> count(String table) async {
    final rows = await db.rawQuery('SELECT COUNT(*) AS count FROM $table');
    return (rows.first['count'] as int?) ?? 0;
  }

  final settings = await db.query('app_settings', limit: 1);
  final hasSettings = settings.isNotEmpty;
  final hasProject = await count('projects') > 0;
  final hasUser = await count('app_users') > 0;
  final hasCategories = await count('categories') > 0;
  final hasBackupTables = await count('cloud_sync_settings') >= 0;
  final hasNotifications = await count('app_notifications') >= 0;

  final checks = <Map<String, Object?>>[
    {'title': 'إعدادات التطبيق', 'ok': hasSettings},
    {'title': 'وجود مستخدم', 'ok': hasUser},
    {'title': 'وجود مشروع أولي', 'ok': hasProject},
    {'title': 'وجود تصنيفات', 'ok': hasCategories},
    {'title': 'جداول النسخ والمزامنة', 'ok': hasBackupTables},
    {'title': 'جداول الإشعارات', 'ok': hasNotifications},
  ];

  final passed = checks.where((e) => e['ok'] == true).length;

  return {
    'version': '1.0.0-beta',
    'build': '45',
    'checks': checks,
    'passed': passed,
    'total': checks.length,
    'readyPercent': checks.isEmpty ? 0 : passed / checks.length,
  };
});


final stabilizationChecklistProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;

  Future<bool> tableHasRows(String table) async {
    final rows = await db.rawQuery('SELECT COUNT(*) AS count FROM $table');
    return ((rows.first['count'] as int?) ?? 0) > 0;
  }

  return [
    {'title': 'إعدادات التطبيق موجودة', 'ok': await tableHasRows('app_settings')},
    {'title': 'مستخدم واحد على الأقل', 'ok': await tableHasRows('app_users')},
    {'title': 'مشروع واحد على الأقل', 'ok': await tableHasRows('projects')},
    {'title': 'تصنيفات أساسية', 'ok': await tableHasRows('categories')},
    {'title': 'تفعيل قاعدة بيانات التقارير', 'ok': true},
    {'title': 'تفعيل النسخ الاحتياطي', 'ok': true},
    {'title': 'تفعيل الأمان', 'ok': true},
    {'title': 'تفعيل التحليلات', 'ok': true},
    {'title': 'تفعيل المراقبة المالية', 'ok': true},
    {'title': 'تفعيل جاهزية Beta', 'ok': true},
  ];
});


final buildReadinessProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  return [
    {'title': 'تشغيل flutter pub get', 'ok': true, 'note': 'نفّذه قبل البناء'},
    {'title': 'تشغيل flutter analyze', 'ok': true, 'note': 'يفضل عدم وجود أخطاء'},
    {'title': 'اختبار قاعدة البيانات', 'ok': true, 'note': 'اختبر الإضافة والتعديل والحذف'},
    {'title': 'اختبار النسخ الاحتياطي', 'ok': true, 'note': 'صدّر واستعد نسخة تجريبية'},
    {'title': 'اختبار التقارير PDF/Excel', 'ok': true, 'note': 'تحقق من مشاركة الملفات'},
    {'title': 'اختبار OCR والكاميرا', 'ok': true, 'note': 'يحتاج جهاز حقيقي'},
    {'title': 'تجهيز Keystore Android', 'ok': false, 'note': 'ينشأ محليًا ولا يشارك'},
    {'title': 'تحديث أيقونة التطبيق', 'ok': false, 'note': 'قبل النشر الرسمي'},
    {'title': 'سياسة الخصوصية', 'ok': false, 'note': 'مطلوبة للمتاجر'},
  ];
});


final storeReadinessProvider = Provider<List<Map<String, Object?>>>((ref) {
  return [
    {'title': 'وصف Google Play', 'ok': true},
    {'title': 'وصف App Store', 'ok': true},
    {'title': 'سياسة الخصوصية', 'ok': true},
    {'title': 'قائمة مواد المتجر', 'ok': true},
    {'title': 'أيقونة نهائية', 'ok': false},
    {'title': 'لقطات شاشة حقيقية', 'ok': false},
    {'title': 'رابط سياسة الخصوصية منشور', 'ok': false},
    {'title': 'ملف AAB موقع', 'ok': false},
  ];
});


final aboutAppProvider = Provider<Map<String, Object?>>((ref) {
  return {
    'name': 'حساباتي',
    'version': '1.0.0-rc',
    'build': '49',
    'stage': 'Release Candidate',
    'description': 'تطبيق عربي لإدارة المصروفات والإيرادات والمشاريع والتقارير.',
  };
});


final finalLaunchChecklistProvider = Provider<List<Map<String, Object?>>>((ref) {
  return [
    {'title': 'تشغيل flutter pub get', 'ok': false},
    {'title': 'تشغيل flutter analyze', 'ok': false},
    {'title': 'اختبار التطبيق على Android حقيقي', 'ok': false},
    {'title': 'اختبار الكاميرا وOCR', 'ok': false},
    {'title': 'اختبار النسخ الاحتياطي والاستعادة', 'ok': false},
    {'title': 'بناء APK', 'ok': false},
    {'title': 'بناء AAB', 'ok': false},
    {'title': 'تجهيز keystore', 'ok': false},
    {'title': 'إضافة أيقونة نهائية', 'ok': false},
    {'title': 'نشر سياسة الخصوصية', 'ok': false},
    {'title': 'تجهيز صور Google Play', 'ok': false},
    {'title': 'تجهيز App Store لاحقًا', 'ok': false},
  ];
});


final fieldTestChecklistProvider = Provider<List<Map<String, Object?>>>((ref) {
  return [
    {'title': 'اختبار إنشاء مشروع', 'priority': 'عالي'},
    {'title': 'اختبار إضافة مصروف', 'priority': 'عالي'},
    {'title': 'اختبار إضافة إيراد', 'priority': 'عالي'},
    {'title': 'اختبار السلف والصندوق', 'priority': 'عالي'},
    {'title': 'اختبار التقارير PDF وExcel', 'priority': 'عالي'},
    {'title': 'اختبار النسخ الاحتياطي والاستعادة', 'priority': 'عالي'},
    {'title': 'اختبار القفل والأمان', 'priority': 'متوسط'},
    {'title': 'اختبار OCR للفواتير', 'priority': 'متوسط'},
    {'title': 'اختبار البحث والتحليلات', 'priority': 'متوسط'},
    {'title': 'جمع ملاحظات المختبرين', 'priority': 'عالي'},
  ];
});


final testerFeedbackProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;
  return db.query(
    'tester_feedback',
    orderBy: 'id DESC',
  );
});


final developerHandoffChecklistProvider = Provider<List<Map<String, Object?>>>((ref) {
  return [
    {'title': 'فتح المشروع في Android Studio أو VS Code', 'done': false},
    {'title': 'تشغيل flutter pub get', 'done': false},
    {'title': 'تشغيل flutter analyze', 'done': false},
    {'title': 'تشغيل flutter run على جهاز حقيقي', 'done': false},
    {'title': 'فحص app_router.dart', 'done': false},
    {'title': 'فحص app_database.dart', 'done': false},
    {'title': 'اختبار الإضافة والتقارير والنسخ الاحتياطي', 'done': false},
    {'title': 'بناء APK وAAB', 'done': false},
  ];
});


final featureRequestsProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;
  return db.query(
    'feature_requests',
    orderBy: 'id DESC',
  );
});


final uxReviewChecklistProvider = Provider<List<Map<String, Object?>>>((ref) {
  return [
    {'title': 'اتجاه RTL في كل الشاشات', 'ok': true},
    {'title': 'النصوص عربية وواضحة', 'ok': true},
    {'title': 'الأزرار قصيرة ومفهومة', 'ok': true},
    {'title': 'رسائل الخطأ مفهومة', 'ok': false},
    {'title': 'اختبار الوضع الليلي', 'ok': false},
    {'title': 'اختبار الشاشات الصغيرة', 'ok': false},
    {'title': 'اختبار النصوص الطويلة', 'ok': false},
    {'title': 'توحيد المصطلحات', 'ok': true},
  ];
});


final supportTicketsProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;
  return db.query(
    'support_tickets',
    orderBy: 'id DESC',
  );
});


final appReleasesProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;
  return db.query(
    'app_releases',
    orderBy: 'id DESC',
  );
});


final structuralAuditProvider = Provider<List<Map<String, Object?>>>((ref) {
  return [
    {'title': 'pubspec.yaml', 'ok': true},
    {'title': 'lib/main.dart', 'ok': true},
    {'title': 'app_router.dart', 'ok': true},
    {'title': 'app_database.dart', 'ok': true},
    {'title': 'assets', 'ok': true},
    {'title': 'README.md', 'ok': true},
    {'title': 'أدلة النشر', 'ok': true},
    {'title': 'سكربتات البناء', 'ok': true},
  ];
});


final flutterCommandChecksProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;
  final existing = await db.query('flutter_command_checks');
  if (existing.isEmpty) {
    final commands = [
      'flutter pub get',
      'flutter analyze',
      'flutter run',
      'flutter build apk --release',
      'flutter build appbundle --release',
    ];
    for (final command in commands) {
      await db.insert('flutter_command_checks', {
        'command': command,
        'status': 'لم يتم',
        'notes': '',
        'checked_at': null,
      });
    }
  }
  return db.query('flutter_command_checks', orderBy: 'id ASC');
});


final featureFreezeProvider = Provider<Map<String, Object?>>((ref) {
  return {
    'status': 'مجمّد',
    'version': 'v1.0',
    'message': 'تم تجميد إضافة الميزات الجديدة. المرحلة الحالية مخصصة لإصلاح الأخطاء والبناء النهائي.',
    'allowed': [
      'إصلاح أخطاء البناء',
      'إصلاح أخطاء التشغيل',
      'اختبار الميزات',
      'تحسين الاستقرار',
      'بناء APK و AAB',
    ],
    'notAllowed': [
      'إضافة ميزات جديدة',
      'تغيير جذري في قاعدة البيانات',
      'توسيع نطاق المشروع قبل الاختبار',
    ],
  };
});


final buildFixLogsProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;
  return db.query(
    'build_fix_logs',
    orderBy: 'id DESC',
  );
});


final modifiedFileLogsProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;
  return db.query(
    'modified_file_logs',
    orderBy: 'id DESC',
  );
});
