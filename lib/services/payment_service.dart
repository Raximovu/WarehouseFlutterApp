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

  Future<int> deletePayment(int id) async {
    final db = await dbHelper.database;
    return await db.delete('payments', where: 'id = ?', whereArgs: [id]);
  }
}
