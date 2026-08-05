import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../product/models/product.dart';
import '../product/widgets/product_card.dart';
import 'models/profile_models.dart';

/// Perfil PÚBLICO de un vendedor, visto por otros usuarios de la app.
/// No confundir con ProfilePage: esa es la del usuario con sesión
/// iniciada (con opciones de editar, cerrar sesión, etc). Esta es
/// de solo lectura.
class SellerProfilePage extends StatefulWidget {
  final String userId;

  const SellerProfilePage({super.key, required this.userId});

  @override
  State<SellerProfilePage> createState() => _SellerProfilePageState();
}

class _SellerProfilePageState extends State<SellerProfilePage> {
  bool _isLoading = true;
  UserProfile? _user;

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (!mounted) return;
      if (doc.exists && doc.data() != null) {
        setState(() {
          _user = UserProfile.fromMap(doc.data()!, doc.id);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Stream<List<Product>> _watchSellerProducts() {
    return FirebaseFirestore.instance
        .collection('products')
        .where('sellerId', isEqualTo: widget.userId)
        .where('status', isEqualTo: ProductStatus.activa.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Product.fromMap(d.data(), d.id)).toList(),
        );
  }

  // ==========================================================================
  // Modal "Escribir al WhatsApp" + redirección al número del vendedor.
  // ==========================================================================

  Future<void> _openWhatsAppModal(UserProfile seller) async {
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
                  'Se abrirá WhatsApp para chatear con ${seller.name}.',
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
                      _contactSeller(seller);
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

  Future<void> _contactSeller(UserProfile seller) async {
    try {
      final phone = seller.phone;

      if (phone.trim().isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Este usuario no tiene un número de WhatsApp registrado',
            ),
          ),
        );
        return;
      }

      final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
      final message = Uri.encodeComponent(
        'Hola ${seller.name}, vi tu perfil en la app y quería consultarte.',
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Perfil del vendedor',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
          ? const Center(child: Text('No se pudo cargar este perfil.'))
          : _buildBody(_user!),
    );
  }

  Widget _buildBody(UserProfile user) {
    final responsive = Responsive(context);
    final isSelf = _currentUid != null && _currentUid == user.id;

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
      children: [
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.primary,
            backgroundImage:
                (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                ? Text(
                    user.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Text(
            user.name,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (user.career.isNotEmpty) ...[
          const SizedBox(height: 2),
          Center(
            child: Text(
              user.career,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                size: 18,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(width: 4),
              Text(
                user.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                ' (${user.ratingCount})',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),

        // ---- NUEVO: botón de contacto por WhatsApp ----
        if (!isSelf) ...[
          const SizedBox(height: AppSpacing.md),
          _WhatsAppContactCard(
            sellerName: user.name,
            onTap: () => _openWhatsAppModal(user),
          ),
        ],

        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: _StatItem(label: 'Ventas', value: '${user.totalVentas}'),
              ),
              Container(width: 1, height: 34, color: AppColors.border),
              Expanded(
                child: _StatItem(
                  label: 'Compras',
                  value: '${user.totalCompras}',
                ),
              ),
              Container(width: 1, height: 34, color: AppColors.border),
              Expanded(
                child: _StatItem(
                  label: 'Miembro desde',
                  value: '${user.memberSince.year}',
                ),
              ),
            ],
          ),
        ),
        if (user.bio.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Sobre mí',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            user.bio,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        const Text(
          'Publicaciones activas',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        StreamBuilder<List<Product>>(
          stream: _watchSellerProducts(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final products = snap.data ?? [];
            if (products.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(
                  child: Text(
                    'Este usuario no tiene publicaciones activas.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 0.68,
              ),
              itemBuilder: (context, index) {
                final item = products[index];
                return ProductCard(
                  product: item,
                  onTap: () => context.push('/product/${item.id}'),
                );
              },
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// ---- NUEVO: tarjeta de contacto por WhatsApp -----------------------------
/// Un botón más vistoso que un OutlinedButton plano: fondo con degradado
/// suave del verde de WhatsApp, ícono en burbuja circular y flecha de
/// "acción" a la derecha para que se lea como algo tappable.
class _WhatsAppContactCard extends StatelessWidget {
  final String sellerName;
  final VoidCallback onTap;

  const _WhatsAppContactCard({required this.sellerName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF25D366), Color(0xFF1DA851)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF25D366).withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat, color: Colors.white, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contactar por WhatsApp',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Respuesta rápida y directa',
                        style: TextStyle(color: Colors.white70, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
