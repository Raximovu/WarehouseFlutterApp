class PartnerModel {
  final int? id;
  final String name;
  final String? inn; // STIR / INN kodi
  final String type; // 'mijoz' yoki 'taminotchi'
  final String? phone;

  PartnerModel({
    this.id,
    required this.name,
    this.inn,
    required this.type,
    this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'inn': inn,
      'type': type,
      'phone': phone,
    };
  }

  factory PartnerModel.fromMap(Map<String, dynamic> map) {
    return PartnerModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      inn: map['inn'] as String?,
      type: map['type'] as String,
      phone: map['phone'] as String?,
    );
  }

  // ComboBox va ro'yxatlarda xatosiz ishlashi uchun
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PartnerModel && runtimeType == other.runtimeType && id == other.id && name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
