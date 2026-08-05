import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/firestore_service.dart';
import '../../profile/models/profile_models.dart';
import '../models/product_review.dart';

/// -----------------------------------------------------------------------
/// SECCIÓN DE RESEÑAS / COMENTARIOS DE UN PRODUCTO
///
/// Muestra el promedio + total de reseñas, un botón para dejar la propia
/// (con estrellas y comentario) y la lista completa en tiempo real.
/// Cualquier usuario logueado puede opinar, incluso si no compró — es
/// una vitrina de reputación del vendedor y del producto en general.
/// -----------------------------------------------------------------------
class ProductReviewsSection extends StatefulWidget {
  final String productId;
  final String sellerId;

  const ProductReviewsSection({
    super.key,
    required this.productId,
    required this.sellerId,
  });

  @override
  State<ProductReviewsSection> createState() => _ProductReviewsSectionState();
}

class _ProductReviewsSectionState extends State<ProductReviewsSection> {
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _openReviewSheet() async {
    final uid = _uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para dejar una reseña')),
      );
      return;
    }

    if (uid == widget.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes reseñar tu propia publicación'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => _WriteReviewSheet(
        productId: widget.productId,
        sellerId: widget.sellerId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Reseñas',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _openReviewSheet,
              icon: const Icon(Icons.rate_review_outlined, size: 16),
              label: const Text('Opinar'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        StreamBuilder<List<ProductReview>>(
          stream: FirestoreService.watchProductReviews(widget.productId),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final reviews = snap.data ?? [];

            if (reviews.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.lg,
                  horizontal: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 30,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Aún no hay reseñas',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Sé la primera persona en opinar sobre este producto.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              );
            }

            final avg =
                reviews.map((r) => r.rating).reduce((a, b) => a + b) /
                reviews.length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReviewsSummary(average: avg, total: reviews.length),
                const SizedBox(height: AppSpacing.sm),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reviews.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) =>
                      _ReviewTile(review: reviews[index]),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ReviewsSummary extends StatelessWidget {
  final double average;
  final int total;

  const _ReviewsSummary({required this.average, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Text(
            average.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(5, (i) {
                    final filled = i < average.round();
                    return Icon(
                      filled ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 16,
                      color: const Color(0xFFF59E0B),
                    );
                  }),
                ),
                const SizedBox(height: 2),
                Text(
                  '$total ${total == 1 ? 'reseña' : 'reseñas'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final ProductReview review;

  const _ReviewTile({required this.review});

  // FIX: createdAt es DateTime? en el modelo (puede ser null justo después
  // de escribir, antes de que el servidor confirme el serverTimestamp).
  String _timeAgo(DateTime? date) {
    if (date == null) return 'hace un momento';
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 30) {
      final months = (diff.inDays / 30).floor();
      return 'hace $months ${months == 1 ? 'mes' : 'meses'}';
    }
    if (diff.inDays >= 1) return 'hace ${diff.inDays} d';
    if (diff.inHours >= 1) return 'hace ${diff.inHours} h';
    return 'hace un momento';
  }

  @override
  Widget build(BuildContext context) {
    final initials = review.authorName.trim().isNotEmpty
        ? review.authorName.trim()[0].toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: AppColors.primary,
            backgroundImage:
                (review.authorAvatarUrl != null &&
                    review.authorAvatarUrl!.isNotEmpty)
                ? NetworkImage(review.authorAvatarUrl!)
                : null,
            child:
                (review.authorAvatarUrl == null ||
                    review.authorAvatarUrl!.isEmpty)
                ? Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        review.authorName.isNotEmpty
                            ? review.authorName
                            : 'Usuario',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      _timeAgo(review.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: List.generate(5, (i) {
                    final filled = i < review.rating;
                    return Icon(
                      filled ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 13,
                      color: const Color(0xFFF59E0B),
                    );
                  }),
                ),
                if (review.comment.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    review.comment,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ---- Bottom sheet para escribir una reseña -------------------------------

class _WriteReviewSheet extends StatefulWidget {
  final String productId;
  final String sellerId;

  const _WriteReviewSheet({required this.productId, required this.sellerId});

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<String> _fetchAuthorName(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!doc.exists || doc.data() == null) return 'Usuario';
      final profile = UserProfile.fromMap(doc.data()!, uid);
      return profile.name.trim().isNotEmpty ? profile.name : 'Usuario';
    } catch (_) {
      return 'Usuario';
    }
  }

  Future<void> _submit() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un comentario antes de enviar')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final authorName = await _fetchAuthorName(uid);
      await FirestoreService.addProductReview(
        productId: widget.productId,
        sellerId: widget.sellerId,
        authorId: uid,
        authorName: authorName,
        rating: _rating,
        comment: _commentController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('¡Gracias por tu reseña!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo enviar la reseña: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Escribe tu reseña',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final starIndex = i + 1;
                  final filled = starIndex <= _rating;
                  return IconButton(
                    onPressed: () => setState(() => _rating = starIndex),
                    icon: Icon(
                      filled ? Icons.star_rounded : Icons.star_border_rounded,
                      color: const Color(0xFFF59E0B),
                      size: 32,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 300,
              decoration: InputDecoration(
                hintText:
                    'Cuéntanos cómo fue tu experiencia con este producto...',
                filled: true,
                fillColor: AppColors.fieldFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Publicar reseña',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
