import 'package:cloud_firestore/cloud_firestore.dart';

/// Reseña / comentario de un producto (colección
/// `products/{productId}/reviews/{reviewId}` en Firestore).
///
/// Cada vez que se crea una reseña, ReviewRepository también recalcula
/// automáticamente la calificación (rating) del vendedor en `users/{uid}`.
class ProductReview {
  final String id;
  final String productId;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;

  /// 1 a 5.
  final int rating;
  final String comment;
  final DateTime? createdAt;

  const ProductReview({
    required this.id,
    required this.productId,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatarUrl': authorAvatarUrl,
      'rating': rating,
      'comment': comment,
    };
  }

  factory ProductReview.fromMap(
    Map<String, dynamic> map,
    String id,
    String productId,
  ) {
    final ts = map['createdAt'];
    return ProductReview(
      id: id,
      productId: productId,
      authorId: map['authorId'] as String? ?? '',
      authorName: map['authorName'] as String? ?? 'Usuario',
      authorAvatarUrl: map['authorAvatarUrl'] as String?,
      rating: (map['rating'] as num?)?.toInt() ?? 5,
      comment: map['comment'] as String? ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
