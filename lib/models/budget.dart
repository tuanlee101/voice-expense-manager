class Budget {
  final String id;
  final String categoryId;
  final double amount;
  final String period; // day, week, month, year
  final DateTime startDate;
  final DateTime? endDate;

  Budget({
    required this.id,
    required this.categoryId,
    required this.amount,
    this.period = 'month',
    DateTime? startDate,
    this.endDate,
  }) : startDate = startDate ?? DateTime.now();

  bool get isValid => amount > 0 && amount <= 999999999.99;

  Map<String, dynamic> toMap() => {
        'id': id,
        'category_id': categoryId,
        'amount': amount,
        'period': period,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
      };

  factory Budget.fromMap(Map<String, dynamic> map) => Budget(
        id: map['id'] as String,
        categoryId: map['category_id'] as String,
        amount: (map['amount'] as num).toDouble(),
        period: map['period'] as String? ?? 'month',
        startDate: map['start_date'] != null
            ? DateTime.parse(map['start_date'] as String)
            : null,
        endDate: map['end_date'] != null
            ? DateTime.parse(map['end_date'] as String)
            : null,
      );

  Budget copyWith({
    String? id,
    String? categoryId,
    double? amount,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      Budget(
        id: id ?? this.id,
        categoryId: categoryId ?? this.categoryId,
        amount: amount ?? this.amount,
        period: period ?? this.period,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
      );
}
