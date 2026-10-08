import '../database/db_helper.dart';

class InventoryService {
  final dbHelper = DatabaseHelper.instance;

  // Ombordagi barcha xomashyo va tayyor mahsulotlar qoldig'ini Vaznli O'rtacha Tannarx (Weighted Average Cost) bo'yicha hisoblash
  Future<List<Map<String, dynamic>>> getInventoryBalances() async {
    final db = await dbHelper.database;

    final result = await db.rawQuery('''
      SELECT 
        t.name,
        c.name AS category_name,
        u.name AS unit_name,
        SUM(
          CASE 
            WHEN t.type IN ('kirim', 'tayyor_kirim', 'brak_kirim', 'boshlangich_qoldiq') THEN t.amount
            WHEN t.type IN ('chiqim_sex', 'sotuv', 'brak') THEN -t.amount
            ELSE 0 
          END
        ) AS current_amount,
        COALESCE(
          SUM(
            CASE 
              WHEN t.type IN ('kirim', 'tayyor_kirim', 'brak_kirim', 'boshlangich_qoldiq') AND t.amount > 0 THEN t.total_sum
              ELSE 0 
            END
          ) / 
          NULLIF(
            SUM(
              CASE 
                WHEN t.type IN ('kirim', 'tayyor_kirim', 'brak_kirim', 'boshlangich_qoldiq') AND t.amount > 0 THEN t.amount
                ELSE 0 
              END
            ), 0
          ), 0
        ) AS avg_unit_price
      FROM transactions t
      JOIN categories c ON t.category_id = c.id
      JOIN units u ON t.unit_id = u.id
      GROUP BY t.name, c.name, u.name
      HAVING ABS(current_amount) > 0.000001
      ORDER BY c.name, t.name
    ''');

    return result.map((row) {
      final amount = (row['current_amount'] as num).toDouble();
      final avgPrice = (row['avg_unit_price'] as num).toDouble();
      final totalSum = amount * avgPrice;

      return {
        'name': row['name'],
        'category_name': row['category_name'],
        'unit_name': row['unit_name'],
        'current_amount': amount,
        'avg_price': avgPrice,
        'current_total_sum': totalSum,
      };
    }).toList();
  }
}
