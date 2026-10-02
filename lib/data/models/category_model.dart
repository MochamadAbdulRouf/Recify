import 'dart:ui' show Color;

class CategoryModel {
  final String id;
  final String name;
  final String type; // 'EXPENSE', 'INCOME'
  final String icon;
  final String color;

  CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    this.icon = 'category',
    this.color = '#2F6BFF',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      icon: map['icon'] as String? ?? 'category',
      color: map['color'] as String? ?? '#2F6BFF',
    );
  }
}

extension CategoryColorX on CategoryModel {
  /// Satu-satunya sumber warna kategori untuk UI (icon-circle terpilih,
  /// shadow, dsb.) — baca getter ini, jangan salin nilai hex-nya manual.
  Color get colorAsColor {
    final v = int.tryParse(color.replaceFirst('#', ''), radix: 16);
    return v == null ? const Color(0xFF2F6BFF) : Color(v | 0xFF000000);
  }
}
