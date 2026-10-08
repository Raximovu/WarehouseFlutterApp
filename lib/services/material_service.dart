import '../database/db_helper.dart';
import '../models/material_model.dart';

class MaterialService {
  final dbHelper = DatabaseHelper.instance;

  Future<List<MaterialModel>> getAllMaterials({int? categoryId}) async {
    final db = await dbHelper.database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    if (categoryId != null) {
      whereClause = 'WHERE m.category_id = ?';
      whereArgs.add(categoryId);
    }

    final result = await db.rawQuery('''
      SELECT 
        m.id, 
        m.name, 
        m.category_id, 
        m.unit_id,
        c.name AS category_name,
        u.name AS unit_name
      FROM materials m
      JOIN categories c ON m.category_id = c.id
      JOIN units u ON m.unit_id = u.id
      $whereClause
      ORDER BY m.name ASC
    ''', whereArgs);

    return result.map((map) => MaterialModel.fromMap(map)).toList();
  }

  Future<int> addMaterial(MaterialModel material) async {
    final db = await dbHelper.database;
    return await db.insert('materials', material.toMap());
  }

  Future<int> updateMaterial(MaterialModel material) async {
    final db = await dbHelper.database;
    return await db.update('materials', material.toMap(), where: 'id = ?', whereArgs: [material.id]);
  }

  Future<int> deleteMaterial(int id) async {
    final db = await dbHelper.database;
    return await db.delete('materials', where: 'id = ?', whereArgs: [id]);
  }
}
