class ExpenseCategory {
  final String id;
  final String name;
  final bool isDefault; // 8 danh mục mặc định không được xoá
  final String icon; // icon name
  final int color; // color value

  const ExpenseCategory({
    required this.id,
    required this.name,
    this.isDefault = false,
    this.icon = 'category',
    this.color = 0xFF4CAF50,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'is_default': isDefault ? 1 : 0,
        'icon': icon,
        'color': color,
      };

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) => ExpenseCategory(
        id: map['id'] as String,
        name: map['name'] as String,
        isDefault: (map['is_default'] as int? ?? 0) == 1,
        icon: map['icon'] as String? ?? 'category',
        color: map['color'] as int? ?? 0xFF4CAF50,
      );

  ExpenseCategory copyWith({
    String? id,
    String? name,
    bool? isDefault,
    String? icon,
    int? color,
  }) =>
      ExpenseCategory(
        id: id ?? this.id,
        name: name ?? this.name,
        isDefault: isDefault ?? this.isDefault,
        icon: icon ?? this.icon,
        color: color ?? this.color,
      );

  static const List<ExpenseCategory> defaultCategories = [
    ExpenseCategory(
      id: 'default_food',
      name: 'Ăn uống',
      isDefault: true,
      icon: 'restaurant',
      color: 0xFFFF5722,
    ),
    ExpenseCategory(
      id: 'default_transport',
      name: 'Đi lại',
      isDefault: true,
      icon: 'directions_car',
      color: 0xFF2196F3,
    ),
    ExpenseCategory(
      id: 'default_shopping',
      name: 'Mua sắm',
      isDefault: true,
      icon: 'shopping_cart',
      color: 0xFFE91E63,
    ),
    ExpenseCategory(
      id: 'default_entertainment',
      name: 'Giải trí',
      isDefault: true,
      icon: 'movie',
      color: 0xFF9C27B0,
    ),
    ExpenseCategory(
      id: 'default_health',
      name: 'Sức khỏe',
      isDefault: true,
      icon: 'favorite',
      color: 0xFF4CAF50,
    ),
    ExpenseCategory(
      id: 'default_bills',
      name: 'Hóa đơn',
      isDefault: true,
      icon: 'receipt',
      color: 0xFF607D8B,
    ),
    ExpenseCategory(
      id: 'default_education',
      name: 'Giáo dục',
      isDefault: true,
      icon: 'school',
      color: 0xFF3F51B5,
    ),
    ExpenseCategory(
      id: 'default_other',
      name: 'Khác',
      isDefault: true,
      icon: 'more_horiz',
      color: 0xFF9E9E9E,
    ),
    ExpenseCategory(
      id: 'default_uncategorized',
      name: 'Không phân loại',
      isDefault: true,
      icon: 'help_outline',
      color: 0xFFBDBDBD,
    ),
  ];

  static const String uncategorizedId = 'default_uncategorized';
}
