import '../models/voice_command.dart';

class NLPProcessor {
  // ========== INTENT MAPPING ==========

  static const Map<String, List<String>> _intentPatternsVi = {
    'add_expense': [
      'chi', 'mua', 'trả', 'thanh toán', 'tiêu', 'tiền', 'đóng',
      'tốn', 'hết', 'mất', 'nạp', 'chuyển', 'đưa',
    ],
    'query_expense': [
      'xem', 'kiểm tra', 'tra', 'tổng', 'bao nhiêu', 'hết bao',
      'đã tiêu', 'đã chi', 'danh sách', 'liệt kê', 'cho tôi xem',
      'tuần này', 'tháng này', 'hôm nay', 'hôm qua',
    ],
    'set_budget': [
      'đặt ngân sách', 'giới hạn', 'hạn mức', 'budget',
      'cài ngân sách', 'thiết lập ngân sách',
    ],
    'query_budget': [
      'ngân sách', 'còn bao nhiêu', 'hạn mức còn', 'budget còn',
      'ngân sách còn',
    ],
    'view_report': [
      'báo cáo', 'thống kê', 'tổng kết', 'report', 'biểu đồ',
      'tổng quan',
    ],
    'create_category': [
      'tạo danh mục', 'thêm danh mục', 'tạo mục', 'mới mục',
      'thêm mục',
    ],
    'rename_category': [
      'đổi tên', 'sửa tên', 'rename',
    ],
    'delete_category': [
      'xóa danh mục', 'xoá danh mục', 'xóa mục', 'xoá mục',
    ],
  };

  static const Map<String, List<String>> _intentPatternsEn = {
    'add_expense': [
      'spent', 'paid', 'bought', 'purchase', 'pay', 'cost',
      'expense', 'add', 'spend',
    ],
    'query_expense': [
      'show', 'list', 'view', 'how much', 'total', 'spent on',
      'expenses for', 'transactions', 'find',
    ],
    'set_budget': [
      'set budget', 'limit', 'budget for', 'set limit',
    ],
    'query_budget': [
      'budget left', 'budget remaining', 'budget status',
      'how\'s my budget',
    ],
    'view_report': [
      'report', 'summary', 'overview', 'analytics', 'chart',
    ],
    'create_category': [
      'create category', 'add category', 'new category',
    ],
    'rename_category': [
      'rename', 'rename category',
    ],
    'delete_category': [
      'delete category', 'remove category',
    ],
  };

  // ========== AMOUNT PATTERNS ==========

  static final RegExp _amountViPattern = RegExp(
    r'(\d+[.,]?\d*)\s*(k|nghìn|tr|triệu|m|chục triệu|tỉ|tỷ|usd|\$|vnd|đồng|đ)',
    caseSensitive: false,
  );

  static final RegExp _amountEnPattern = RegExp(
    r'(\d+[.,]?\d*)\s*(usd|\$|dollars?|cents?|vnd|đ)',
    caseSensitive: false,
  );

  static final RegExp _amountBarePattern = RegExp(
    r'(\d+[.,]?\d*)',
  );

  static final Map<String, double> _viMultiplier = {
    'k': 1000,
    'nghìn': 1000,
    'ngàn': 1000,
    'tr': 1000000,
    'triệu': 1000000,
    'm': 10000000,
    'chục triệu': 10000000,
    'tỉ': 1000000000,
    'tỷ': 1000000000,
  };

  // ========== MAIN PROCESSING ==========

  VoiceCommand process(String text, {String language = 'vi'}) {
    final trimmed = text.trim();
    final patterns = language == 'vi' ? _intentPatternsVi : _intentPatternsEn;
    final lower = trimmed.toLowerCase();

    // Find matching intents
    final matches = <MapEntry<String, double>>[];
    for (final entry in patterns.entries) {
      double score = 0;
      for (final pattern in entry.value) {
        if (lower.contains(pattern)) {
          score += (pattern.length / lower.length).clamp(0.1, 1.0);
        }
      }
      if (score > 0) {
        matches.add(MapEntry(entry.key, score));
      }
    }

    // Sort by confidence
    matches.sort((a, b) => b.value.compareTo(a.value));

    String? intent;
    double confidence = 0;

    if (matches.isNotEmpty) {
      intent = matches.first.key;
      confidence = matches.first.value.clamp(0.0, 1.0);
    }

    // Extract entities
    final entities = extractEntities(trimmed, language: language);

    return VoiceCommand(
      rawText: trimmed,
      intent: intent,
      confidence: confidence,
      entities: entities,
    );
  }

