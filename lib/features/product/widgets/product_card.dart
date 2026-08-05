import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/firestore_service.dart'; // ajusta la ruta real
import '../models/product.dart';

/// -----------------------------------------------------------------------
/// TARJETA DE PRODUCTO
/// Se usa en el Home, en el listado/buscador de productos, en favoritos,
/// etc. Así evitamos tener el mismo diseño duplicado en cada pantalla.
///
/// CAMBIO: antes el corazón era un "bool _isFavorite" local que se
/// inicializaba con product.isFavorite (que Firestore ni siquiera
/// llenaba) y solo hacía setState. Ahora es un StatelessWidget que
/// escucha en vivo si el usuario logueado marcó ESTE producto como
/// favorito, y al tocarlo guarda/borra en Firestore de verdad.
/// -----------------------------------------------------------------------
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _toggleFavorite(BuildContext context) async {
    final uid = _uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para guardar favoritos')),
      );
      return;
    }
    try {
      await FirestoreService.toggleFavorite(uid: uid, productId: product.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar favoritos: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.15,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.fieldFill,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: _ConditionBadge(condition: product.condition),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: StreamBuilder<bool>(
                      stream: uid == null
                          ? null
                          : FirestoreService.watchIsFavorite(uid, product.id),
                      builder: (context, snap) {
                        final isFavorite = snap.data ?? false;
                        return GestureDetector(
                          onTap: () => _toggleFavorite(context),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 16,
                              color: isFavorite
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'S/${product.price.toStringAsFixed(product.price.truncateToDouble() == product.price ? 0 : 2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.category} · ${product.timeAgo}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConditionBadge extends StatelessWidget {
  final ProductCondition condition;
  const _ConditionBadge({required this.condition});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: condition.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        condition.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
