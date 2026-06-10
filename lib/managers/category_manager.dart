import 'package:uuid/uuid.dart';
import '../models/expense_category.dart';
import '../services/database_service.dart';

class CategoryManager {
  final DatabaseService _db;
  final Uuid _uuid = Uuid();

  CategoryManager(this._db);

  /// Get all categories
  Future<List<ExpenseCategory>> getCategories() => _db.getCategories();

  /// Create category (R6.1 - R6.3)
  Future<ExpenseCategory> createCategory(String name) async {
    if (name.trim().isEmpty || name.length > 50) {
      throw ArgumentError('Tên danh mục phải từ 1-50 ký tự');
    }

    final trimmed = name.trim();

    // Check if exists (case-insensitive)
    final existing = await _db.getCategoryByName(trimmed);
    if (existing != null) {
      throw ArgumentError('Danh mục "$trimmed" đã tồn tại');
    }

    final category = ExpenseCategory(
      id: _uuid.v4(),
      name: trimmed,
      isDefault: false,
      icon: 'category',
      color: 0xFF9C27B0,
    );

    await _db.insertCategory(category);
    return category;
  }

  /// Rename category (R6.7 - R6.8)
  Future<ExpenseCategory> renameCategory(String id, String newName) async {
    final category = await _db.getCategory(id);
    if (category == null) {
      throw ArgumentError('Không tìm thấy danh mục');
    }
    if (category.isDefault) {
      throw ArgumentError('Không thể đổi tên danh mục mặc định');
    }

    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed.length > 50) {
      throw ArgumentError('Tên danh mục phải từ 1-50 ký tự');
    }

    // Check if name already exists
    final existing = await _db.getCategoryByName(trimmed);
    if (existing != null && existing.id != id) {
      throw ArgumentError('Tên "$trimmed" đã được sử dụng');
    }

    final updated = category.copyWith(name: trimmed);
    await _db.updateCategory(updated);
    return updated;
  }

  /// Delete category (R6.4 - R6.6)
  Future<void> deleteCategory(String id) async {
    final category = await _db.getCategory(id);
    if (category == null) {
      throw ArgumentError('Không tìm thấy danh mục');
    }
    if (category.isDefault) {
      throw ArgumentError('Không thể xóa danh mục mặc định');
    }

    await _db.deleteCategory(id);
  }

  /// Get category by name
  Future<ExpenseCategory?> getByName(String name) =>
      _db.getCategoryByName(name);
}
