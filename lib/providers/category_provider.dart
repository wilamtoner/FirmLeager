import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../services/database_service.dart';

final categoryProvider = StateNotifierProvider<CategoryNotifier, List<CategoryModel>>((ref) {
  return CategoryNotifier();
});

class CategoryNotifier extends StateNotifier<List<CategoryModel>> {
  CategoryNotifier() : super([]) {
    loadCategories();
  }

  final DatabaseService _db = DatabaseService();

  Future<void> loadCategories() async {
    final list = await _db.getCategories();
    state = list;
  }

  Future<void> saveCategory(CategoryModel category) async {
    await _db.saveCategory(category);
    await loadCategories();
  }
}
