import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// -----------------------------------------------------------------------
/// ESTADO / CONDICIÓN DEL PRODUCTO
/// -----------------------------------------------------------------------
enum ProductCondition { nuevo, comoNuevo, buenEstado }

extension ProductConditionX on ProductCondition {
  String get label {
    switch (this) {
      case ProductCondition.nuevo:
        return 'Nuevo';
      case ProductCondition.comoNuevo:
        return 'Como nuevo';
      case ProductCondition.buenEstado:
        return 'Buen estado';
    }
  }

  Color get color {
    switch (this) {
      case ProductCondition.nuevo:
        return AppColors.success;
      case ProductCondition.comoNuevo:
        return AppColors.secondary;
      case ProductCondition.buenEstado:
        return const Color(0xFFF59E0B);
    }
  }
}

/// -----------------------------------------------------------------------
/// ESTADO DE LA PUBLICACIÓN (antes vivía en MyListing, ahora vive en el
/// producto mismo porque en Firestore "mis publicaciones" son
/// simplemente productos donde sellerId == mi uid).
/// -----------------------------------------------------------------------
enum ProductStatus { activa, pausada, vendida }

extension ProductStatusX on ProductStatus {
  String get label {
    switch (this) {
      case ProductStatus.activa:
        return 'Activa';
      case ProductStatus.pausada:
        return 'Pausada';
      case ProductStatus.vendida:
        return 'Vendida';
    }
  }

  Color get color {
    switch (this) {
      case ProductStatus.activa:
        return AppColors.success;
      case ProductStatus.pausada:
        return const Color(0xFFF59E0B);
      case ProductStatus.vendida:
        return AppColors.textSecondary;
    }
  }
}

/// -----------------------------------------------------------------------
/// MODELO DE PRODUCTO
/// -----------------------------------------------------------------------
class Product {
  final String id;

  /// uid del dueño del producto en Firestore (colección `users`).
  final String sellerId;

  final String title;
  final double price;
  final String category;
  final String timeAgo;
  final ProductCondition condition;
  final List<String> imageUrls;
  final String description;
  final String location;
  final SellerInfo seller;
  final bool isFavorite;

  final ProductStatus status;
  final int views;
  final int favorites;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Product({
    required this.id,
    this.sellerId = '',
    required this.title,
    required this.price,
    required this.category,
    required this.timeAgo,
    required this.condition,
    required this.imageUrls,
    this.description = '',
    this.location = 'Arequipa, Perú',
    this.seller = const SellerInfo(),
    this.isFavorite = false,
    this.status = ProductStatus.activa,
    this.views = 0,
    this.favorites = 0,
    this.createdAt,
    this.updatedAt,
  });

  String get imageUrl => imageUrls.first;

  Product copyWith({
    String? title,
    double? price,
    String? category,
    ProductCondition? condition,
    List<String>? imageUrls,
    String? description,
    String? location,
    ProductStatus? status,
    int? views,
    int? favorites,
  }) {
    return Product(
      id: id,
      sellerId: sellerId,
      title: title ?? this.title,
      price: price ?? this.price,
      category: category ?? this.category,
      timeAgo: timeAgo,
      condition: condition ?? this.condition,
      imageUrls: imageUrls ?? this.imageUrls,
      description: description ?? this.description,
      location: location ?? this.location,
      seller: seller,
      isFavorite: isFavorite,
      status: status ?? this.status,
      views: views ?? this.views,
      favorites: favorites ?? this.favorites,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Datos que se guardan en Firestore. `id`, `createdAt` y `updatedAt`
  /// los pone el repositorio (doc.id / FieldValue.serverTimestamp()).
  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'sellerName': seller.name,
      'sellerRating': seller.rating,
      'sellerTotalSales': seller.totalSales,
      'title': title,
      'price': price,
      'category': category,
      'condition': condition.name,
      'imageUrls': imageUrls,
      'description': description,
      'location': location,
      'status': status.name,
      'views': views,
      'favorites': favorites,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    final createdAtTs = map['createdAt'];
    final updatedAtTs = map['updatedAt'];
    final createdAt = createdAtTs is Timestamp ? createdAtTs.toDate() : null;

    return Product(
      id: id,
      sellerId: map['sellerId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      category: map['category'] as String? ?? '',
      timeAgo: _timeAgoFrom(createdAt),
      condition: ProductCondition.values.firstWhere(
        (c) => c.name == map['condition'],
        orElse: () => ProductCondition.buenEstado,
      ),
      imageUrls: List<String>.from(map['imageUrls'] as List? ?? const []),
      description: map['description'] as String? ?? '',
      location: map['location'] as String? ?? 'Arequipa, Perú',
      seller: SellerInfo(
        name: map['sellerName'] as String? ?? 'Vendedor',
        rating: (map['sellerRating'] as num?)?.toDouble() ?? 0,
        totalSales: (map['sellerTotalSales'] as num?)?.toInt() ?? 0,
      ),
      status: ProductStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => ProductStatus.activa,
      ),
      views: (map['views'] as num?)?.toInt() ?? 0,
      favorites: (map['favorites'] as num?)?.toInt() ?? 0,
      createdAt: createdAt,
      updatedAt: updatedAtTs is Timestamp ? updatedAtTs.toDate() : null,
    );
  }

  static String _timeAgoFrom(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 30) return 'Hace ${diff.inDays}d';
    return 'Hace ${(diff.inDays / 30).floor()} mes(es)';
  }
}

class SellerInfo {
  final String name;
  final double rating;
  final int totalSales;

  const SellerInfo({
    this.name = 'Invitado',
    this.rating = 4.8,
    this.totalSales = 12,
  });
}

/// Categorías disponibles en toda la app (chips de Home y del buscador).
const List<String> productCategories = [
  'Todos',
  'Libros',
  'Tecnología',
  'Ropa',
  'Deportes',
  'Hogar',
];

/// -----------------------------------------------------------------------
/// REPOSITORIO MOCK (solo para pruebas locales / diseño de UI sin backend)
/// Cuando uses ProductRepository (Firestore) ya no necesitas esta lista.
/// -----------------------------------------------------------------------
final List<Product> mockProducts = [
  Product(
    id: '1',
    title: 'Cálculo Integral - Stewart 8va Ed.',
    price: 45,
    category: 'Libros',
    timeAgo: 'Hace 2h',
    condition: ProductCondition.buenEstado,
    imageUrls: const [
      'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=600',
      'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=600',
    ],
    description:
        'Libro de Cálculo Integral de Stewart, 8va edición. Usado un semestre, '
        'sin subrayados ni hojas rotas. Ideal para estudiantes de Ingeniería.',
  ),
  Product(
    id: '2',
    title: 'MacBook Air M1 2020 - 8GB/256GB',
    price: 850,
    category: 'Tecnología',
    timeAgo: 'Hace 5h',
    condition: ProductCondition.comoNuevo,
    imageUrls: const [
      'https://images.unsplash.com/photo-1611186871348-b1ce696e52c9?w=600',
      'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=600',
    ],
    description:
        'MacBook Air M1, 8GB RAM, 256GB SSD. Batería al 92%. Incluye cargador '
        'original y funda. Poco uso, siempre con case.',
    isFavorite: true,
  ),
];

/// Busca un producto por id en el repositorio mock.
Product? findProductById(String id) {
  for (final product in mockProducts) {
    if (product.id == id) return product;
  }
  return null;
}