  Map<String, dynamic> extractEntities(String text,
      {String language = 'vi'}) {
    final entities = <String, dynamic>{};

    // Extract amount
    final amount = _extractAmount(text, language: language);
    if (amount != null) {
      entities['amount'] = amount['value'];
      entities['currency'] = amount['currency'];
    }

    // Extract category
    final category = _extractExpenseCategory(text, language: language);
    if (category != null) {
      entities['category_name'] = category;
    }

    // Extract time reference
    final timeRef = _extractTimeReference(text, language: language);
    if (timeRef != null) {
      entities['time_reference'] = timeRef;
    }

    // Extract note (remaining text after removing known patterns)
    final note = _extractNote(text, entities, language: language);
    if (note.isNotEmpty) {
      entities['note'] = note;
    }

    return entities;
  }

  Map<String, dynamic>? _extractAmount(String text,
      {String language = 'vi'}) {
    final lower = text.toLowerCase();
    RegExpMatch? match;

    if (language == 'vi') {
      match = _amountViPattern.firstMatch(lower);
    } else {
      match = _amountEnPattern.firstMatch(lower);
    }

    match ??= _amountBarePattern.firstMatch(lower);

    if (match == null) return null;

    final numStr = match.group(1)!.replaceAll(',', '');
    double value = double.tryParse(numStr) ?? 0;

    String currency = 'VND';
    final suffix = match.group(2)?.toLowerCase() ?? '';

    if (language == 'vi') {
      if (_viMultiplier.containsKey(suffix)) {
        value *= _viMultiplier[suffix]!;
      }
      if (suffix == 'usd' || suffix == '\$') {
        currency = 'USD';
      }
    } else {
      if (suffix == 'k' || suffix == 'thousand') value *= 1000;
      if (suffix == 'm' || suffix == 'million') value *= 1000000;
      if (suffix == 'usd' || suffix == '\$' || suffix == 'dollars' ||
          suffix == 'dollar') {
        currency = 'USD';
      }
    }

    return {'value': value, 'currency': currency};
  }

  String? _extractExpenseCategory(String text, {String language = 'vi'}) {
    if (language == 'vi') {
      const categories = [
        'ăn uống', 'ăn', 'đi lại', 'xe', 'xăng', 'bus', 'grab',
        'mua sắm', 'shopping', 'quần áo', 'giải trí', 'phim', 'game',
        'sức khỏe', 'khám', 'thuốc', 'bệnh viện',
        'hóa đơn', 'điện', 'nước', 'internet', 'tiền nhà',
        'giáo dục', 'học', 'học phí', 'sách',
        'khác',
      ];

      final lower = text.toLowerCase();
      for (final cat in categories) {
        if (lower.contains(cat)) {
          // Map to standardized name
          if (cat == 'ăn' || cat == 'ăn uống') return 'Ăn uống';
          if (cat == 'đi lại' || cat == 'xe' || cat == 'xăng' ||
              cat == 'bus' || cat == 'grab') {
            return 'Đi lại';
          }
          if (cat == 'mua sắm' || cat == 'shopping' || cat == 'quần áo') {
            return 'Mua sắm';
          }
          if (cat == 'giải trí' || cat == 'phim' || cat == 'game') {
            return 'Giải trí';
          }
          if (cat == 'sức khỏe' || cat == 'khám' || cat == 'thuốc' ||
              cat == 'bệnh viện') {
            return 'Sức khỏe';
          }
          if (cat == 'hóa đơn' || cat == 'điện' || cat == 'nước' ||
              cat == 'internet' || cat == 'tiền nhà') {
            return 'Hóa đơn';
          }
          if (cat == 'giáo dục' || cat == 'học' || cat == 'học phí' ||
              cat == 'sách') {
            return 'Giáo dục';
          }
          return 'Khác';
        }
      }
    } else {
      const categories = {
        'food': 'Ăn uống', 'dining': 'Ăn uống', 'lunch': 'Ăn uống',
        'dinner': 'Ăn uống', 'breakfast': 'Ăn uống', 'restaurant': 'Ăn uống',
        'transport': 'Đi lại', 'gas': 'Đi lại', 'fuel': 'Đi lại',
        'uber': 'Đi lại', 'taxi': 'Đi lại', 'bus': 'Đi lại',
        'shopping': 'Mua sắm', 'clothes': 'Mua sắm',
        'entertainment': 'Giải trí', 'movie': 'Giải trí', 'game': 'Giải trí',
        'health': 'Sức khỏe', 'medical': 'Sức khỏe', 'medicine': 'Sức khỏe',
        'hospital': 'Sức khỏe',
        'bill': 'Hóa đơn', 'bills': 'Hóa đơn', 'electricity': 'Hóa đơn',
        'water': 'Hóa đơn', 'rent': 'Hóa đơn',
        'education': 'Giáo dục', 'school': 'Giáo dục', 'tuition': 'Giáo dục',
        'book': 'Giáo dục', 'books': 'Giáo dục',
      };

      final lower = text.toLowerCase();
      for (final entry in categories.entries) {
        if (lower.contains(entry.key)) {
          return entry.value;
        }
      }
    }
    return null;
  }

