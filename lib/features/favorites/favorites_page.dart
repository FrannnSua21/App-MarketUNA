import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/services/firestore_service.dart';
import '../product/models/product.dart';
import '../product/widgets/product_card.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    final responsive = Responsive(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Favoritos',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: uid == null
          ? const _EmptyState(
              icon: Icons.lock_outline,
              title: 'Inicia sesión',
              subtitle: 'Necesitas una cuenta para guardar favoritos.',
            )
          : StreamBuilder<List<Product>>(
              stream: FirestoreService.watchUserFavorites(uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snap.hasError) {
                  return _EmptyState(
                    icon: Icons.error_outline,
                    title: 'Ocurrió un error',
                    subtitle: '${snap.error}',
                  );
                }

                final favorites = snap.data ?? [];

                if (favorites.isEmpty) {
                  return const _EmptyState(
                    icon: Icons.favorite_border,
                    title: 'Sin favoritos todavía',
                    subtitle:
                        'Toca el corazón en cualquier publicación para guardarla aquí.',
                  );
                }

                return GridView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.horizontalPadding,
                    vertical: AppSpacing.md,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 0.62,
                  ),
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final product = favorites[index];
                    return ProductCard(
                      product: product,
                      onTap: () => context.push('/product/${product.id}'),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
