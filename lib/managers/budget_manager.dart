import 'package:uuid/uuid.dart';
import '../models/budget.dart';
import '../models/expense.dart';
import '../services/database_service.dart';

class BudgetManager {
  final DatabaseService _db;
  final Uuid _uuid = Uuid();

  BudgetManager(this._db);

  /// Get period boundaries for budget check
  Map<String, DateTime> _getPeriodRange(String period, DateTime from) {
    final now = DateTime.now();
    switch (period) {
      case 'day':
        return {
          'from': DateTime(now.year, now.month, now.day),
          'to': DateTime(now.year, now.month, now.day, 23, 59, 59),
        };
      case 'week':
        final monday = now.subtract(Duration(days: now.weekday - 1));
        return {
          'from': DateTime(monday.year, monday.month, monday.day),
          'to': DateTime(now.year, now.month, now.day, 23, 59, 59),
        };
      case 'month':
        return {
          'from': DateTime(now.year, now.month, 1),
          'to': DateTime(now.year, now.month, now.day, 23, 59, 59),
        };
      case 'year':
        return {
          'from': DateTime(now.year, 1, 1),
          'to': DateTime(now.year, now.month, now.day, 23, 59, 59),
        };
      default:
        return {
          'from': DateTime(now.year, now.month, 1),
          'to': DateTime(now.year, now.month, now.day, 23, 59, 59),
        };
    }
  }

  /// Set a budget (R4.1)
  Future<Budget> setBudget({
    required String categoryId,
    required double amount,
    String period = 'month',
  }) async {
    if (amount <= 0 || amount > 999999999.99) {
      throw ArgumentError('Số tiền không hợp lệ. Vui lòng nhập từ 0.01 đến 999,999,999.99');
    }

    final existing = await _db.getBudget(categoryId, period);
    final now = DateTime.now();

    final budget = Budget(
      id: existing?.id ?? _uuid.v4(),
      categoryId: categoryId,
      amount: amount,
      period: period,
      startDate: now,
    );

    await _db.insertBudget(budget);
    return budget;
  }

  /// Check budget status after adding an expense (R4.4 - R4.6)
  Future<String?> checkBudgetAlert(Expense expense) async {
    final budgets = await _db.getBudgets();
    String? lastAlert;

    for (final budget in budgets) {
      if (budget.categoryId != expense.categoryId) continue;

      final range = _getPeriodRange(budget.period, budget.startDate);
      final total = await _db.getTotalExpense(
        from: range['from'],
        to: range['to'],
        categoryId: budget.categoryId,
      );

      final percentage = (total / budget.amount) * 100;

      if (percentage >= 100) {
        lastAlert = 'Đã vượt ngân sách! ${budget.period == 'month' ? 'Tháng' : 'Kỳ'} này đã chi '
            '${total.toStringAsFixed(0)}đ, vượt ${(total - budget.amount).toStringAsFixed(0)}đ so với '
            'hạn mức ${budget.amount.toStringAsFixed(0)}đ.';
      } else if (percentage >= 80) {
        final remaining = budget.amount - total;
        lastAlert = 'Cảnh báo: Đã sử dụng ${percentage.toStringAsFixed(0)}% ngân sách. '
            'Còn ${remaining.toStringAsFixed(0)}đ trong hạn mức ${budget.amount.toStringAsFixed(0)}đ.';
      }
    }

    return lastAlert;
  }

  /// Query budget status (R4.7)
  Future<Map<String, dynamic>> queryBudget(String categoryId) async {
    final budget = await _db.getBudget(categoryId, 'month');
    if (budget == null) {
      return {'exists': false};
    }

    final range = _getPeriodRange(budget.period, budget.startDate);
    final total = await _db.getTotalExpense(
      from: range['from'],
      to: range['to'],
      categoryId: categoryId,
    );

    final remaining = budget.amount - total;
    final percentage = (total / budget.amount) * 100;

    return {
      'exists': true,
      'budget': budget,
      'spent': total,
      'remaining': remaining > 0 ? remaining : 0,
      'percentage': percentage.clamp(0, 100),
      'isOver': total > budget.amount,
    };
  }

  /// Delete a budget
  Future<void> deleteBudget(String id) async {
    await _db.deleteBudget(id);
  }
}
