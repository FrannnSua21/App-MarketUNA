import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// -----------------------------------------------------------------------
/// MODELOS DE DATOS DEL PERFIL
///
/// UserProfile y ProfileTransaction ya están listos para Firestore
/// (toMap/fromMap). El resto (MyListing, PaymentMethod, ActiveSession,
/// AppLanguage) sigue igual que antes, con MockProfileRepository como
/// fuente de datos de ejemplo — reemplázalos por repos reales cuando
/// llegues a esas pantallas.
/// -----------------------------------------------------------------------

/// ---- Usuario (colección `users/{uid}` en Firestore) ---------------------

/// ---- Usuario (colección `users/{uid}` en Firestore) ---------------------

class UserProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? avatarUrl;
  final String bio;
  final String address;
  final String universityCode; // Código universitario, ej: 230494
  final String career; // Carrera, ej: Ingeniería de Sistemas

  // ---- Campos de solo lectura: el sistema los calcula, el usuario NO
  // los puede editar desde ProfileEditPage. ----
  final double rating;
  final int ratingCount;
  final int totalVentas;
  final int totalCompras;
  final int following; // A cuántos sigue
  final int followers; // Cuántos lo siguen
  final int favoritesCount;

  final DateTime memberSince;

  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.avatarUrl,
    this.bio = '',
    this.address = '',
    this.universityCode = '',
    this.career = '',
    this.rating = 0,
    this.ratingCount = 0,
    this.totalVentas = 0,
    this.totalCompras = 0,
    this.following = 0,
    this.followers = 0,
    this.favoritesCount = 0,
    required this.memberSince,
  });

  /// Nombre completo, para no tener que estar concatenando en cada pantalla.
  String get name => '$firstName $lastName'.trim();

  String get initials {
    final n = name.trim();
    return n.isNotEmpty ? n.substring(0, 1).toUpperCase() : '?';
  }

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? avatarUrl,
    String? bio,
    String? address,
    String? universityCode,
    String? career,
  }) {
    return UserProfile(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      address: address ?? this.address,
      universityCode: universityCode ?? this.universityCode,
      career: career ?? this.career,
      rating: rating,
      ratingCount: ratingCount,
      totalVentas: totalVentas,
      totalCompras: totalCompras,
      following: following,
      followers: followers,
      favoritesCount: favoritesCount,
      memberSince: memberSince,
    );
  }

  /// Solo los campos que el propio usuario puede editar (para `update()`).
  /// NO incluye rating, ratingCount, ventas, compras, following, followers,
  /// favoritesCount: esos los actualiza el sistema, nunca el usuario.
  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'address': address,
      'universityCode': universityCode,
      'career': career,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, String id) {
    final memberSinceTs = map['memberSince'];

    // Compatibilidad con cuentas viejas que solo tenían el campo 'name'
    // (antes de separar nombres/apellidos).
    String firstName = map['firstName'] as String? ?? '';
    String lastName = map['lastName'] as String? ?? '';
    if (firstName.isEmpty && lastName.isEmpty) {
      final legacyName = (map['name'] as String? ?? '').trim();
      if (legacyName.isNotEmpty) {
        final parts = legacyName.split(' ');
        firstName = parts.first;
        lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }
    }

    return UserProfile(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String?,
      bio: map['bio'] as String? ?? '',
      address: map['address'] as String? ?? '',
      universityCode: map['universityCode'] as String? ?? '',
      career: map['career'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: (map['ratingCount'] as num?)?.toInt() ?? 0,
      totalVentas: (map['totalVentas'] as num?)?.toInt() ?? 0,
      totalCompras: (map['totalCompras'] as num?)?.toInt() ?? 0,
      following: (map['following'] as num?)?.toInt() ?? 0,
      followers: (map['followers'] as num?)?.toInt() ?? 0,
      favoritesCount: (map['favoritesCount'] as num?)?.toInt() ?? 0,
      memberSince: memberSinceTs is Timestamp
          ? memberSinceTs.toDate()
          : DateTime.now(),
    );
  }
}

