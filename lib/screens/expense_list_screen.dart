import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  String? _filterCategoryId;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().refreshExpenses();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final expenses = _filterExpenses(appState.recentExpenses);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Lịch sử chi tiêu',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search and filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm...',
                    hintStyle:
                        TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    prefixIcon: Icon(Icons.search,
                        color: Colors.white.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 12),
                // Category filter chips
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('Tất cả', null),
                      ...appState.categories.map(
                        (cat) => _buildFilterChip(cat.name, cat.id),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Expense list
          Expanded(
            child: expenses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có chi tiêu nào',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      return _ExpenseCard(
                        expense: expenses[index],
                        categories: appState.categories,
                        onDelete: () => _deleteExpense(expenses[index].id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? categoryId) {
    final isSelected = _filterCategoryId == categoryId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filterCategoryId = categoryId),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF4CAF50)
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  List<Expense> _filterExpenses(List<Expense> expenses) {
    var filtered = expenses;

    if (_filterCategoryId != null) {
      filtered = filtered.where((e) => e.categoryId == _filterCategoryId).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((e) {
        return e.note.toLowerCase().contains(query) ||
            e.amount.toString().contains(query);
      }).toList();
    }

    return filtered;
  }

  Future<void> _deleteExpense(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Xoá khoản chi?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Khoản chi này sẽ bị xoá vĩnh viễn.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AppState>().expenseManager.deleteExpense(id);
      if (context.mounted) {
        context.read<AppState>().refreshExpenses();
      }
    }
  }
}

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  final List<ExpenseCategory> categories;
  final VoidCallback onDelete;

  const _ExpenseCard({
    required this.expense,
    required this.categories,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cat = categories.firstWhere(
      (c) => c.id == expense.categoryId,
      orElse: () => const ExpenseCategory(id: '', name: '?', isDefault: false),
    );
    final timeFormat = DateFormat('dd/MM HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(cat.color).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.circle, color: Color(cat.color), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cat.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (expense.note.isNotEmpty)
                  Text(
                    expense.note,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatAmount(expense.amount),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                timeFormat.format(expense.timestamp),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.delete_outline,
                size: 18, color: Colors.white.withValues(alpha: 0.3)),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}tr';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    }
    return amount.toStringAsFixed(0);
  }
}
