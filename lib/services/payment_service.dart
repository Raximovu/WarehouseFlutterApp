import '../database/db_helper.dart';
import '../models/payment_model.dart';

class PaymentService {
  final dbHelper = DatabaseHelper.instance;

  Future<List<PaymentModel>> getAllPayments() async {
    final db = await dbHelper.database;
    final result = await db.query('payments', orderBy: 'date DESC');
    return result.map((map) => PaymentModel.fromMap(map)).toList();
  }

  Future<int> addPayment(PaymentModel payment) async {
    final db = await dbHelper.database;
    return await db.insert('payments', payment.toMap());
  }

  /// Perekidka (o'zaro o'tkazma): ikkala tomonning yozuvi BITTA tranzaksiyada saqlanadi.
  /// Biror xato bo'lsa ikkalasi ham saqlanmaydi (bir tomonlama qarz paydo bo'lmaydi).
  Future<void> addTransferPair(PaymentModel sender, PaymentModel receiver) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert('payments', sender.toMap());
      await txn.insert('payments', receiver.toMap());
    });
  }

  /// To'lovni o'chiradi. Agar bu perekidka bo'lsa va uning qarama-qarshi (juft) yozuvi
  /// aniq topilsa — ikkinchi kontragentdagi juft yozuv ham birga o'chiriladi.
  /// O'chirilgan yozuvlar sonini qaytaradi (oddiy to'lov — 1, juft perekidka — 2).
  Future<int> deletePayment(int id) async {
    final db = await dbHelper.database;

    return await db.transaction<int>((txn) async {
      final rows = await txn.query('payments', where: 'id = ?', whereArgs: [id]);
      if (rows.isEmpty) return 0;
      final payment = PaymentModel.fromMap(rows.first);

      final idsToDelete = <int>[id];

      if (payment.paymentType == 'perekidka') {
        // Juft yozuv: bir vaqtda (sana aynan bir xil), bir xil summa, qarama-qarshi yo'nalish, boshqa kontragent
        final pair = await txn.query(
          'payments',
          where: "payment_type = 'perekidka' AND date = ? AND amount = ? AND is_incoming != ? AND partner_id != ? AND id != ?",
          whereArgs: [payment.date, payment.amount, payment.isIncoming, payment.partnerId, id],
        );
        // Faqat juft aniq bitta bo'lsa o'chiramiz (noaniq bo'lsa boshqa odamning yozuviga tegmaymiz)
        if (pair.length == 1) {
          idsToDelete.add(pair.first['id'] as int);
        }
      }

      var deleted = 0;
      for (final paymentId in idsToDelete) {
        deleted += await txn.delete('payments', where: 'id = ?', whereArgs: [paymentId]);
      }
      return deleted;
    });
  }
}
