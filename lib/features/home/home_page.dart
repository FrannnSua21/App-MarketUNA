import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/services/firestore_service.dart'; // ajusta la ruta real en tu proyecto
import '../product/models/product.dart';
import '../product/widgets/product_card.dart';
import '../profile/models/profile_models.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedCategory = 'Todos';

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  void _onSelectCategoryFromDrawer(String category) {
    setState(() => _selectedCategory = category);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final uid = _uid;

    if (uid == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<UserProfile?>(
      stream: FirestoreService.watchUserProfile(uid),
      builder: (context, userSnap) {
        if (userSnap.hasError) {
          // Esto te va a decir EXACTAMENTE qué está fallando (permisos, etc.)
          debugPrint('Error leyendo perfil: ${userSnap.error}');
        }
        final userName = userSnap.data?.name ?? 'Usuario';

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.background,
          drawer: _MainDrawer(
            userName: userName,
            onSelectCategory: _onSelectCategoryFromDrawer,
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.horizontalPadding,
                  vertical: AppSpacing.md,
                ),
                children: [
                  _HomeHeader(profile: userSnap.data, notificationCount: 0),
                  const SizedBox(height: AppSpacing.md),
                  _SearchBarRow(
                    onSearchTap: () => context.push('/search'),
                    onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                    onCartTap: () => context.push('/cart'),
                    cartItemCount: 0,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _CategoryChips(
                    categories: productCategories,
                    selected: _selectedCategory,
                    onSelected: (cat) =>
                        setState(() => _selectedCategory = cat),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _SellBanner(onPublish: () => context.push('/publish')),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recientes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/search'),
                        child: const Text(
                          'Ver todos',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  StreamBuilder<List<Product>>(
                    stream: FirestoreService.watchFeed(
                      category: _selectedCategory == 'Todos'
                          ? null
                          : _selectedCategory,
                    ),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snap.hasError) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: Text('Error: ${snap.error}')),
                        );
                      }
                      final products = snap.data ?? [];
                      if (products.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text('Todavía no hay publicaciones'),
                          ),
                        );
                      }
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: products.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: AppSpacing.md,
                              crossAxisSpacing: AppSpacing.md,
                              childAspectRatio: 0.68,
                            ),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return ProductCard(
                            product: product,
                            onTap: () => context.push('/product/${product.id}'),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// -----------------------------------------------------------------------
/// HEADER: avatar, saludo, nombre, correo, campana + tarjeta de stats
/// (rating, ventas, compras) leídos en vivo de users/{uid}
/// -----------------------------------------------------------------------
class _HomeHeader extends StatelessWidget {
  final UserProfile? profile;
  final int notificationCount;

  const _HomeHeader({required this.profile, required this.notificationCount});

  String _saludoSegunHora() {
    final hora = DateTime.now().hour;
    if (hora >= 5 && hora < 12) return 'Buenos días';
    if (hora >= 12 && hora < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    final userName = profile?.name ?? 'Usuario';
    final initials = userName.trim().isNotEmpty
        ? userName.trim().substring(0, 1).toUpperCase()
        : '?';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => context.push('/profile'),
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
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _saludoSegunHora(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (profile?.email != null &&
                              profile!.email.isNotEmpty)
                            Text(
                              profile!.email,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          if (profile?.phone != null &&
                              profile!.phone.isNotEmpty)
                            Text(
                              profile!.phone,
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
            ),
            const SizedBox(width: AppSpacing.sm),
            _NotificationBell(
              count: notificationCount,
              onTap: () => context.push('/notifications'),
            ),
          ],
        ),
        if (profile != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  icon: Icons.star_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  label: profile!.rating.toStringAsFixed(1),
                  sub: '${profile!.ratingCount} reseñas',
                ),
                const _StatDivider(),
                _StatItem(
                  icon: Icons.sell_outlined,
                  iconColor: AppColors.primary,
                  label: '${profile!.totalVentas}',
                  sub: 'Ventas',
                ),
                const _StatDivider(),
                _StatItem(
                  icon: Icons.shopping_bag_outlined,
                  iconColor: AppColors.secondary,
                  label: '${profile!.totalCompras}',
                  sub: 'Compras',
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String sub;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          style: const TextStyle(
            fontSize: 10.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 28, color: AppColors.border);
}

class _NotificationBell extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _NotificationBell({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.textPrimary,
              size: 22,
            ),
          ),
          if (count > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.fieldFill,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            Icon(Icons.search, size: 20, color: AppColors.textSecondary),
            SizedBox(width: AppSpacing.sm),
            Text(
              'Buscar productos...',
              style: TextStyle(color: Color(0xFFB0B6C3), fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBarRow extends StatelessWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onMenuTap;
  final VoidCallback onCartTap;
  final int cartItemCount;

  const _SearchBarRow({
    required this.onSearchTap,
    required this.onMenuTap,
    required this.onCartTap,
    this.cartItemCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SearchBar(onTap: onSearchTap)),
        const SizedBox(width: AppSpacing.sm),
        _CircleIconButton(
          icon: Icons.menu_rounded,
          tooltip: 'Menú',
          onTap: onMenuTap,
        ),
        const SizedBox(width: AppSpacing.sm),
        _CircleIconButton(
          icon: Icons.shopping_cart_outlined,
          tooltip: 'Carrito',
          onTap: onCartTap,
          badgeCount: cartItemCount,
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final int badgeCount;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, color: AppColors.textPrimary, size: 22),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badgeCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selected;
          return GestureDetector(
            onTap: () => onSelected(category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SellBanner extends StatelessWidget {
  final VoidCallback onPublish;
  const _SellBanner({required this.onPublish});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¡Vende hoy mismo!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Publica gratis en segundos',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          ElevatedButton(
            onPressed: onPublish,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            child: const Text(
              'Publicar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _MainDrawer extends StatelessWidget {
  final String userName;
  final ValueChanged<String>? onSelectCategory;

  const _MainDrawer({required this.userName, this.onSelectCategory});

  void _comingSoon(BuildContext context, String feature) {
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature: próximamente')));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            _DrawerHeader(userName: userName),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                children: [
                  _DrawerItem(
                    icon: Icons.home_rounded,
                    label: 'Inicio',
                    onTap: () => Navigator.pop(context),
                  ),
                  _DrawerItem(
                    icon: Icons.local_offer_outlined,
                    label: 'Ofertas',
                    onTap: () => _comingSoon(context, 'Ofertas'),
                  ),
                  _DrawerItem(
                    icon: Icons.play_circle_outline_rounded,
                    label: 'Mercado Play',
                    trailing: const _Badge(text: 'GRATIS'),
                    onTap: () => _comingSoon(context, 'Mercado Play'),
                  ),
                  _DrawerItem(
                    icon: Icons.history_rounded,
                    label: 'Historial',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/profile/history');
                    },
                  ),
                  const Divider(
                    height: AppSpacing.md,
                    indent: AppSpacing.md,
                    endIndent: AppSpacing.md,
                    color: AppColors.border,
                  ),
                  _DrawerItem(
                    icon: Icons.checkroom_outlined,
                    label: 'Moda',
                    onTap: () => _comingSoon(context, 'Moda'),
                  ),
                  _DrawerItem(
                    icon: Icons.star_border_rounded,
                    label: 'Más vendidos',
                    onTap: () => _comingSoon(context, 'Más vendidos'),
                  ),
                  _DrawerItem(
                    icon: Icons.storefront_outlined,
                    label: 'Tiendas oficiales',
                    onTap: () => _comingSoon(context, 'Tiendas oficiales'),
                  ),
                  _CategoriesExpansionTile(onSelectCategory: onSelectCategory),
                  const Divider(
                    height: AppSpacing.md,
                    indent: AppSpacing.md,
                    endIndent: AppSpacing.md,
                    color: AppColors.border,
                  ),
                  _DrawerItem(
                    icon: Icons.receipt_long_outlined,
                    label: 'Resumen',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/profile/listings');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.sell_outlined,
                    label: 'Vender',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/publish');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Ayuda',
                    onTap: () => _comingSoon(context, 'Ayuda'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final String userName;
  const _DrawerHeader({required this.userName});

  @override
  Widget build(BuildContext context) {
    final initials = userName.trim().isNotEmpty
        ? userName.trim().substring(0, 1).toUpperCase()
        : '?';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white,
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/profile');
                  },
                  child: const Text(
                    'Ver mi perfil',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white70,
                    ),
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

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary, size: 22),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: trailing,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      onTap: onTap,
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _CategoriesExpansionTile extends StatelessWidget {
  final ValueChanged<String>? onSelectCategory;
  const _CategoriesExpansionTile({this.onSelectCategory});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        childrenPadding: const EdgeInsets.only(
          left: AppSpacing.xl,
          bottom: AppSpacing.sm,
        ),
        leading: const Icon(
          Icons.list_alt_rounded,
          color: AppColors.textPrimary,
          size: 22,
        ),
        title: const Text(
          'Categorías',
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        children: productCategories
            .where((category) => category != 'Todos')
            .map(
              (category) => ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                title: Text(
                  category,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onSelectCategory?.call(category);
                },
              ),
            )
            .toList(),
      ),
    );
  }
}