/// ---- Publicaciones del usuario (usada por profile_listings_page) --------
///
/// Nota: si ya migraste a ProductRepository, "mis publicaciones" son en
/// realidad los Product donde sellerId == mi uid (con su propio
/// ProductStatus). MyListing se deja aquí para no romper la pantalla
/// actual mientras haces esa migración con calma.

enum ListingStatus { activa, pausada, vendida }

extension ListingStatusX on ListingStatus {
  String get label {
    switch (this) {
      case ListingStatus.activa:
        return 'Activa';
      case ListingStatus.pausada:
        return 'Pausada';
      case ListingStatus.vendida:
        return 'Vendida';
    }
  }

  Color get color {
    switch (this) {
      case ListingStatus.activa:
        return AppColors.success;
      case ListingStatus.pausada:
        return const Color(0xFFF59E0B);
      case ListingStatus.vendida:
        return AppColors.textSecondary;
    }
  }
}

class MyListing {
  final String id;
  final String title;
  final double price;
  final ListingStatus status;
  final int views;
  final int favorites;
  final DateTime publishedAt;

  const MyListing({
    required this.id,
    required this.title,
    required this.price,
    required this.status,
    this.views = 0,
    this.favorites = 0,
    required this.publishedAt,
  });

  MyListing copyWith({ListingStatus? status}) {
    return MyListing(
      id: id,
      title: title,
      price: price,
      status: status ?? this.status,
      views: views,
      favorites: favorites,
      publishedAt: publishedAt,
    );
  }
}

/// ---- Historial de compras y ventas (colección `transactions`) -----------

enum TransactionType { compra, venta }

enum TransactionStatus { completado, enProceso, cancelado }

extension TransactionStatusX on TransactionStatus {
  String get label {
    switch (this) {
      case TransactionStatus.completado:
        return 'Completado';
      case TransactionStatus.enProceso:
        return 'En proceso';
      case TransactionStatus.cancelado:
        return 'Cancelado';
    }
  }

  Color get color {
    switch (this) {
      case TransactionStatus.completado:
        return AppColors.success;
      case TransactionStatus.enProceso:
        return const Color(0xFFF59E0B);
      case TransactionStatus.cancelado:
        return AppColors.error;
    }
  }
}

class ProfileTransaction {
  final String id;
  final TransactionType type;
  final String productId;
  final String productName;
  final String productImageUrl; // NUEVO
  final String counterpartName;
  final double amount;
  final DateTime date;
  final TransactionStatus status;

  const ProfileTransaction({
    required this.id,
    required this.type,
    this.productId = '',
    required this.productName,
    this.productImageUrl = '', // NUEVO
    required this.counterpartName,
    required this.amount,
    required this.date,
    required this.status,
  });

  factory ProfileTransaction.fromMap(
    Map<String, dynamic> map,
    String id,
    String currentUid,
  ) {
    final isBuyer = map['buyerId'] == currentUid;
    final dateTs = map['createdAt'];
    return ProfileTransaction(
      id: id,
      type: isBuyer ? TransactionType.compra : TransactionType.venta,
      productId: map['productId'] as String? ?? '',
      productName: map['productTitle'] as String? ?? '',
      productImageUrl: map['productImageUrl'] as String? ?? '', // NUEVO
      counterpartName: isBuyer
          ? (map['sellerName'] as String? ?? '')
          : (map['buyerName'] as String? ?? ''),
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      date: dateTs is Timestamp ? dateTs.toDate() : DateTime.now(),
      status: TransactionStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => TransactionStatus.enProceso,
      ),
    );
  }
}

/// ---- Métodos de pago (usada por profile_payment_methods_page) -----------

enum PaymentMethodType { visa, mastercard, amex, other }

extension PaymentMethodTypeX on PaymentMethodType {
  String get label {
    switch (this) {
      case PaymentMethodType.visa:
        return 'Visa';
      case PaymentMethodType.mastercard:
        return 'Mastercard';
      case PaymentMethodType.amex:
        return 'American Express';
      case PaymentMethodType.other:
        return 'Tarjeta';
    }
  }

