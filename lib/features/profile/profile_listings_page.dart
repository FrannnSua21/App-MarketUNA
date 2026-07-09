import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import 'models/profile_models.dart';
import 'widgets/profile_widgets.dart';

/// -----------------------------------------------------------------------
/// MIS PUBLICACIONES
/// Muestra las publicaciones del usuario agrupadas por estado, con
/// acciones para pausar/activar, editar o eliminar cada una.
/// -----------------------------------------------------------------------
class ProfileListingsPage extends StatefulWidget {
  const ProfileListingsPage({super.key});

  @override
  State<ProfileListingsPage> createState() => _ProfileListingsPageState();
}

class _ProfileListingsPageState extends State<ProfileListingsPage> {
  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final listings = MockProfileRepository.myListings;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: GradientSubHeader(
          title: 'Mis publicaciones',
          onBack: () => context.pop(),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                color: Colors.white,
                child: TabBar(
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  tabs: [
                    Tab(
                      text:
                          'Activas (${_count(listings, ListingStatus.activa)})',
                    ),
                    Tab(
                      text:
                          'Pausadas (${_count(listings, ListingStatus.pausada)})',
                    ),
                    Tab(
                      text:
                          'Vendidas (${_count(listings, ListingStatus.vendida)})',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _ListingsTab(
                      status: ListingStatus.activa,
                      responsive: responsive,
                      onChanged: () => setState(() {}),
                    ),
                    _ListingsTab(
                      status: ListingStatus.pausada,
                      responsive: responsive,
                      onChanged: () => setState(() {}),
                    ),
                    _ListingsTab(
                      status: ListingStatus.vendida,
                      responsive: responsive,
                      onChanged: () => setState(() {}),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Publicar'),
          onPressed: () {
            // Coincide con la ruta '/product/new' del router (ver TODO ahí
            // sobre el modo "crear" de ProductEditPage).
            context.push('/product/new');
          },
        ),
      ),
    );
  }

  int _count(List<MyListing> listings, ListingStatus status) =>
      listings.where((l) => l.status == status).length;
}

class _ListingsTab extends StatelessWidget {
  final ListingStatus status;
  final Responsive responsive;
  final VoidCallback onChanged;

  const _ListingsTab({
    required this.status,
    required this.responsive,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = MockProfileRepository.myListings
        .where((l) => l.status == status)
        .toList();

    if (items.isEmpty) {
      return ListView(
        padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
        children: [
          ProfileEmptyState(
            icon: status == ListingStatus.activa
                ? Icons.storefront_outlined
                : status == ListingStatus.pausada
                ? Icons.pause_circle_outline
                : Icons.sell_outlined,
            title: 'Nada por aquí todavía',
            message: status == ListingStatus.activa
                ? 'Cuando publiques un producto aparecerá en esta lista.'
                : status == ListingStatus.pausada
                ? 'Las publicaciones que pauses aparecerán aquí.'
                : 'Tus ventas completadas aparecerán aquí.',
          ),
        ],
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.horizontalPadding,
        vertical: AppSpacing.md,
      ),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) =>
          _ListingCard(listing: items[index], onChanged: onChanged),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final MyListing listing;
  final VoidCallback onChanged;

  const _ListingCard({required this.listing, required this.onChanged});

  @override
  Widget build(BuildContext context) {
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
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.image_outlined, color: AppColors.primary),
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
                        listing.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    StatusChip(
                      label: listing.status.label,
                      color: listing.status.color,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'S/ ${listing.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.visibility_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 3),
                    Text('${listing.views}', style: _metaStyle),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.favorite_border,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 3),
                    Text('${listing.favorites}', style: _metaStyle),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            onSelected: (value) => _handleAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Editar')),
              if (listing.status != ListingStatus.vendida)
                PopupMenuItem(
                  value: listing.status == ListingStatus.activa
                      ? 'pause'
                      : 'activate',
                  child: Text(
                    listing.status == ListingStatus.activa
                        ? 'Pausar publicación'
                        : 'Reactivar publicación',
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Eliminar',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const _metaStyle = TextStyle(
    fontSize: 11.5,
    color: AppColors.textSecondary,
  );

  void _handleAction(BuildContext context, String action) {
    final listings = MockProfileRepository.myListings;
    final index = listings.indexWhere((l) => l.id == listing.id);
    if (index == -1) return;

    switch (action) {
      case 'edit':
        // Coincide con la ruta '/product/:id/edit' del router.
        context.push('/product/${listing.id}/edit');
        return;
      case 'pause':
        listings[index] = listing.copyWith(status: ListingStatus.pausada);
        onChanged();
        return;
      case 'activate':
        listings[index] = listing.copyWith(status: ListingStatus.activa);
        onChanged();
        return;
      case 'delete':
        _confirmDelete(context, index);
        return;
    }
  }

  void _confirmDelete(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        title: const Text('Eliminar publicación'),
        content: Text(
          '¿Seguro que quieres eliminar "${listing.title}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              MockProfileRepository.myListings.removeAt(index);
              Navigator.of(dialogContext).pop();
              onChanged();
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
