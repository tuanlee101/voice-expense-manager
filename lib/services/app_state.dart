import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/expense.dart';
import '../models/expense_category.dart';
import '../models/voice_command.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../managers/expense_manager.dart';
import '../managers/budget_manager.dart';
import '../managers/category_manager.dart';
import '../managers/report_generator.dart';
import '../voice/voice_input_module.dart';
import '../voice/speech_recognition_engine.dart';
import '../voice/nlp_processor.dart';
import '../voice/tts_engine.dart';

class AppState extends ChangeNotifier {
  late final DatabaseService databaseService;
  late final AuthService authService;
  late final SyncService syncService;
  late final ExpenseManager expenseManager;
  late final BudgetManager budgetManager;
  late final CategoryManager categoryManager;
  late final ReportGenerator reportGenerator;
  late final VoiceInputModule voiceInput;
  late final SpeechRecognitionEngine speechEngine;
  late final NLPProcessor nlpProcessor;
  late final TTSEngine ttsEngine;

  // UI State
  bool _isInitialized = false;
  String _currentLanguage = 'vi';
  double _ttsSpeed = 1.0;
  List<ExpenseCategory> _categories = [];
  List<Expense> _recentExpenses = [];
  String? _lastFeedback;

  // Auth state
  bool _isAuthenticated = false;
  bool _darkMode = false;
  double _budgetRemaining = 0;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _isAuthenticated;
  bool get darkMode => _darkMode;
  String get currentLanguage => _currentLanguage;
  double get ttsSpeed => _ttsSpeed;
  double get budgetRemaining => _budgetRemaining;
  List<ExpenseCategory> get categories => _categories;
  List<Expense> get recentExpenses => _recentExpenses;
  String? get lastFeedback => _lastFeedback;

  set isAuthenticated(bool val) {
    _isAuthenticated = val;
    notifyListeners();
  }

  set darkMode(bool val) {
    _darkMode = val;
    notifyListeners();
  }

