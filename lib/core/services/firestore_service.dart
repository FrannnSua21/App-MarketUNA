import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/profile/models/profile_models.dart';
import '../../features/product/models/product.dart';
import '../../features/product/models/product_review.dart';

/// -----------------------------------------------------------------------
/// TODO lo de Firestore en un solo lugar, con funciones directas
/// (sin capas de "repository"). Se llama así: FirestoreService.metodo(...)
/// -----------------------------------------------------------------------
class FirestoreService {
  FirestoreService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // =========================================================================
  // USUARIO  ->  colección `users/{uid}`
  // =========================================================================

  /// Se llama una sola vez, justo después de crear la cuenta en FirebaseAuth.
  static Future<void> createUserProfile({
    required String uid,
    required String email,
    String? name,
    String? phone, // NUEVO
  }) async {
    final now = FieldValue.serverTimestamp();
    await _db.collection('users').doc(uid).set({
      'name': (name != null && name.trim().isNotEmpty)
          ? name
          : email.split('@').first,
      'email': email,
      'phone': phone ?? '', // NUEVO
      'avatarUrl': null,
      'bio': '',
      'address': '',
      'rating': 0.0,
      'ratingCount': 0,
      'totalVentas': 0,
      'totalCompras': 0,
      'memberSince': now,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  static Future<UserProfile?> getUserProfile(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    if (!snap.exists) return null;
    return UserProfile.fromMap(snap.data()!, snap.id);
  }

  /// Para usar con StreamBuilder en la pantalla de perfil.
  static Stream<UserProfile?> watchUserProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return UserProfile.fromMap(snap.data()!, snap.id);
    });
  }

  static Future<void> updateUserProfile(String uid, Map<String, dynamic> data) {
    data['updatedAt'] = FieldValue.serverTimestamp();
    return _db.collection('users').doc(uid).update(data);
  }

  // =========================================================================
  // PRODUCTOS  ->  colección `products/{productId}`
  // =========================================================================

  /// Crea un producto nuevo. Devuelve el id generado.
  static Future<String> createProduct(Product product) async {
    final doc = _db.collection('products').doc();
    final data = product.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await doc.set(data);
    return doc.id;
  }

  static Future<Product?> getProductById(String id) async {
    final snap = await _db.collection('products').doc(id).get();
    if (!snap.exists) return null;
    return Product.fromMap(snap.data()!, snap.id);
  }

  /// Productos publicados por un usuario (su "tienda" / mis publicaciones).
  static Stream<List<Product>> watchUserProducts(String sellerId) {
    return _db
        .collection('products')
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Product.fromMap(d.data(), d.id)).toList(),
        );
  }

  /// Feed general (home / búsqueda), solo productos activos.
  static Stream<List<Product>> watchFeed({String? category}) {
    Query<Map<String, dynamic>> query = _db
        .collection('products')
        .where('status', isEqualTo: ProductStatus.activa.name);

    if (category != null && category != 'Todos') {
      query = query.where('category', isEqualTo: category);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Product.fromMap(d.data(), d.id)).toList(),
        );
  }

  static Future<void> updateProduct(String id, Map<String, dynamic> data) {
    data['updatedAt'] = FieldValue.serverTimestamp();
    return _db.collection('products').doc(id).update(data);
  }

  static Future<void> changeProductStatus(String id, ProductStatus status) {
    return updateProduct(id, {'status': status.name});
  }

  static Future<void> incrementProductViews(String id) {
    return _db.collection('products').doc(id).update({
      'views': FieldValue.increment(1),
    });
  }

  static Future<void> deleteProduct(String id) {
    return _db.collection('products').doc(id).delete();
  }

  // =========================================================================
  // RESEÑAS  ->  colección `products/{productId}/reviews/{reviewId}`
  // También recalcula el rating del vendedor en `users/{sellerId}`.
  // =========================================================================

  static Stream<List<ProductReview>> watchProductReviews(String productId) {
    return _db
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ProductReview.fromMap(d.data(), d.id, productId))
              .toList(),
        );
  }

  static Future<void> addProductReview({
    required String productId,
    required String sellerId,
    required String authorId,
    required String authorName,
    String? authorAvatarUrl,
    required int rating,
    required String comment,
  }) async {
    final reviewRef = _db
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .doc();
    final sellerRef = _db.collection('users').doc(sellerId);

    await _db.runTransaction((tx) async {
      final sellerSnap = await tx.get(sellerRef);
      final sellerData = sellerSnap.data() ?? {};
      final currentRating = (sellerData['rating'] as num?)?.toDouble() ?? 0.0;
      final currentCount = (sellerData['ratingCount'] as num?)?.toInt() ?? 0;
      final newCount = currentCount + 1;
      final newRating = ((currentRating * currentCount) + rating) / newCount;

      tx.set(reviewRef, {
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatarUrl': authorAvatarUrl,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.update(sellerRef, {
        'rating': newRating,
        'ratingCount': newCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // =========================================================================
  // TRANSACCIONES (compras/ventas)  ->  colección `transactions/{id}`
  // =========================================================================

  static Future<void> updateTransactionStatus(
    String transactionId,
    TransactionStatus status,
  ) {
    return _db.collection('transactions').doc(transactionId).update({
      'status': status.name,
    });
  }

  /// Compras Y ventas del usuario en un solo stream (requiere
  /// cloud_firestore >= 4.9 por el uso de Filter.or).
  static Stream<List<ProfileTransaction>> watchUserTransactions(String uid) {
    return _db
        .collection('transactions')
        .where(
          Filter.or(
            Filter('buyerId', isEqualTo: uid),
            Filter('sellerId', isEqualTo: uid),
          ),
        )
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ProfileTransaction.fromMap(d.data(), d.id, uid))
              .toList(),
        );
  }

  static DocumentReference<Map<String, dynamic>> newProductRef() =>
      _db.collection('products').doc();

  static Future<void> createTransaction({
    required String productId,
    required String productTitle,
    String productImageUrl = '', // NUEVO
    required String buyerId,
    required String buyerName,
    required String sellerId,
    required String sellerName,
    required double amount,
  }) async {
    final doc = _db.collection('transactions').doc();
    await doc.set({
      'productId': productId,
      'productTitle': productTitle,
      'productImageUrl': productImageUrl, // NUEVO
      'buyerId': buyerId,
      'buyerName': buyerName,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'amount': amount,
      'status': TransactionStatus.enProceso.name,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('users').doc(buyerId).update({
      'totalCompras': FieldValue.increment(1),
    });
    await _db.collection('users').doc(sellerId).update({
      'totalVentas': FieldValue.increment(1),
    });
  }
}
