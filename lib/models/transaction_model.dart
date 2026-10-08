class TransactionModel {
  final int? id;
  final String date;
  final String type; // 'kirim', 'chiqim_sex', 'tayyor_kirim', 'brak_kirim', 'sotuv', 'brak'
  final int? partnerId;
  final int categoryId;
  final String name;
  final double amount;
  final int unitId;
  final double price;
  final double totalSum;
  final String? notes;

  TransactionModel({
    this.id,
    required this.date,
    required this.type,
    this.partnerId,
    required this.categoryId,
    required this.name,
    required this.amount,
    required this.unitId,
    required this.price,
    required this.totalSum,
    this.notes,
  });

  // Clean Code: Operatsiya turini o'zbekcha tushunarli matnga o'girib beruvchi umumiy getter
  String get typeLabel {
    switch (type) {
      case 'kirim':
        return 'Xomashyo Kirimi';
      case 'chiqim_sex':
        return 'Ishlab chiqarishga Chiqim';
      case 'tayyor_kirim':
        return 'Tayyor Qop Kirimi';
      case 'brak_kirim':
        return 'Brak Kirimi (Sexdan)';
      case 'sotuv':
        return 'Sotuv';
      case 'brak':
        return 'Brak Chiqimi / Sotuvi';
      default:
        return 'Boshqa';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'type': type,
      'partner_id': partnerId,
      'category_id': categoryId,
      'name': name,
      'amount': amount,
      'unit_id': unitId,
      'price': price,
      'total_sum': totalSum,
      'notes': notes,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      date: map['date'] as String,
      type: map['type'] as String,
      partnerId: map['partner_id'] as int?,
      categoryId: map['category_id'] as int,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      unitId: map['unit_id'] as int,
      price: (map['price'] as num).toDouble(),
      totalSum: (map['total_sum'] as num).toDouble(),
      notes: map['notes'] as String?,
    );
  }
}
