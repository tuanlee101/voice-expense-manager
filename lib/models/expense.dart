class Expense {
  final String id;
  final double amount;
  final String currency; // VND, USD
  final String categoryId;
  final String note;
  final DateTime timestamp; // Thời gian chi tiêu
  final DateTime createdAt; // Thời gian tạo bản ghi

  Expense({
    required this.id,
    required this.amount,
    this.currency = 'VND',
    required this.categoryId,
    this.note = '',
    required this.timestamp,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'currency': currency,
        'category_id': categoryId,
        'note': note,
        'timestamp': timestamp.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
        id: map['id'] as String,
        amount: (map['amount'] as num).toDouble(),
        currency: map['currency'] as String? ?? 'VND',
        categoryId: map['category_id'] as String,
        note: map['note'] as String? ?? '',
        timestamp: DateTime.parse(map['timestamp'] as String),
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'] as String)
            : null,
      );

  Expense copyWith({
    String? id,
    double? amount,
    String? currency,
    String? categoryId,
    String? note,
    DateTime? timestamp,
    DateTime? createdAt,
  }) =>
      Expense(
        id: id ?? this.id,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        categoryId: categoryId ?? this.categoryId,
        note: note ?? this.note,
        timestamp: timestamp ?? this.timestamp,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  String toString() =>
      'Expense($amount $currency, ${note.isEmpty ? "no note" : note}, $timestamp)';
}
