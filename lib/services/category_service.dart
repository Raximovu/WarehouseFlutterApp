import '../database/db_helper.dart';
import '../models/category_model.dart';

class CategoryService {
  final dbHelper = DatabaseHelper.instance;

  Future<List<CategoryModel>> getAllCategories() async {
    final db = await dbHelper.database;
    final result = await db.query('categories', orderBy: 'id ASC');
    return result.map((map) => CategoryModel.fromMap(map)).toList();
  }

  Future<int> addCategory(String name) async {
    final db = await dbHelper.database;
    return await db.insert('categories', {'name': name});
  }

  Future<int> updateCategory(int id, String name) async {
    final db = await dbHelper.database;
    return await db.update('categories', {'name': name}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCategory(int id) async {
    final db = await dbHelper.database;
    // Database foreign key RESTRICT constraint orqali xavfsizlik ta'minlanadi
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