  /// Convenience: total expense today
  double getTotalToday() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return _recentExpenses
        .where((e) => e.timestamp.isAfter(todayStart) && e.amount < 0)
        .fold(0.0, (sum, e) => sum + e.amount.abs());
  }

  /// Convenience: total expense this month
  double getTotalThisMonth() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    return _recentExpenses
        .where((e) => e.timestamp.isAfter(monthStart) && e.amount < 0)
        .fold(0.0, (sum, e) => sum + e.amount.abs());
  }

  /// Get category by id
  ExpenseCategory? getCategory(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Refresh all data from DB
  Future<void> refreshData() async {
    _categories = await categoryManager.getCategories();
    _recentExpenses = await expenseManager.queryExpenses(limit: 20);
    notifyListeners();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    databaseService = DatabaseService();
    authService = AuthService();
    syncService = SyncService(databaseService);

    // Managers
    expenseManager = ExpenseManager(databaseService);
    budgetManager = BudgetManager(databaseService);
    categoryManager = CategoryManager(databaseService);
    reportGenerator = ReportGenerator(databaseService);

    // Voice modules
    speechEngine = SpeechRecognitionEngine();
    nlpProcessor = NLPProcessor();
    ttsEngine = TTSEngine();

    voiceInput = VoiceInputModule(
      speechEngine: speechEngine,
      nlpProcessor: nlpProcessor,
      ttsEngine: ttsEngine,
    );

    // Initialize voice
    await speechEngine.initialize();
    await ttsEngine.initialize(language: 'vi-VN');

    // Load settings
    await _loadSettings();

    // Load categories
    _categories = await categoryManager.getCategories();

    // Sync service
    await syncService.initialize();

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language') ?? 'vi';
    _ttsSpeed = prefs.getDouble('tts_speed') ?? 1.0;
    ttsEngine.speechRate = _ttsSpeed;
    voiceInput.currentLanguage =
        _currentLanguage == 'vi' ? 'vi-VN' : 'en-US';
  }

  Future<void> setLanguage(String lang) async {
    _currentLanguage = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    voiceInput.currentLanguage = lang == 'vi' ? 'vi-VN' : 'en-US';
    ttsEngine.setLanguage(lang == 'vi' ? 'vi-VN' : 'en-US');
    notifyListeners();
  }

  Future<void> setTtsSpeed(double speed) async {
    _ttsSpeed = speed;
    ttsEngine.speechRate = speed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_speed', speed);
    notifyListeners();
  }

  // ========== VOICE COMMAND HANDLING ==========

  Future<String> handleVoiceCommand(VoiceCommand command) async {
    if (command.intent == null) {
      return _currentLanguage == 'vi'
          ? 'Không hiểu yêu cầu của bạn'
          : 'I didn\'t understand your request';
    }

    switch (command.intent) {
      case 'add_expense':
        return _handleAddExpense(command);
      case 'query_expense':
        return _handleQueryExpense(command);
      case 'set_budget':
        return _handleSetBudget(command);
      case 'query_budget':
        return _handleQueryBudget(command);
      case 'view_report':
        return _handleViewReport(command);
      case 'create_category':
        return _handleCreateCategory(command);
      case 'rename_category':
        return _handleRenameCategory(command);
      case 'delete_category':
        return _handleDeleteCategory(command);
      default:
        return _currentLanguage == 'vi'
            ? 'Tính năng này chưa được hỗ trợ'
            : 'This feature is not yet supported';
    }
  }

  Future<String> _handleAddExpense(VoiceCommand command) async {
    final amount = command.get<double>('amount');
    if (amount == null) {
      return _currentLanguage == 'vi'
          ? 'Bạn chi bao nhiêu tiền?'
          : 'How much did you spend?';
    }

    String? categoryName = command.get<String>('category_name');
    ExpenseCategory? category;

    if (categoryName != null) {
      category = await categoryManager.getByName(categoryName);
    }

    if (category == null) {
      // Suggest categories
      final suggestions = NLPProcessor.suggestCategories(
        command.rawText,
        language: _currentLanguage,
      );
      if (suggestions.isNotEmpty) {
        final name = suggestions.first;
        category = await categoryManager.getByName(name);
      }
    }

    category ??= (await categoryManager.getCategories())
        .firstWhere((c) => c.name == 'Khác',
            orElse: () => const ExpenseCategory(
                id: 'default_other', name: 'Khác', isDefault: true));

    final note = command.get<String>('note') ?? '';
    final timestamp = command.get<DateTime>('time_reference');

    await expenseManager.addExpense(
      amount: amount,
      categoryId: category.id,
      note: note,
      timestamp: timestamp,
    );

    // Check budget alert
    final expense = Expense(
      id: '',
      amount: amount,
      categoryId: category.id,
      note: note,
      timestamp: timestamp ?? DateTime.now(),
    );
    final alert = await budgetManager.checkBudgetAlert(expense);

    _recentExpenses = await expenseManager.queryExpenses(limit: 10);
    notifyListeners();

    final vi =
        'Đã ghi nhận: ${_formatAmount(amount)} đồng cho mục ${category.name}${note.isNotEmpty ? ", ghi chú: $note" : ""}.${alert != null ? " $alert" : ""}';
    final en =
        'Recorded: \$${amount.toStringAsFixed(2)} for ${category.name}${note.isNotEmpty ? ", note: $note" : ""}.${alert != null ? " $alert" : ""}';
    return _currentLanguage == 'vi' ? vi : en;
  }

  Future<String> _handleQueryExpense(VoiceCommand command) async {
    final timeRef = command.get<DateTime>('time_reference');
    Map<String, DateTime> range;

    if (timeRef != null) {
      range = NLPProcessor.resolveTimeRange(timeRef);
    } else {
      // Default to today
      final now = DateTime.now();
      range = {
        'from': DateTime(now.year, now.month, now.day),
        'to': DateTime(now.year, now.month, now.day, 23, 59, 59),
      };
    }

    final categoryName = command.get<String>('category_name');
    ExpenseCategory? category;
    if (categoryName != null) {
      category = await categoryManager.getByName(categoryName);
    }

    final expenses = await expenseManager.queryExpenses(
      categoryId: category?.id,
      from: range['from'],
      to: range['to'],
    );

    if (expenses.isEmpty) {
      return _currentLanguage == 'vi'
          ? 'Không có khoản chi tiêu nào trong khoảng thời gian này.'
          : 'No expenses found in this period.';
    }

    final total =
        expenses.fold<double>(0, (sum, e) => sum + e.amount);

    if (_currentLanguage == 'vi') {
      if (expenses.length <= 5) {
        final sb = StringBuffer();
        for (final e in expenses) {
          final cat = _categories.firstWhere((c) => c.id == e.categoryId,
              orElse: () => const ExpenseCategory(
                  id: '', name: 'Unknown', isDefault: false));
          sb.writeln(
              '${e.timestamp.hour.toString().padLeft(2, '0')}:${e.timestamp.minute.toString().padLeft(2, '0')} - ${_formatAmount(e.amount)} - ${cat.name}');
        }
        sb.write(
            'Tổng cộng ${expenses.length} khoản, ${_formatAmount(total)} đồng.');
        return sb.toString();
      } else {
        return 'Có ${expenses.length} khoản chi tiêu, tổng ${_formatAmount(total)} đồng.';
      }
    } else {
      if (expenses.length <= 5) {
        final sb = StringBuffer();
        for (final e in expenses) {
          final cat = _categories.firstWhere((c) => c.id == e.categoryId,
              orElse: () => const ExpenseCategory(
                  id: '', name: 'Unknown', isDefault: false));
          sb.writeln(
              '${e.timestamp.hour.toString().padLeft(2, '0')}:${e.timestamp.minute.toString().padLeft(2, '0')} - \$${e.amount.toStringAsFixed(2)} - ${cat.name}');
        }
        sb.write(
            'Total ${expenses.length} transactions, \$${total.toStringAsFixed(2)}.');
        return sb.toString();
      } else {
        return '${expenses.length} transactions found, total \$${total.toStringAsFixed(2)}.';
      }
    }
  }

  Future<String> _handleSetBudget(VoiceCommand command) async {
    final amount = command.get<double>('amount');
    if (amount == null) {
      return _currentLanguage == 'vi'
          ? 'Bạn muốn đặt ngân sách bao nhiêu?'
          : 'How much budget do you want to set?';
    }

    String? categoryName = command.get<String>('category_name');
    if (categoryName == null) {
      return _currentLanguage == 'vi'
          ? 'Cho danh mục nào?'
          : 'For which category?';
    }

    final category = await categoryManager.getByName(categoryName);
    if (category == null) {
      return _currentLanguage == 'vi'
          ? 'Không tìm thấy danh mục "$categoryName"'
          : 'Category "$categoryName" not found';
    }

    try {
      await budgetManager.setBudget(
        categoryId: category.id,
        amount: amount,
      );
      return _currentLanguage == 'vi'
          ? 'Đã đặt ngân sách ${_formatAmount(amount)} đồng cho mục ${category.name}.'
          : 'Budget of \$${amount.toStringAsFixed(2)} set for ${category.name}.';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String> _handleQueryBudget(VoiceCommand command) async {
    String? categoryName = command.get<String>('category_name');
    if (categoryName == null) {
      return _currentLanguage == 'vi'
          ? 'Bạn muốn xem ngân sách của danh mục nào?'
          : 'Which category budget do you want to see?';
    }

    final category = await categoryManager.getByName(categoryName);
    if (category == null) {
      return _currentLanguage == 'vi'
          ? 'Không tìm thấy danh mục "$categoryName"'
          : 'Category "$categoryName" not found';
    }

    final status = await budgetManager.queryBudget(category.id);
    if (!status['exists']) {
      return _currentLanguage == 'vi'
          ? 'Chưa có ngân sách cho mục ${category.name}. Bạn có muốn thiết lập không?'
          : 'No budget set for ${category.name}. Would you like to set one?';
    }

    final spent = status['spent'] as double;
    final remaining = status['remaining'] as double;
    final percentage = status['percentage'] as double;

    if (_currentLanguage == 'vi') {
      return 'Ngân sách ${category.name}: đã dùng ${_formatAmount(spent)}/${_formatAmount(status['budget'].amount)}, '
          'còn ${_formatAmount(remaining)} (${percentage.toStringAsFixed(0)}%).';
    } else {
      return 'Budget for ${category.name}: spent \$${spent.toStringAsFixed(2)}/\$${(status['budget'].amount as double).toStringAsFixed(2)}, '
          'remaining \$${remaining.toStringAsFixed(2)} (${percentage.toStringAsFixed(0)}%).';
    }
  }

  Future<String> _handleViewReport(VoiceCommand command) async {
    final timeRef = command.get<DateTime>('time_reference');
    Map<String, DateTime> range;

    if (timeRef != null) {
      range = NLPProcessor.resolveTimeRange(timeRef);
    } else {
      final now = DateTime.now();
      range = {
        'from': DateTime(now.year, now.month, 1),
        'to': DateTime(now.year, now.month, now.day, 23, 59, 59),
      };
    }

    // Also trigger UI chart update
    notifyListeners();

    return reportGenerator.generateSummaryText(
      from: range['from']!,
      to: range['to']!,
      language: _currentLanguage,
    );
  }

  Future<String> _handleCreateCategory(VoiceCommand command) async {
    final note = command.get<String>('note') ?? '';
    final name = note.isNotEmpty ? note : command.rawText;

    // Try to extract category name from text
    String catName = name;
    for (final prefix in ['tạo danh mục', 'thêm danh mục', 'tạo mục', 'thêm mục']) {
      if (catName.toLowerCase().contains(prefix)) {
        catName = catName.substring(catName.toLowerCase().indexOf(prefix) + prefix.length).trim();
        break;
      }
    }

    if (catName.isEmpty) {
      return _currentLanguage == 'vi'
          ? 'Bạn muốn tạo danh mục tên gì?'
          : 'What name for the new category?';
    }

    try {
      final cat = await categoryManager.createCategory(catName);
      _categories = await categoryManager.getCategories();
      notifyListeners();
      return _currentLanguage == 'vi'
          ? 'Đã tạo danh mục "${cat.name}" thành công.'
          : 'Category "${cat.name}" created successfully.';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String> _handleRenameCategory(VoiceCommand command) async {
    return _currentLanguage == 'vi'
        ? 'Vui lòng chọn danh mục cần đổi tên trên màn hình.'
        : 'Please select the category to rename on screen.';
  }

  Future<String> _handleDeleteCategory(VoiceCommand command) async {
    return _currentLanguage == 'vi'
        ? 'Vui lòng chọn danh mục cần xoá trên màn hình.'
        : 'Please select the category to delete on screen.';
  }

  Future<void> refreshExpenses() async {
    _recentExpenses = await expenseManager.queryExpenses(limit: 20);
    notifyListeners();
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

  @override
  void dispose() {
    voiceInput.dispose();
    syncService.dispose();
    super.dispose();
  }
}