  List<Color> get gradient {
    switch (this) {
      case PaymentMethodType.visa:
        return const [Color(0xFF1A1F71), Color(0xFF2D4EA8)];
      case PaymentMethodType.mastercard:
        return const [Color(0xFFEB001B), Color(0xFFF79E1B)];
      case PaymentMethodType.amex:
        return const [Color(0xFF2E77BC), Color(0xFF6FA8DC)];
      case PaymentMethodType.other:
        return [AppColors.primary, AppColors.secondary];
    }
  }

  static PaymentMethodType fromNumber(String number) {
    final clean = number.replaceAll(' ', '');
    if (clean.startsWith('4')) return PaymentMethodType.visa;
    if (clean.startsWith('5')) return PaymentMethodType.mastercard;
    if (clean.startsWith('3')) return PaymentMethodType.amex;
    return PaymentMethodType.other;
  }
}

class PaymentMethod {
  final String id;
  final PaymentMethodType type;
  final String holderName;
  final String last4;
  final String expiry;
  final bool isDefault;

  const PaymentMethod({
    required this.id,
    required this.type,
    required this.holderName,
    required this.last4,
    required this.expiry,
    this.isDefault = false,
  });

  PaymentMethod copyWith({bool? isDefault}) {
    return PaymentMethod(
      id: id,
      type: type,
      holderName: holderName,
      last4: last4,
      expiry: expiry,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

/// ---- Sesiones activas (usada por profile_security_page) -----------------

class ActiveSession {
  final String id;
  final String deviceName;
  final IconData deviceIcon;
  final String location;
  final DateTime lastActive;
  final bool isCurrent;

  const ActiveSession({
    required this.id,
    required this.deviceName,
    required this.deviceIcon,
    required this.location,
    required this.lastActive,
    this.isCurrent = false,
  });
}

/// ---- Idioma (usada por profile_language_page) ---------------------------

class AppLanguage {
  final String code;
  final String name;
  final String flag;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.flag,
  });
}

/// ---------------------------------------------------------------------------
/// REPOSITORIO MOCK
/// Sigue usándose para: publicaciones (por ahora), métodos de pago,
/// sesiones activas e idioma. `currentUser` y `transactions` puedes
/// reemplazarlos poco a poco por UserRepository/TransactionRepository.
/// ---------------------------------------------------------------------------
class MockProfileRepository {
  MockProfileRepository._();

  static UserProfile currentUser = UserProfile(
    id: 'u-001',
    firstName: 'Invitado',
    lastName: '',
    email: 'invitado@correo.com',
    phone: '+51 987 654 321',
    bio: 'Me encanta encontrar y vender cosas increíbles por acá.',
    address: 'Arequipa, Perú',
    universityCode: '000000',
    career: 'Sin especificar',
    rating: 4.8,
    ratingCount: 15,
    totalVentas: 12,
    totalCompras: 7,
    following: 8,
    followers: 20,
    favoritesCount: 5,
    memberSince: DateTime(2023, 3, 14),
  );

  static final List<MyListing> myListings = [
    MyListing(
      id: 'l-001',
      title: 'Bicicleta montañera aro 29',
      price: 890,
      status: ListingStatus.activa,
      views: 214,
      favorites: 18,
      publishedAt: DateTime(2026, 6, 20),
    ),
    MyListing(
      id: 'l-002',
      title: 'Laptop Lenovo IdeaPad 15"',
      price: 1450,
      status: ListingStatus.activa,
      views: 98,
      favorites: 6,
      publishedAt: DateTime(2026, 6, 28),
    ),
    MyListing(
      id: 'l-003',
      title: 'Consola PlayStation 4 + 2 mandos',
      price: 780,
      status: ListingStatus.pausada,
      views: 152,
      favorites: 11,
      publishedAt: DateTime(2026, 5, 2),
    ),
    MyListing(
      id: 'l-004',
      title: 'Mesa de centro de madera',
      price: 220,
      status: ListingStatus.vendida,
      views: 301,
      favorites: 24,
      publishedAt: DateTime(2026, 4, 11),
    ),
    MyListing(
      id: 'l-005',
      title: 'Cámara Canon EOS Rebel T7',
      price: 1290,
      status: ListingStatus.vendida,
      views: 176,
      favorites: 15,
      publishedAt: DateTime(2026, 3, 3),
    ),
  ];

