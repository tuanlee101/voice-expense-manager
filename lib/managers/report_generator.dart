import '../services/database_service.dart';

class ReportGenerator {
  final DatabaseService _db;

  ReportGenerator(this._db);

  /// Generate period summary report (R5.1 - R5.2)
  Future<Map<String, dynamic>> generatePeriodReport({
    required DateTime from,
    required DateTime to,
  }) async {
    final total = await _db.getTotalExpense(from: from, to: to);
    final summary = await _db.getCategorySummary(from: from, to: to);

    final categoryTotals = <String, double>{};

    for (final row in summary) {
      final catTotal = (row['total'] as num).toDouble();
      categoryTotals[row['name'] as String] = catTotal;
    }

    // Sort categories by total descending
    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Top category
    final topCategory = sortedEntries.isNotEmpty ? sortedEntries.first : null;

    // Compare with previous period
    final periodDuration = to.difference(from);
    final prevFrom = from.subtract(periodDuration);
    final prevTo = from.subtract(const Duration(seconds: 1));
    final prevTotal = await _db.getTotalExpense(from: prevFrom, to: prevTo);

    double? changePercent;
    if (prevTotal > 0) {
      changePercent = ((total - prevTotal) / prevTotal) * 100;
    }

    return {
      'from': from,
      'to': to,
      'total': total,
      'expenseCount': summary.fold<int>(0, (sum, row) => sum + (row['count'] as int)),
      'categoryTotals': categoryTotals,
      'topCategory': topCategory?.key,
      'topCategoryAmount': topCategory?.value ?? 0,
      'topCategoryPercent': total > 0 && topCategory != null
          ? (topCategory.value / total * 100)
          : 0,
      'changePercent': changePercent,
      'previousTotal': prevTotal,
      'sortedCategories': sortedEntries.map((e) => {
        'name': e.key,
        'amount': e.value,
        'percent': total > 0 ? (e.value / total * 100) : 0,
      }).toList(),
    };
  }

  /// Generate category breakdown report (R5.3)
  Future<List<Map<String, dynamic>>> generateCategoryReport({
    required DateTime from,
    required DateTime to,
    int limit = 5,
  }) async {
    final summary = await _db.getCategorySummary(from: from, to: to);

    final result = <Map<String, dynamic>>[];
    for (final row in summary) {
      final total = (row['total'] as num).toDouble();
      if (total > 0) {
        result.add({
          'id': row['id'],
          'name': row['name'],
          'icon': row['icon'],
          'color': row['color'],
          'total': total,
          'count': row['count'],
        });
      }
    }

    // Sort by total descending and limit
    result.sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));
    return result.take(limit).toList();
  }

  /// Generate text summary for TTS (R5.2)
  Future<String> generateSummaryText({
    required DateTime from,
    required DateTime to,
    String language = 'vi',
  }) async {
    final report = await generatePeriodReport(from: from, to: to);
    final total = report['total'] as double;
    final count = report['expenseCount'] as int;
    final topCategory = report['topCategory'] as String?;
    final topPercent = report['topCategoryPercent'] as double;
    final change = report['changePercent'] as double?;

    if (total == 0) {
      return language == 'vi'
          ? 'Không có dữ liệu chi tiêu trong khoảng thời gian này.'
          : 'No expense data for this period.';
    }

    if (language == 'vi') {
      final sb = StringBuffer();
      sb.write('Tổng chi tiêu là ${_formatAmount(total)} đồng, với $count khoản. ');
      if (topCategory != null && topPercent > 0) {
        sb.write('Danh mục chiếm nhiều nhất là $topCategory với ${topPercent.toStringAsFixed(1)}%. ');
      }
      if (change != null) {
        final direction = change >= 0 ? 'tăng' : 'giảm';
        sb.write('So với kỳ trước, chi tiêu $direction ${change.abs().toStringAsFixed(1)}%.');
      }
      return sb.toString();
    } else {
      final sb = StringBuffer();
      sb.write('Total expenses are \$${total.toStringAsFixed(2)} with $count transactions. ');
      if (topCategory != null && topPercent > 0) {
        sb.write('The top category is $topCategory at ${topPercent.toStringAsFixed(1)}%. ');
      }
      if (change != null) {
        final direction = change >= 0 ? 'increased' : 'decreased';
        sb.write('Compared to last period, spending $direction by ${change.abs().toStringAsFixed(1)}%.');
      }
      return sb.toString();
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)} tỉ';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)} triệu';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)} nghìn';
    }
    return amount.toStringAsFixed(0);
  }
}
