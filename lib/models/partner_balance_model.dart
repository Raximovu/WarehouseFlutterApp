class PartnerBalanceModel {
  final int id;
  final String name;
  final String? inn; // STIR / INN kodi
  final String type; // 'mijoz' yoki 'taminotchi'
  final String? phone;
  final double totalSales;
  final double totalPurchases;
  final double totalIncoming;
  final double totalOutgoing;
  final String? lastPaymentDate;

  PartnerBalanceModel({
    required this.id,
    required this.name,
    this.inn,
    required this.type,
    this.phone,
    required this.totalSales,
    required this.totalPurchases,
    required this.totalIncoming,
    required this.totalOutgoing,
    this.lastPaymentDate,
  });

  // Mijozning qarzi:
  // Biz unga qancha sotganmiz (totalSales) + biz unga qancha pul berganmiz (totalOutgoing)
  // - u bizga qancha to'lov qilgan (totalIncoming).
  double get clientBalance => totalSales + totalOutgoing - totalIncoming;

  // Bizning ta'minotchidan qarzimiz:
  // Biz undan qancha mol olganmiz (totalPurchases) + u bizga qancha pul/avans bergan (totalIncoming)
  // - biz unga qancha pul to'laganmiz (totalOutgoing).
  double get supplierBalance => totalPurchases + totalIncoming - totalOutgoing;
}
