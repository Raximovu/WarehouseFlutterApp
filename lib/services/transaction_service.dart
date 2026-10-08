import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../database/db_helper.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final dbHelper = DatabaseHelper.instance;

  /// double yig'indisidagi mikroskopik qoldiqlar (masalan 5.5e-17) manfiy qoldiq deb hisoblanmasligi uchun.
  static const _eps = 1e-9;

  // Barcha operatsiyalar (sana bo'yicha filtr 500 tadan eski yozuvlarni ham qamrab olishi uchun cheklovsiz)
  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await dbHelper.database;
    final result = await db.query(
      'transactions',
      orderBy: 'date DESC, id DESC',
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<List<TransactionModel>> getTransactionsByType(String type) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'transactions',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'date DESC, id DESC',
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  // Boshlang'ich qoldiqlarni olish (Avval type = 'kirim' qidirilib xato qilingan, to'g'rilandi!)
  Future<List<TransactionModel>> getInitialBalances() async {
    final db = await dbHelper.database;
    final result = await db.query(
      'transactions',
      where: "type = 'boshlangich_qoldiq' OR (type = 'kirim' AND notes LIKE '%Boshlang%')",
      orderBy: 'date DESC',
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<List<TransactionModel>> getRecentTransactions({int limit = 10}) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'transactions',
      orderBy: 'date DESC',
      limit: limit,
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<List<TransactionModel>> getTransactionsByMaterialName(String name) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'transactions',
      where: 'name = ?',
      whereArgs: [name],
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<List<TransactionModel>> getTransactionsByCategoryId(int categoryId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'transactions',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<List<TransactionModel>> getTransactionsByUnitId(int unitId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'transactions',
      where: 'unit_id = ?',
      whereArgs: [unitId],
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  // Omborga yangi operatsiya qo'shish
  Future<int> addTransaction(TransactionModel transaction) async {
    _checkPartnerRequired(transaction);

    final db = await dbHelper.database;
    final map = transaction.toMap();
    map.remove('id');
    return await db.insert('transactions', map);
  }

  // Operatsiyani tahrirlash: tekshiruv va o'zgartirish BITTA tranzaksiyada bajariladi.
  // Agar o'zgarishdan keyin ombor qoldig'i manfiy bo'lib qolsa — o'zgarish avtomatik bekor qilinadi.
  Future<int> updateTransaction(TransactionModel newTx) async {
    _checkPartnerRequired(newTx);

    final db = await dbHelper.database;

    return await db.transaction<int>((txn) async {
      final oldRows = await txn.query('transactions', where: 'id = ?', whereArgs: [newTx.id]);
      if (oldRows.isEmpty) {
        throw Exception('Tahrirlanayotgan operatsiya bazadan topilmadi!');
      }
      final oldTx = TransactionModel.fromMap(oldRows.first);

      // Nom o'zgartirilgan bo'lishi mumkin — ham eski, ham yangi nom qoldig'i tekshiriladi
      final names = {oldTx.name, newTx.name};
      final before = <String, double>{};
      for (final name in names) {
        before[name] = await _stockOf(txn, name);
      }

      final map = newTx.toMap();
      map.remove('id');
      final updated = await txn.update(
        'transactions',
        map,
        where: 'id = ?',
        whereArgs: [newTx.id],
      );

      for (final name in names) {
        await _ensureStockNotWorse(txn, name, before[name]!);
      }
      return updated;
    });
  }

  // Operatsiyani o'chirish: o'chirgandan keyin ombor qoldig'i manfiy bo'lib qolsa — o'chirish bekor qilinadi.
  Future<int> deleteTransaction(int id) async {
    final db = await dbHelper.database;

    return await db.transaction<int>((txn) async {
      final rows = await txn.query('transactions', where: 'id = ?', whereArgs: [id]);
      if (rows.isEmpty) return 0;
      final tx = TransactionModel.fromMap(rows.first);

      final before = await _stockOf(txn, tx.name);
      final deleted = await txn.delete('transactions', where: 'id = ?', whereArgs: [id]);
      await _ensureStockNotWorse(txn, tx.name, before);
      return deleted;
    });
  }

  /// Xomashyo/mahsulotning ombordagi joriy qoldig'i (InventoryService bilan bir xil qoida bo'yicha).
  Future<double> _stockOf(DatabaseExecutor db, String name) async {
    final rows = await db.rawQuery('''
      SELECT COALESCE(SUM(
        CASE
          WHEN type IN ('kirim', 'tayyor_kirim', 'brak_kirim', 'boshlangich_qoldiq') THEN amount
          WHEN type IN ('chiqim_sex', 'sotuv', 'brak') THEN -amount
          ELSE 0
        END
      ), 0) AS stock
      FROM transactions
      WHERE name = ?
    ''', [name]);
    return (rows.first['stock'] as num).toDouble();
  }

  /// Amaldan keyin qoldiq manfiy bo'lib qolmasligini tekshiradi.
  /// Bazada oldindan manfiy qoldiq bo'lsa ham, uni yanada yomonlashtirmaydigan amallarga ruxsat beriladi.
  Future<void> _ensureStockNotWorse(DatabaseExecutor db, String name, double before) async {
    final after = await _stockOf(db, name);
    if (after < -_eps && after < before - _eps) {
      throw Exception(
        'Bu amalni bajarib bo\'lmaydi! "$name" bo\'yicha ombor qoldig\'i manfiy bo\'lib qoladi '
        '(hozir: ${_fmt(before)}, amaldan keyin: ${_fmt(after)}).\n\n'
        'Sabab: bu miqdor allaqachon sexga yoki sotuvga chiqim qilib ishlatilgan, yoki omborda yetarli mahsulot yo\'q.',
      );
    }
  }

  /// Kirim (xomashyo xaridi) va sotuv kontragentsiz saqlansa — qarz/haqdorlik hisobiga umuman tushmay qoladi.
  void _checkPartnerRequired(TransactionModel tx) {
    final needsPartner = tx.type == 'kirim' || tx.type == 'sotuv';
    final isLegacyInitialBalance = tx.notes?.contains('Boshlang') ?? false;
    if (needsPartner && tx.partnerId == null && !isLegacyInitialBalance) {
      throw Exception(
        tx.type == 'sotuv' ? 'Sotuv uchun mijozni tanlash shart!' : 'Kirim uchun ta\'minotchini tanlash shart!',
      );
    }
  }

  String _fmt(double value) {
    var s = value.toStringAsFixed(3);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    }
    return s == '-0' ? '0' : s;
  }
}
