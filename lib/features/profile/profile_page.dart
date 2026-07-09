import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import 'models/profile_models.dart';
import 'widgets/profile_widgets.dart';

/// -----------------------------------------------------------------------
/// PANTALLA DE PERFIL
/// Se abre al tocar el avatar/usuario en el Home. Incluye datos del
/// usuario, estadísticas rápidas y las secciones de configuración.
/// -----------------------------------------------------------------------
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late UserProfile _user = MockProfileRepository.currentUser;
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final selectedLanguage = MockProfileRepository.availableLanguages
        .firstWhere(
          (l) => l.code == MockProfileRepository.selectedLanguageCode,
          orElse: () => MockProfileRepository.availableLanguages.first,
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _ProfileHeader(
              user: _user,
              onBack: () => context.pop(),
              onEditProfile: _openEditProfile,
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.horizontalPadding,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Mi cuenta'),
                  const SizedBox(height: AppSpacing.sm),
                  MenuCard(
                    children: [
                      MenuTile(
                        icon: Icons.person_outline,
                        color: AppColors.primary,
                        label: 'Editar perfil',
                        onTap: _openEditProfile,
                      ),
                      MenuTile(
                        icon: Icons.storefront_outlined,
                        color: AppColors.secondary,
                        label: 'Mis publicaciones',
                        subtitle:
                            '${MockProfileRepository.myListings.length} publicaciones',
                        onTap: () => context.push('/profile/listings'),
                      ),
                      MenuTile(
                        icon: Icons.favorite_border,
                        color: AppColors.error,
                        label: 'Favoritos',
                        onTap: () => context.push('/favorites'),
                      ),
                      MenuTile(
                        icon: Icons.receipt_long_outlined,
                        color: const Color(0xFF0EA5E9),
                        label: 'Historial de compras y ventas',
                        onTap: () => context.push('/profile/history'),
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const SectionLabel('Configuración'),
                  const SizedBox(height: AppSpacing.sm),
                  MenuCard(
                    children: [
                      MenuTile(
                        icon: Icons.notifications_none_rounded,
                        color: const Color(0xFFF59E0B),
                        label: 'Notificaciones',
                        trailing: Switch(
                          value: _notificationsEnabled,
                          activeThumbColor: AppColors.primary,
                          onChanged: (value) {
                            setState(() => _notificationsEnabled = value);
                            // TODO: guarda la preferencia en tu backend/local storage
                          },
                        ),
                      ),
                      MenuTile(
                        icon: Icons.lock_outline,
                        color: AppColors.textSecondary,
                        label: 'Privacidad y seguridad',
                        onTap: () => context.push('/profile/security'),
                      ),
                      MenuTile(
                        icon: Icons.credit_card,
                        color: AppColors.success,
                        label: 'Métodos de pago',
                        subtitle:
                            '${MockProfileRepository.paymentMethods.length} guardados',
                        onTap: () => context.push('/profile/payment-methods'),
                      ),
                      MenuTile(
                        icon: Icons.language,
                        color: const Color(0xFF7C6FEE),
                        label: 'Idioma',
                        trailingText: selectedLanguage.name,
                        onTap: _openLanguage,
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const SectionLabel('Soporte'),
                  const SizedBox(height: AppSpacing.sm),
                  MenuCard(
                    children: [
                      MenuTile(
                        icon: Icons.help_outline,
                        color: AppColors.primary,
                        label: 'Centro de ayuda',
                        onTap: () => context.push('/help'),
                      ),
                      MenuTile(
                        icon: Icons.description_outlined,
                        color: AppColors.textSecondary,
                        label: 'Términos y condiciones',
                        onTap: () => context.push('/terms'),
                      ),
                      MenuTile(
                        icon: Icons.info_outline,
                        color: AppColors.textSecondary,
                        label: 'Acerca de',
                        onTap: () => context.push('/about'),
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  MenuCard(
                    children: [
                      MenuTile(
                        icon: Icons.logout,
                        color: AppColors.error,
                        label: 'Cerrar sesión',
                        labelColor: AppColors.error,
                        showChevron: false,
                        onTap: () => _confirmLogout(context),
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Center(
                    child: Text(
                      'Versión 1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditProfile() async {
    final updated = await context.push<UserProfile>(
      '/profile/edit',
      extra: _user,
    );
    if (updated != null) {
      setState(() {
        _user = updated;
        MockProfileRepository.currentUser = updated;
      });
    }
  }

  Future<void> _openLanguage() async {
    await context.push('/profile/language');
    // El código de idioma se guarda en MockProfileRepository; solo
    // refrescamos la etiqueta al volver.
    if (mounted) setState(() {});
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar tu sesión?'),
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
              Navigator.of(dialogContext).pop();
              // TODO: llama a tu AuthService/AuthProvider para cerrar sesión real
              context.go('/login');
            },
            child: const Text(
              'Cerrar sesión',
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

/// -----------------------------------------------------------------------
/// HEADER DEGRADADO CON DATOS DEL USUARIO Y ESTADÍSTICAS
/// -----------------------------------------------------------------------
class _ProfileHeader extends StatelessWidget {
  final UserProfile user;
  final VoidCallback onBack;
  final VoidCallback onEditProfile;

  const _ProfileHeader({
    required this.user,
    required this.onBack,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.xl),
          bottomRight: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const Expanded(
                child: Text(
                  'Mi perfil',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 38),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            backgroundImage: user.avatarUrl != null
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null
                ? Text(
                    user.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            user.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            user.email,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: onEditProfile,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text(
              'Editar perfil',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                ProfileStatItem(value: '${user.totalVentas}', label: 'Ventas'),
                const VerticalStatDivider(),
                ProfileStatItem(
                  value: '${user.totalCompras}',
                  label: 'Compras',
                ),
                const VerticalStatDivider(),
                ProfileStatItem(
                  value: user.rating.toStringAsFixed(1),
                  label: 'Calificación',
                  icon: Icons.star_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
