import '../database/db_helper.dart';
import '../models/partner_model.dart';
import '../models/partner_balance_model.dart';
import '../models/sverka_item_model.dart';

class PartnerService {
  final dbHelper = DatabaseHelper.instance;

  Future<List<PartnerModel>> getAllPartners({String? type}) async {
    final db = await dbHelper.database;
    final result = type != null
        ? await db.query('partners', where: 'type = ?', whereArgs: [type], orderBy: 'name ASC')
        : await db.query('partners', orderBy: 'name ASC');
    return result.map((map) => PartnerModel.fromMap(map)).toList();
  }

  Future<List<PartnerBalanceModel>> getPartnersWithBalance({String? typeFilter}) async {
    final db = await dbHelper.database;

    String whereClause = '';
    List<dynamic> whereArgs = [];
    if (typeFilter != null && typeFilter.isNotEmpty) {
      whereClause = 'WHERE p.type = ?';
      whereArgs.add(typeFilter);
    }

    final result = await db.rawQuery('''
      SELECT 
        p.id, 
        p.name, 
        p.inn,
        p.type, 
        p.phone,
        COALESCE(t.total_sales, 0) AS total_sales,
        COALESCE(t.total_purchases, 0) AS total_purchases,
        COALESCE(pay.total_incoming, 0) AS total_incoming,
        COALESCE(pay.total_outgoing, 0) AS total_outgoing,
        pay.last_payment_date
      FROM partners p
      LEFT JOIN (
        SELECT partner_id,
          SUM(CASE WHEN type = 'sotuv' THEN total_sum ELSE 0 END) AS total_sales,
          SUM(CASE WHEN type IN ('kirim', 'tayyor_kirim') THEN total_sum ELSE 0 END) AS total_purchases
        FROM transactions
        GROUP BY partner_id
      ) t ON p.id = t.partner_id
      LEFT JOIN (
        SELECT partner_id,
          SUM(CASE WHEN is_incoming = 1 THEN amount ELSE 0 END) AS total_incoming,
          SUM(CASE WHEN is_incoming = 0 THEN amount ELSE 0 END) AS total_outgoing,
          MAX(date) AS last_payment_date
        FROM payments
        GROUP BY partner_id
      ) pay ON p.id = pay.partner_id
      $whereClause
      ORDER BY p.name ASC
    ''', whereArgs);

    return result.map((map) {
      return PartnerBalanceModel(
        id: map['id'] as int,
        name: map['name'] as String,
        inn: map['inn'] as String?,
        type: map['type'] as String,
        phone: map['phone'] as String?,
        totalSales: (map['total_sales'] as num).toDouble(),
        totalPurchases: (map['total_purchases'] as num).toDouble(),
        totalIncoming: (map['total_incoming'] as num).toDouble(),
        totalOutgoing: (map['total_outgoing'] as num).toDouble(),
        lastPaymentDate: map['last_payment_date'] as String?,
      );
    }).toList();
  }

  Future<List<SverkaItemModel>> getPartnerSverkaHistory(int partnerId) async {
    final db = await dbHelper.database;

    final txResult = await db.rawQuery('''
      SELECT id, date, type, name, amount, total_sum, notes 
      FROM transactions 
      WHERE partner_id = ?
    ''', [partnerId]);

    final payResult = await db.rawQuery('''
      SELECT id, amount, payment_type, is_incoming, notes, date 
      FROM payments 
      WHERE partner_id = ?
    ''', [partnerId]);

    List<SverkaItemModel> items = [];

    for (var row in txResult) {
      final id = row['id'] as int;
      final type = row['type'] as String;
      final name = row['name'] as String;
      final amount = (row['amount'] as num).toDouble();
      final totalSum = (row['total_sum'] as num).toDouble();

      String title = type == 'sotuv'
          ? 'Sotuv: $name ($amount dona/kg)'
          : 'Kirim: $name ($amount dona/kg)';

      items.add(SverkaItemModel(
        id: id,
        date: row['date'] as String,
        type: type,
        title: title,
        amount: totalSum,
        notes: row['notes'] as String?,
      ));
    }

    for (var row in payResult) {
      final id = row['id'] as int;
      final isIncoming = row['is_incoming'] as int;
      final payType = row['payment_type'] as String;
      final amount = (row['amount'] as num).toDouble();

      String title = isIncoming == 1
          ? 'To\'lov Qabul Qilindi ($payType)'
          : 'To\'lov Bajarildi ($payType)';

      items.add(SverkaItemModel(
        id: id,
        date: row['date'] as String,
        type: isIncoming == 1 ? 'tolov_kirim' : 'tolov_chiqim',
        title: title,
        amount: amount,
        notes: row['notes'] as String?,
      ));
    }

    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  Future<int> addPartner(PartnerModel partner) async {
    final db = await dbHelper.database;
    final map = partner.toMap();
    map.remove('id');
    return await db.insert('partners', map);
  }

  Future<int> updatePartner(PartnerModel partner) async {
    final db = await dbHelper.database;
    final map = partner.toMap();
    map.remove('id');
    return await db.update('partners', map, where: 'id = ?', whereArgs: [partner.id]);
  }

  Future<int> deletePartner(int id) async {
    final db = await dbHelper.database;
    return await db.delete('partners', where: 'id = ?', whereArgs: [id]);
  }
}
