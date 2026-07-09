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
/// MODELO DE PRODUCTO
/// Reemplaza esto por tu modelo real (el que venga de Firestore / tu API).
/// Si ya tienes uno, solo copia los nombres de campos que uses en las
/// pantallas de esta feature (product_list_page, product_detail_page,
/// product_edit_page) para no tener que reescribir todo.
/// -----------------------------------------------------------------------
class Product {
  final String id;
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

  const Product({
    required this.id,
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
  }) {
    return Product(
      id: id,
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
    );
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
/// REPOSITORIO MOCK
/// Fuente única de productos de ejemplo. Cuando conectes tu backend,
/// reemplaza `mockProducts` por la llamada real (p. ej. un
/// ProductRepository con Firestore/REST) y deja `findById` con la misma
/// firma para no tener que tocar las pantallas que ya la usan.
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
  Product(
    id: '3',
    title: 'Sudadera Universidad Azul M',
    price: 28,
    category: 'Ropa',
    timeAgo: 'Hace 1d',
    condition: ProductCondition.nuevo,
    imageUrls: const [
      'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=600',
    ],
    description: 'Sudadera talla M, nunca usada, todavía con etiqueta.',
  ),
  Product(
    id: '4',
    title: 'Balón de Fútbol Nike Premier',
    price: 35,
    category: 'Deportes',
    timeAgo: 'Hace 3h',
    condition: ProductCondition.buenEstado,
    imageUrls: const [
      'https://images.unsplash.com/photo-1614632537197-38a17061c2bd?w=600',
    ],
    description: 'Balón oficial Nike Premier, usado en pocos partidos.',
    isFavorite: true,
  ),
  Product(
    id: '5',
    title: 'Arduino Uno R3 + Cables',
    price: 40,
    category: 'Tecnología',
    timeAgo: 'Hace 6h',
    condition: ProductCondition.comoNuevo,
    imageUrls: const [
      'https://images.unsplash.com/photo-1553406830-ef2513450d76?w=600',
    ],
    description: 'Kit Arduino Uno R3 con cables jumper y protoboard.',
  ),
  Product(
    id: '6',
    title: 'Clases de Inglés - Nivel B1/B2',
    price: 20,
    category: 'Libros',
    timeAgo: 'Hace 3h',
    condition: ProductCondition.nuevo,
    imageUrls: const [
      'https://images.unsplash.com/photo-1546410531-bb4caa6b424d?w=600',
    ],
    description:
        'Clases particulares de inglés, por hora, online o presencial.',
  ),
  Product(
    id: '7',
    title: 'Silla Gamer Reclinable',
    price: 320,
    category: 'Hogar',
    timeAgo: 'Hace 8h',
    condition: ProductCondition.buenEstado,
    imageUrls: const [
      'https://images.unsplash.com/photo-1598550476439-6847785fcea6?w=600',
    ],
    description: 'Silla gamer reclinable, apoyabrazos ajustables, poco uso.',
  ),
  Product(
    id: '8',
    title: 'Bicicleta Montañera Aro 29',
    price: 480,
    category: 'Deportes',
    timeAgo: 'Hace 1d',
    condition: ProductCondition.buenEstado,
    imageUrls: const [
      'https://images.unsplash.com/photo-1576435728678-68d0fbf94e91?w=600',
    ],
    description: 'Bicicleta aro 29, cambios Shimano, frenos de disco.',
  ),
  Product(
    id: '9',
    title: 'Zapatillas Running Talla 42',
    price: 95,
    category: 'Ropa',
    timeAgo: 'Hace 10h',
    condition: ProductCondition.comoNuevo,
    imageUrls: const [
      'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600',
    ],
    description: 'Zapatillas running, usadas 2 veces, talla 42.',
  ),
  Product(
    id: '10',
    title: 'Monitor Gamer 24" 144Hz',
    price: 420,
    category: 'Tecnología',
    timeAgo: 'Hace 12h',
    condition: ProductCondition.comoNuevo,
    imageUrls: const [
      'https://images.unsplash.com/photo-1527443224154-c4a3942d3acf?w=600',
    ],
    description: 'Monitor 24 pulgadas, 144Hz, ideal para gaming.',
  ),
  Product(
    id: '11',
    title: 'Set de Ollas Antiadherentes',
    price: 110,
    category: 'Hogar',
    timeAgo: 'Hace 2d',
    condition: ProductCondition.nuevo,
    imageUrls: const [
      'https://images.unsplash.com/photo-1584990347449-a5d9f800a783?w=600',
    ],
    description: 'Set de 5 ollas antiadherentes, sin usar, caja sellada.',
  ),
  Product(
    id: '12',
    title: 'Guitarra Acústica Yamaha',
    price: 260,
    category: 'Hogar',
    timeAgo: 'Hace 4h',
    condition: ProductCondition.buenEstado,
    imageUrls: const [
      'https://images.unsplash.com/photo-1525201548942-d8732f6617a0?w=600',
    ],
    description: 'Guitarra acústica Yamaha, buen sonido, incluye funda.',
  ),
];

/// Busca un producto por id en el repositorio mock.
Product? findProductById(String id) {
  for (final product in mockProducts) {
    if (product.id == id) return product;
  }
  return null;
}
