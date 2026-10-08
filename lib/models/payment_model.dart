class PaymentModel {
  final int? id;
  final String date;
  final int partnerId;
  final double amount;
  final String paymentType; // 'naqd', 'karta', 'bank'
  final int isIncoming; // 1 = Mijozdan pul kirdi, 0 = Taminotchiga pul berildi
  final String? notes;

  PaymentModel({
    this.id,
    required this.date,
    required this.partnerId,
    required this.amount,
    required this.paymentType,
    required this.isIncoming,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'partner_id': partnerId,
      'amount': amount,
      'payment_type': paymentType,
      'is_incoming': isIncoming,
      'notes': notes,
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] as int?,
      date: map['date'] as String,
      partnerId: map['partner_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      paymentType: map['payment_type'] as String,
      isIncoming: map['is_incoming'] as int,
      notes: map['notes'] as String?,
    );
  }
}
