class CategoryModel {
  final String id;
  final String name;
  final int colorHex;
  final double budgetLimit;

  CategoryModel({
    required this.id,
    required this.name,
    required this.colorHex,
    this.budgetLimit = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colorHex': colorHex,
      'budgetLimit': budgetLimit,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      colorHex: map['colorHex'] as int,
      budgetLimit: (map['budgetLimit'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
