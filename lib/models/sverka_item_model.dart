class SverkaItemModel {
  final int id; // Transaction yoki Payment ID si
  final String date; // YYYY-MM-DD HH:MM:SS
  final String type; // 'sotuv', 'kirim', 'tolov_kirim', 'tolov_chiqim'
  final String title; // "5000 dona 50x100 qop" yoki "Naqd pul to'lov"
  final double amount; // Summa (So'm)
  final String? notes;

  SverkaItemModel({
    required this.id,
    required this.date,
    required this.type,
    required this.title,
    required this.amount,
    this.notes,
  });
}
