import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/services/firestore_service.dart';
import 'models/profile_models.dart';
import 'widgets/profile_widgets.dart';

/// -----------------------------------------------------------------------
/// PANTALLA DE PERFIL
/// Se abre al tocar el avatar/usuario en el Home. Lee el perfil real desde
/// Firestore (users/{uid}) en tiempo real, igual que HomePage.
/// -----------------------------------------------------------------------
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _notificationsEnabled = true;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

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
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: Text('Error: ${snap.error}')),
          );
        }

        final user = snap.data;
        if (user == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: Text('No se encontró tu perfil')),
          );
        }

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
                  user: user,
                  onBack: () => context.pop(),
                  onEditProfile: () => _openEditProfile(user),
                ),

                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.horizontalPadding,
                    vertical: AppSpacing.lg,
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      _FieldCardLike(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (user.career.isNotEmpty ||
                                user.universityCode.isNotEmpty) ...[
                              Row(
                                children: [
                                  const Icon(
                                    Icons.school_outlined,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      user.career.isNotEmpty
                                          ? user.career
                                          : 'Carrera sin especificar',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ),
                                  if (user.universityCode.isNotEmpty)
                                    Text(
                                      'Código: ${user.universityCode}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _MiniStat(
                                  label: 'Siguiendo',
                                  value: '${user.following}',
                                ),
                                _MiniStat(
                                  label: 'Seguidores',
                                  value: '${user.followers}',
                                ),
                                _MiniStat(
                                  label: 'Favoritos',
                                  value: '${user.favoritesCount}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      const SectionLabel('Mi cuenta'),
                      const SizedBox(height: AppSpacing.sm),

                      MenuCard(
                        children: [
                          MenuTile(
                            icon: Icons.person_outline,
                            color: AppColors.primary,
                            label: 'Editar perfil',
                            onTap: () => _openEditProfile(user),
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
                            onTap: () =>
                                context.push('/profile/payment-methods'),
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
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.7,
                            ),
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
      },
    );
  }

  Future<void> _openEditProfile(UserProfile user) async {
    // ProfileEditPage guarda directo en Firestore. Como este StreamBuilder
    // escucha en vivo, no hace falta hacer nada con el valor de retorno:
    // la UI se actualiza sola en cuanto se guarde.
    await context.push('/profile/edit', extra: user);
  }

  Future<void> _openLanguage() async {
    await context.push('/profile/language');
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
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await FirebaseAuth.instance.signOut();
              if (context.mounted) context.go('/login');
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

class _FieldCardLike extends StatelessWidget {
  final Widget child;
  const _FieldCardLike({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
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
