import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/services/firestore_service.dart'; // ajusta la ruta real
import '../../core/services/transaction_service.dart';
import '../profile/models/profile_models.dart';
import 'models/product.dart';
import 'widgets/product_card.dart';

import 'package:url_launcher/url_launcher.dart';

import 'widgets/product_reviews_section.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;
  final bool isAdminView;

  const ProductDetailPage({
    super.key,
    required this.productId,
    this.isAdminView = false,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final PageController _pageController = PageController();
  int _currentImage = 0;
  bool _isLoading = true;
  Product? _product;

  bool _isBuying = false;

  Stream<bool>? _favoriteStream;

  Stream<ProfileTransaction?>? _myRequestStream;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final product = await FirestoreService.getProductById(widget.productId);
    if (!mounted) return;
    setState(() {
      _product = product;
      _isLoading = false;
    });
    if (product != null) {
      FirestoreService.incrementProductViews(product.id);

      final uid = _uid;

      if (uid != null) {
        setState(() {
          _favoriteStream = FirestoreService.watchIsFavorite(uid, product.id);
        });
      }

      if (uid != null && uid != product.sellerId) {
        setState(() {
          _myRequestStream = TransactionService.watchMyLatestRequest(
            productId: product.id,
            buyerId: uid,
          );
        });
      }
    }
  }

  Future<void> _toggleFavorite(String productId) async {
    final uid = _uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para guardar favoritos')),
      );
      return;
    }
    try {
      await FirestoreService.toggleFavorite(uid: uid, productId: productId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar favoritos: $e')),
      );
    }
  }

  Future<String> _fetchBuyerName(String uid) async {
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

  Future<void> _handleBuy() async {
    final product = _product;
    final uid = _uid;
    if (product == null || uid == null) return;

    setState(() => _isBuying = true);
    try {
      final buyerName = await _fetchBuyerName(uid);
      await TransactionService.createPurchaseRequest(
        product: product,
        buyerId: uid,
        buyerName: buyerName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud enviada al vendedor')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isBuying = false);
    }
  }

  // ==========================================================================
  // Modal "Escribir al WhatsApp" + redirección con el número
  // del vendedor ya registrado.
  // ==========================================================================

  Future<void> _openWhatsAppModal() async {
    final product = _product;
    if (product == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chat,
                        color: Color(0xFF25D366),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: Text(
                        'Escribir al WhatsApp',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Se abrirá WhatsApp para chatear con ${product.seller.name} '
                  'sobre "${product.title}".',
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _contactSeller(product);
                    },
                    icon: const Icon(Icons.chat, size: 18, color: Colors.white),
                    label: const Text(
                      'Ir a WhatsApp',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _contactSeller(Product product) async {
    try {
      final sellerProfile = await FirestoreService.getUserProfile(
        product.sellerId,
      );
      final phone = sellerProfile?.phone ?? '';

      if (phone.trim().isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'El vendedor no tiene un número de WhatsApp registrado',
            ),
          ),
        );
        return;
      }

      final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
      final message = Uri.encodeComponent(
        'Hola ${product.seller.name}, te escribo por tu publicación '
        '"${product.title}" en la app.',
      );

      final whatsappAppUri = Uri.parse(
        'whatsapp://send?phone=$cleanPhone&text=$message',
      );
      final whatsappWebUri = Uri.parse(
        'https://wa.me/$cleanPhone?text=$message',
      );

      bool launched = false;
      try {
        launched = await launchUrl(
          whatsappAppUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        launched = false;
      }

      if (!launched) {
        try {
          launched = await launchUrl(
            whatsappWebUri,
            mode: LaunchMode.externalApplication,
          );
        } catch (_) {
          launched = false;
        }
      }

      if (!launched) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir WhatsApp')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al abrir WhatsApp: $e')));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final product = _product;
    if (product == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
        body: const Center(child: Text('Producto no encontrado')),
      );
    }

    final isOwner = _uid != null && _uid == product.sellerId;
    final responsive = Responsive(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: StreamBuilder<bool>(
              stream: _favoriteStream,
              builder: (context, favSnap) {
                final isFavorite = favSnap.data ?? false;
                return _ImageCarousel(
                  imageUrls: product.imageUrls,
                  pageController: _pageController,
                  currentIndex: _currentImage,
                  onPageChanged: (index) =>
                      setState(() => _currentImage = index),
                  isFavorite: isFavorite,
                  onBack: () => context.pop(),
                  onToggleFavorite: () => _toggleFavorite(product.id),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.horizontalPadding,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.title,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: product.condition.color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          product.condition.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'S/${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_offer_outlined,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        product.category,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Icon(
                        Icons.access_time_rounded,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        product.timeAgo,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        product.location,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: AppSpacing.xl, color: AppColors.border),
                  _SellerCard(
                    seller: product.seller,
                    sellerId: product.sellerId,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    'Descripción',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    product.description.isNotEmpty
                        ? product.description
                        : 'El vendedor no agregó una descripción.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  ProductReviewsSection(
                    // NUEVO
                    productId: product.id,
                    sellerId: product.sellerId,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Text(
                    'Publicaciones similares',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 230,
                    child: StreamBuilder<List<Product>>(
                      stream: FirestoreService.watchFeed(
                        category: product.category,
                      ),
                      builder: (context, snap) {
                        final related = (snap.data ?? [])
                            .where((p) => p.id != product.id)
                            .take(4)
                            .toList();
                        if (related.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: related.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final item = related[index];
                            return SizedBox(
                              width: 150,
                              child: ProductCard(
                                product: item,
                                onTap: () =>
                                    context.push('/product/${item.id}'),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isOwner
          ? _OwnerActionsBar(
              onEdit: () => context.push('/product/${product.id}/edit'),
              onDelete: () => _confirmDelete(context, product.id),
            )
          : StreamBuilder<ProfileTransaction?>(
              stream: _myRequestStream,
              builder: (context, reqSnap) {
                final latest = reqSnap.data;
                final alreadyRequested =
                    latest?.status == TransactionStatus.enProceso;

                return _BuyerActionsBar(
                  isSold: product.status == ProductStatus.vendida,
                  alreadyRequested: alreadyRequested,
                  isProcessing: _isBuying,
                  onMessage: _openWhatsAppModal,
                  onBuy: _handleBuy,
                );
              },
            ),
    );
  }

  void _confirmDelete(BuildContext context, String productId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        title: const Text('Eliminar publicación'),
        content: const Text(
          '¿Seguro que quieres eliminar esta publicación? Esta acción no se puede deshacer.',
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
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await FirestoreService.deleteProduct(productId);
              if (mounted) context.pop();
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

class _ImageCarousel extends StatelessWidget {
  final List<String> imageUrls;
  final PageController pageController;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final bool isFavorite;
  final VoidCallback onBack;
  final VoidCallback onToggleFavorite;

  const _ImageCarousel({
    required this.imageUrls,
    required this.pageController,
    required this.currentIndex,
    required this.onPageChanged,
    required this.isFavorite,
    required this.onBack,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Stack(
        children: [
          PageView.builder(
            controller: pageController,
            onPageChanged: onPageChanged,
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              return Image.network(
                imageUrls[index],
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.fieldFill,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.textSecondary,
                    size: 40,
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 12,
            left: 16,
            child: SafeArea(
              bottom: false,
              child: _CircleIconButton(icon: Icons.arrow_back, onTap: onBack),
            ),
          ),
          Positioned(
            top: 12,
            right: 16,
            child: SafeArea(
              bottom: false,
              child: _CircleIconButton(
                icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                iconColor: isFavorite ? AppColors.error : AppColors.textPrimary,
                onTap: onToggleFavorite,
              ),
            ),
          ),
          if (imageUrls.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(imageUrls.length, (index) {
                  final isActive = index == currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }
}

class _SellerCard extends StatelessWidget {
  final SellerInfo seller;
  final String sellerId;
  const _SellerCard({required this.seller, required this.sellerId});

  @override
  Widget build(BuildContext context) {
    final initials = seller.name.trim().isNotEmpty
        ? seller.name.trim()[0].toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  seller.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 15,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      seller.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      ' · ${seller.totalSales} ventas',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: sellerId.isEmpty
                ? null
                : () {
                    final currentUid = FirebaseAuth.instance.currentUser?.uid;
                    if (currentUid != null && currentUid == sellerId) {
                      context.push('/profile');
                    } else {
                      context.push('/seller/$sellerId');
                    }
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            child: const Text('Ver perfil', style: TextStyle(fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}

class _BuyerActionsBar extends StatelessWidget {
  final bool isSold;
  final bool alreadyRequested;
  final bool isProcessing;
  final VoidCallback onMessage;
  final VoidCallback onBuy;

  const _BuyerActionsBar({
    required this.isSold,
    required this.alreadyRequested,
    required this.isProcessing,
    required this.onMessage,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final canBuy = !isSold && !alreadyRequested && !isProcessing;

    String label;
    if (isSold) {
      label = 'Producto vendido';
    } else if (alreadyRequested) {
      label = 'Solicitud enviada';
    } else {
      label = 'Comprar ahora';
    }

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isSold ? null : onMessage,
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('Mensaje'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: canBuy ? onBuy : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSold
                      ? AppColors.textSecondary
                      : AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                child: isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        label,
                        style: const TextStyle(
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

class _OwnerActionsBar extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _OwnerActionsBar({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Eliminar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Editar publicación'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
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
