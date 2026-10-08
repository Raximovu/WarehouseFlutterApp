class MaterialModel {
  final int? id;
  final String name;
  final int categoryId;
  final int unitId;
  
  // JOIN orqali olinadigan qo'shimcha maydonlar (Faqat o'qish uchun)
  final String? categoryName;
  final String? unitName;

  MaterialModel({
    this.id,
    required this.name,
    required this.categoryId,
    required this.unitId,
    this.categoryName,
    this.unitName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'unit_id': unitId,
    };
  }

  factory MaterialModel.fromMap(Map<String, dynamic> map) {
    return MaterialModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      categoryId: map['category_id'] as int,
      unitId: map['unit_id'] as int,
      categoryName: map['category_name'] as String?,
      unitName: map['unit_name'] as String?,
    );
  }

  // ComboBox va ro'yxatlarda xatosiz ishlashi uchun
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialModel && runtimeType == other.runtimeType && id == other.id && name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