  /// Returns a DateTime or a relative time string
  dynamic _extractTimeReference(String text, {String language = 'vi'}) {
    final lower = text.toLowerCase();
    final now = DateTime.now();

    if (language == 'vi') {
      if (lower.contains('hôm qua')) {
        return DateTime(now.year, now.month, now.day - 1);
      }
      if (lower.contains('hôm nay') || lower.contains('bây giờ')) {
        return DateTime(now.year, now.month, now.day);
      }
      if (lower.contains('sáng nay')) {
        return DateTime(now.year, now.month, now.day, 6, 0);
      }
      if (lower.contains('trưa nay')) {
        return DateTime(now.year, now.month, now.day, 12, 0);
      }
      if (lower.contains('chiều nay')) {
        return DateTime(now.year, now.month, now.day, 14, 0);
      }
      if (lower.contains('tối nay')) {
        return DateTime(now.year, now.month, now.day, 18, 0);
      }
      if (lower.contains('tuần này')) {
        // Monday of current week
        final monday = now.subtract(Duration(days: now.weekday - 1));
        return DateTime(monday.year, monday.month, monday.day);
      }
      if (lower.contains('tháng này')) {
        return DateTime(now.year, now.month, 1);
      }
      if (lower.contains('tháng trước')) {
        final prev = DateTime(now.year, now.month - 1, 1);
        return DateTime(prev.year, prev.month, 1);
      }
      if (lower.contains('tuần trước')) {
        final lastWeek = now.subtract(const Duration(days: 7));
        final monday = lastWeek.subtract(Duration(days: lastWeek.weekday - 1));
        return DateTime(monday.year, monday.month, monday.day);
      }
    } else {
      if (lower.contains('yesterday')) {
        return DateTime(now.year, now.month, now.day - 1);
      }
      if (lower.contains('today') || lower.contains('now')) {
        return DateTime(now.year, now.month, now.day);
      }
      if (lower.contains('this week')) {
        final monday = now.subtract(Duration(days: now.weekday - 1));
        return DateTime(monday.year, monday.month, monday.day);
      }
      if (lower.contains('this month')) {
        return DateTime(now.year, now.month, 1);
      }
      if (lower.contains('last month')) {
        final prev = DateTime(now.year, now.month - 1, 1);
        return DateTime(prev.year, prev.month, 1);
      }
      if (lower.contains('last week')) {
        final lastWeek = now.subtract(const Duration(days: 7));
        final monday = lastWeek.subtract(Duration(days: lastWeek.weekday - 1));
        return DateTime(monday.year, monday.month, monday.day);
      }
      if (lower.contains('this year')) {
        return DateTime(now.year, 1, 1);
      }
    }
    return null;
  }

