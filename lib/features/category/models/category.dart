import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;

  /// Nombre de la categoría
  final String name;

  /// Si la categoría está disponible para los usuarios
  final bool active;

  /// Fecha de creación
  final DateTime? createdAt;

  /// Última modificación
  final DateTime? updatedAt;

  const Category({
    required this.id,
    required this.name,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  Category copyWith({
    String? name,
    bool? active,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      active: active ?? this.active,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'active': active,
    };
  }

  factory Category.fromMap(
    Map<String, dynamic> map,
    String id,
  ) {
    return Category(
      id: id,
      name: map['name'] ?? '',
      active: map['active'] ?? true,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }
}