import '../database/db_helper.dart';
import '../models/transaction_model.dart';
import 'inventory_service.dart';

class TransactionService {
  final dbHelper = DatabaseHelper.instance;
  final _inventoryService = InventoryService();

  Future<List<TransactionModel>> getTransactionsByType(String type) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'transactions',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'date DESC',
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
    final db = await dbHelper.database;
    final map = transaction.toMap();
    map.remove('id');
    return await db.insert('transactions', map);
  }

  // Operatsiyani tahrirlash (Sklad manfiyga kirmasligi uchun tekshiruv bilan)
  Future<int> updateTransaction(TransactionModel newTx) async {
    final db = await dbHelper.database;

    final oldTxList = await db.query('transactions', where: 'id = ?', whereArgs: [newTx.id]);
    if (oldTxList.isEmpty) {
      throw Exception('Tahrirlanayotgan operatsiya bazadan topilmadi!');
    }
    final oldTx = TransactionModel.fromMap(oldTxList.first);

    final balances = await _inventoryService.getInventoryBalances();
    final currentItem = balances.cast<Map<String, dynamic>?>().firstWhere(
      (b) => b!['name'] == newTx.name,
      orElse: () => null,
    );
    final currentStock = currentItem != null ? (currentItem['current_amount'] as num).toDouble() : 0.0;

    final isKirimType = newTx.type == 'kirim' || newTx.type == 'tayyor_kirim' || newTx.type == 'boshlangich_qoldiq';
    final isChiqimType = newTx.type == 'chiqim_sex' || newTx.type == 'sotuv' || newTx.type == 'brak';

    if (isKirimType && newTx.amount < oldTx.amount) {
      final diff = oldTx.amount - newTx.amount;
      if (currentStock < diff) {
        throw Exception('Kirim miqdorini kamaytira olmaysiz! Chunki ushbu xomashyoning ko\'p qismi ishlatib bo\'lingan. Omborda qolgan bor qoldiq: $currentStock');
      }
    }

    if (isChiqimType && newTx.amount > oldTx.amount) {
      final diff = newTx.amount - oldTx.amount;
      if (currentStock < diff) {
        throw Exception('Chiqim miqdorini oshira olmaysiz! Chunki omborda yetarli mahsulot qolmagan. Bor qoldiq: $currentStock');
      }
    }

    final map = newTx.toMap();
    map.remove('id');
    return await db.update(
      'transactions',
      map,
      where: 'id = ?',
      whereArgs: [newTx.id],
    );
  }

  // Operatsiyani o'chirish (Delete uchun Sklad minusga kirmasligini tekshirish)
  Future<int> deleteTransaction(int id) async {
    final db = await dbHelper.database;

    final txList = await db.query('transactions', where: 'id = ?', whereArgs: [id]);
    if (txList.isEmpty) return 0;
    final tx = TransactionModel.fromMap(txList.first);

    final isKirimType = tx.type == 'kirim' || tx.type == 'tayyor_kirim' || tx.type == 'boshlangich_qoldiq';

    if (isKirimType) {
      final balances = await _inventoryService.getInventoryBalances();
      final currentItem = balances.cast<Map<String, dynamic>?>().firstWhere(
        (b) => b!['name'] == tx.name,
        orElse: () => null,
      );
      final currentStock = currentItem != null ? (currentItem['current_amount'] as num).toDouble() : 0.0;

      if (currentStock < tx.amount) {
        throw Exception('Ushbu kirimni o\'chira olmaysiz! Chunki xomashyo/mahsulot allaqachon sexga yoki sotuvga chiqim qilib ishlatib bo\'lingan. Omborda qolgan qoldiq: $currentStock');
      }
    }

    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}