  String _extractNote(String text, Map<String, dynamic> entities,
      {String language = 'vi'}) {
    String cleaned = text;

    // Remove known phrases
    if (language == 'vi') {
      final removePatterns = [
        r'tôi\s+vừa\s+', r'(vừa\s+)?(chi|mua|trả|tiêu|tốn|hết|mất)\s+',
        r'(làm\s+)?ơn\s+', r'cho\s+tôi\s+',
        r'(hãy|giúp\s+tôi)\s+',
        r'nói\s+lại\s+', r'rõ\s+hơn\s+',
      ];
      for (final p in removePatterns) {
        cleaned = cleaned.replaceAll(RegExp(p, caseSensitive: false), '');
      }
    } else {
      final removePatterns = [
        r'i\s+(just\s+)?(spent|paid|bought|purchased|pay)\s+',
        r'please\s+', r'can\s+(you\s+)?',
        r'(show|list|view|give)\s+(me\s+)?',
      ];
      for (final p in removePatterns) {
        cleaned = cleaned.replaceAll(RegExp(p, caseSensitive: false), '');
      }
    }

    // Remove amount patterns
    cleaned = cleaned.replaceAll(_amountViPattern, '');
    cleaned = cleaned.replaceAll(RegExp(r'\d+[.,]?\d*\s*(k|nghìn|tr|triệu)', caseSensitive: false), '');

    // Remove category words
    final catWords = [
      'tiền', 'đồng', 'vnd', 'usd',
      'ăn uống', 'đi lại', 'mua sắm', 'giải trí',
      'sức khỏe', 'hóa đơn', 'giáo dục',
    ];
    for (final w in catWords) {
      cleaned = cleaned.replaceAll(RegExp(w, caseSensitive: false), '');
    }

    return cleaned.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Resolve relative time to absolute DateTime range
  static Map<String, DateTime> resolveTimeRange(dynamic timeRef) {
    final now = DateTime.now();

    if (timeRef is DateTime) {
      // Single date reference - full day
      return {
        'from': DateTime(timeRef.year, timeRef.month, timeRef.day),
        'to': DateTime(timeRef.year, timeRef.month, timeRef.day, 23, 59, 59),
      };
    }

    return {
      'from': DateTime(now.year, now.month, now.day),
      'to': DateTime(now.year, now.month, now.day, 23, 59, 59),
    };
  }

  /// Get period boundaries for a given period keyword
  static Map<String, DateTime> getPeriodRange(String period) {
    final now = DateTime.now();

    switch (period) {
      case 'today':
        return {
          'from': DateTime(now.year, now.month, now.day),
          'to': DateTime(now.year, now.month, now.day, 23, 59, 59),
        };
      case 'yesterday':
        final y = now.subtract(const Duration(days: 1));
        return {
          'from': DateTime(y.year, y.month, y.day),
          'to': DateTime(y.year, y.month, y.day, 23, 59, 59),
        };
      case 'this_week':
        final monday = now.subtract(Duration(days: now.weekday - 1));
        return {
          'from': DateTime(monday.year, monday.month, monday.day),
          'to': DateTime(now.year, now.month, now.day, 23, 59, 59),
        };
      case 'this_month':
        return {
          'from': DateTime(now.year, now.month, 1),
          'to': DateTime(now.year, now.month, now.day, 23, 59, 59),
        };
      case 'last_month':
        final prev = DateTime(now.year, now.month - 1, 1);
        final lastDay = DateTime(now.year, now.month, 0);
        return {
          'from': DateTime(prev.year, prev.month, 1),
          'to': DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59),
        };
      default:
        return {
          'from': DateTime(now.year, now.month, now.day),
          'to': DateTime(now.year, now.month, now.day, 23, 59, 59),
        };
    }
  }

  /// Suggest top 3 categories for ambiguous extraction
  static List<String> suggestCategories(String text,
      {String language = 'vi'}) {
    if (language == 'vi') {
      final lower = text.toLowerCase();
      final scored = <MapEntry<String, int>>[];

      const keywordMap = {
        'Ăn uống': ['ăn', 'uống', 'cafe', 'cà phê', 'trà', 'bánh', 'cơm',
            'phở', 'lẩu', 'nước', 'đồ ăn', 'thức ăn'],
        'Đi lại': ['xe', 'xăng', 'bus', 'grab', 'taxi', 'đổ xăng', 'vé',
            'bến', 'đi lại'],
        'Mua sắm': ['mua', 'sắm', 'quần', 'áo', 'giày', 'túi', 'shop',
            'siêu thị', 'chợ'],
        'Giải trí': ['phim', 'game', 'hát', 'karaoke', 'xem', 'cinema',
            'nhạc', 'ca nhạc'],
        'Sức khỏe': ['khám', 'thuốc', 'bệnh', 'viện', 'bs', 'bác sĩ',
            'vitamin', 'tap'],
        'Hóa đơn': ['điện', 'nước', 'internet', 'mạng', 'tiền nhà',
            'chung cư', 'phí'],
        'Giáo dục': ['học', 'học phí', 'sách', 'lớp', 'khóa học', 'trung tâm'],
      };

      for (final catEntry in keywordMap.entries) {
        int score = 0;
        for (final keyword in catEntry.value) {
          if (lower.contains(keyword)) {
            score += keyword.length;
          }
        }
        if (score > 0) {
          scored.add(MapEntry(catEntry.key, score));
        }
      }

      scored.sort((a, b) => b.value.compareTo(a.value));
      return scored.take(3).map((e) => e.key).toList();
    }
    return [];
  }
}
