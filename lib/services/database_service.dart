import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../models/budget.dart';

class DatabaseService {
  static Database? _db;
  static const String _dbName = 'voice_expense_manager.db';
  static const int _dbVersion = 1;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'VND',
        category_id TEXT NOT NULL,
        note TEXT DEFAULT '',
        timestamp TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE COLLATE NOCASE,
        is_default INTEGER NOT NULL DEFAULT 0,
        icon TEXT DEFAULT 'category',
        color INTEGER DEFAULT 0xFF4CAF50
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        amount REAL NOT NULL,
        period TEXT NOT NULL DEFAULT 'month',
        start_date TEXT NOT NULL,
        end_date TEXT,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        action TEXT NOT NULL,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        data TEXT,
        created_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0
      )
    ''');

    // Insert default categories
    for (final cat in ExpenseCategory.defaultCategories) {
      await db.insert('categories', cat.toMap());
    }
  }

  // ========== EXPENSES ==========

  Future<List<Expense>> getExpenses({
    String? categoryId,
    DateTime? from, DateTime? to,
    double? minAmount, double? maxAmount,
    int limit = 100, int offset = 0,
    bool orderDesc = true,
  }) async {
    final db = await database;
    final conditions = <String>[];
    final params = <dynamic>[];

    if (categoryId != null) {
      conditions.add('category_id = ?');
      params.add(categoryId);
    }
    if (from != null) {
      conditions.add('timestamp >= ?');
      params.add(from.toIso8601String());
    }
    if (to != null) {
      conditions.add('timestamp <= ?');
      params.add(to.toIso8601String());
    }
    if (minAmount != null) {
      conditions.add('amount >= ?');
      params.add(minAmount);
    }
    if (maxAmount != null) {
      conditions.add('amount <= ?');
      params.add(maxAmount);
    }

    final where = conditions.isEmpty ? null : conditions.join(' AND ');
    final orderBy = 'timestamp ${orderDesc ? "DESC" : "ASC"}';

    final result = await db.query(
      'expenses',
      where: where,
      whereArgs: params.isNotEmpty ? params : null,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    return result.map((m) => Expense.fromMap(m)).toList();
  }

  Future<Expense?> getExpense(String id) async {
    final db = await database;
    final result = await db.query('expenses', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Expense.fromMap(result.first);
  }

  Future<void> insertExpense(Expense expense) async {
    final db = await database;
    await db.insert('expenses', expense.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateExpense(Expense expense) async {
    final db = await database;
    await db.update('expenses', expense.toMap(),
        where: 'id = ?', whereArgs: [expense.id]);
  }

  Future<void> deleteExpense(String id) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalExpense({DateTime? from, DateTime? to, String? categoryId}) async {
    final db = await database;
    final conditions = <String>[];
    final params = <dynamic>[];

    if (from != null) {
      conditions.add('timestamp >= ?');
      params.add(from.toIso8601String());
    }
    if (to != null) {
      conditions.add('timestamp <= ?');
      params.add(to.toIso8601String());
    }
    if (categoryId != null) {
      conditions.add('category_id = ?');
      params.add(categoryId);
    }

    final where = conditions.isEmpty ? null : conditions.join(' AND ');
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM expenses${where != null ? " WHERE $where" : ""}',
      params.isNotEmpty ? params : null,
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<List<Map<String, dynamic>>> getCategorySummary({
    required DateTime from, required DateTime to,
  }) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT c.id, c.name, c.icon, c.color,
             COALESCE(SUM(e.amount), 0) as total,
             COUNT(e.id) as count
      FROM categories c
      LEFT JOIN expenses e ON c.id = e.category_id
          AND e.timestamp >= ? AND e.timestamp <= ?
      GROUP BY c.id
      ORDER BY total DESC
    ''', [from.toIso8601String(), to.toIso8601String()]);
    return result;
  }

  // ========== CATEGORIES ==========

  Future<List<ExpenseCategory>> getCategories() async {
    final db = await database;
    final result = await db.query('categories', orderBy: 'is_default DESC, name ASC');
    return result.map((m) => ExpenseCategory.fromMap(m)).toList();
  }

  Future<ExpenseCategory?> getCategory(String id) async {
    final db = await database;
    final result = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return ExpenseCategory.fromMap(result.first);
  }

  Future<ExpenseCategory?> getCategoryByName(String name) async {
    final db = await database;
    final result = await db.query('categories',
        where: 'name = ? COLLATE NOCASE', whereArgs: [name]);
    if (result.isEmpty) return null;
    return ExpenseCategory.fromMap(result.first);
  }

  Future<void> insertCategory(ExpenseCategory category) async {
    final db = await database;
    await db.insert('categories', category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<void> updateCategory(ExpenseCategory category) async {
    final db = await database;
    await db.update('categories', category.toMap(),
        where: 'id = ?', whereArgs: [category.id]);
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    // Move expenses to 'Không phân loại'
    await db.update('expenses', {'category_id': ExpenseCategory.uncategorizedId},
        where: 'category_id = ?', whereArgs: [id]);
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ========== BUDGETS ==========

  Future<List<Budget>> getBudgets() async {
    final db = await database;
    final result = await db.query('budgets');
    return result.map((m) => Budget.fromMap(m)).toList();
  }

  Future<Budget?> getBudget(String categoryId, String period) async {
    final db = await database;
    final result = await db.query('budgets',
        where: 'category_id = ? AND period = ?',
        whereArgs: [categoryId, period]);
    if (result.isEmpty) return null;
    return Budget.fromMap(result.first);
  }

  Future<void> insertBudget(Budget budget) async {
    final db = await database;
    await db.insert('budgets', budget.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteBudget(String id) async {
    final db = await database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  // ========== SYNC QUEUE ==========

  Future<void> addSyncQueue(String action, String table, String recordId,
      {Map<String, dynamic>? data}) async {
    final db = await database;
    await db.insert('sync_queue', {
      'id': '${DateTime.now().millisecondsSinceEpoch}_$recordId',
      'action': action,
      'table_name': table,
      'record_id': recordId,
      'data': data?.toString(),
      'created_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getSyncQueue({int limit = 1000}) async {
    final db = await database;
    return db.query('sync_queue', limit: limit, orderBy: 'created_at ASC');
  }

  Future<void> clearSyncQueue() async {
    final db = await database;
    await db.delete('sync_queue');
  }

  // ========== EXPORT / IMPORT ==========

  Future<String> exportToCsv() async {
    final expenses = await getExpenses(limit: 100000);
    final buffer = StringBuffer();
    buffer.writeln('id,amount,currency,category,note,timestamp');

    for (final e in expenses) {
      final cat = await getCategory(e.categoryId);
      buffer.writeln(
          '${e.id},${e.amount.toStringAsFixed(2)},${e.currency},"${cat?.name ?? "Unknown"}","${e.note.replaceAll('"', '""')}",${e.timestamp.toIso8601String()}');
    }
    return buffer.toString();
  }

  Future<void> importFromCsv(String csvContent) async {
    final lines = csvContent.trim().split('\n');
    if (lines.isEmpty) return;
    // Skip header
    for (int i = 1; i < lines.length; i++) {
      final parts = _parseCsvLine(lines[i]);
      if (parts.length < 6) continue;

      final categoryName = parts[3];
      ExpenseCategory? cat = await getCategoryByName(categoryName);
      if (cat == null) {
        // Create category if not exists
        cat = ExpenseCategory(
          id: 'imported_${parts[0]}',
          name: categoryName,
        );
        await insertCategory(cat);
      }

      final expense = Expense(
        id: parts[0],
        amount: double.tryParse(parts[1]) ?? 0,
        currency: parts[2],
        categoryId: cat.id,
        note: parts[4],
        timestamp: DateTime.parse(parts[5]),
      );
      await insertExpense(expense);
    }
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    bool inQuotes = false;
    final current = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString());
        current.clear();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString());
    return result;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _db = null;
  }
}