  static final List<ProfileTransaction> transactions = [
    ProfileTransaction(
      id: 't-001',
      type: TransactionType.compra,
      productName: 'Audífonos Sony WH-1000XM4',
      counterpartName: 'Carla Medina',
      amount: 620,
      date: DateTime(2026, 7, 2),
      status: TransactionStatus.completado,
    ),
    ProfileTransaction(
      id: 't-002',
      type: TransactionType.venta,
      productName: 'Mesa de centro de madera',
      counterpartName: 'Jorge Salas',
      amount: 220,
      date: DateTime(2026, 6, 18),
      status: TransactionStatus.completado,
    ),
    ProfileTransaction(
      id: 't-003',
      type: TransactionType.venta,
      productName: 'Cámara Canon EOS Rebel T7',
      counterpartName: 'Renzo Alarcón',
      amount: 1290,
      date: DateTime(2026, 6, 1),
      status: TransactionStatus.enProceso,
    ),
    ProfileTransaction(
      id: 't-004',
      type: TransactionType.compra,
      productName: 'Silla ergonómica de oficina',
      counterpartName: 'Ana Quispe',
      amount: 340,
      date: DateTime(2026, 5, 22),
      status: TransactionStatus.cancelado,
    ),
    ProfileTransaction(
      id: 't-005',
      type: TransactionType.compra,
      productName: 'Set de ollas antiadherentes',
      counterpartName: 'Milagros Paredes',
      amount: 180,
      date: DateTime(2026, 4, 30),
      status: TransactionStatus.completado,
    ),
  ];

  static final List<PaymentMethod> paymentMethods = [
    PaymentMethod(
      id: 'p-001',
      type: PaymentMethodType.visa,
      holderName: 'INVITADO APP',
      last4: '4242',
      expiry: '09/28',
      isDefault: true,
    ),
    PaymentMethod(
      id: 'p-002',
      type: PaymentMethodType.mastercard,
      holderName: 'INVITADO APP',
      last4: '8823',
      expiry: '02/27',
    ),
  ];

  static final List<ActiveSession> activeSessions = [
    ActiveSession(
      id: 's-001',
      deviceName: 'Este dispositivo · Android',
      deviceIcon: Icons.smartphone,
      location: 'Arequipa, Perú',
      lastActive: DateTime.now(),
      isCurrent: true,
    ),
    ActiveSession(
      id: 's-002',
      deviceName: 'Chrome · Windows',
      deviceIcon: Icons.laptop_mac,
      location: 'Arequipa, Perú',
      lastActive: DateTime(2026, 7, 6, 21, 40),
    ),
    ActiveSession(
      id: 's-003',
      deviceName: 'Safari · iPhone',
      deviceIcon: Icons.phone_iphone,
      location: 'Lima, Perú',
      lastActive: DateTime(2026, 6, 30, 9, 15),
    ),
  ];

  static const List<AppLanguage> availableLanguages = [
    AppLanguage(code: 'es', name: 'Español', flag: '🇪🇸'),
    AppLanguage(code: 'en', name: 'English', flag: '🇺🇸'),
    AppLanguage(code: 'pt', name: 'Português', flag: '🇧🇷'),
    AppLanguage(code: 'fr', name: 'Français', flag: '🇫🇷'),
    AppLanguage(code: 'qu', name: 'Runasimi (Quechua)', flag: '🇵🇪'),
  ];

  static String selectedLanguageCode = 'es';
}
