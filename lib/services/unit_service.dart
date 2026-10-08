import '../database/db_helper.dart';
import '../models/unit_model.dart';

class UnitService {
  final dbHelper = DatabaseHelper.instance;

  Future<List<UnitModel>> getAllUnits() async {
    final db = await dbHelper.database;
    final result = await db.query('units', orderBy: 'id ASC');
    return result.map((map) => UnitModel.fromMap(map)).toList();
  }

  Future<int> addUnit(String name) async {
    final db = await dbHelper.database;
    return await db.insert('units', {'name': name});
  }

  Future<int> updateUnit(int id, String name) async {
    final db = await dbHelper.database;
    return await db.update('units', {'name': name}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteUnit(int id) async {
    final db = await dbHelper.database;
    // RESTRICT logikasi o'z-o'zidan ishlaydi
    return await db.delete('units', where: 'id = ?', whereArgs: [id]);
  }
}
