import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../services/database_service.dart';

class ExpenseManager {
  final DatabaseService _db;
  final Uuid _uuid = Uuid();

  ExpenseManager(this._db);

  /// Add a new expense
  Future<Expense> addExpense({
    required double amount,
    required String categoryId,
    String note = '',
    String currency = 'VND',
    DateTime? timestamp,
  }) async {
    final expense = Expense(
      id: _uuid.v4(),
      amount: amount,
      currency: currency,
      categoryId: categoryId,
      note: note,
      timestamp: timestamp ?? DateTime.now(),
    );

    await _db.insertExpense(expense);
    await _db.addSyncQueue('create', 'expenses', expense.id);
    return expense;
  }

  /// Get expenses with filters
  Future<List<Expense>> queryExpenses({
    String? categoryId,
    DateTime? from,
    DateTime? to,
    double? minAmount,
    double? maxAmount,
    int limit = 100,
  }) async {
    return _db.getExpenses(
      categoryId: categoryId,
      from: from,
      to: to,
      minAmount: minAmount,
      maxAmount: maxAmount,
      limit: limit,
    );
  }

  /// Get total for a period (optionally by category)
  Future<double> getTotal({
    DateTime? from,
    DateTime? to,
    String? categoryId,
  }) async {
    return _db.getTotalExpense(from: from, to: to, categoryId: categoryId);
  }

  /// Update an expense
  Future<void> updateExpense(Expense expense) async {
    await _db.updateExpense(expense);
    await _db.addSyncQueue('update', 'expenses', expense.id);
  }

  /// Delete an expense
  Future<void> deleteExpense(String id) async {
    await _db.deleteExpense(id);
    await _db.addSyncQueue('delete', 'expenses', id);
  }
}
