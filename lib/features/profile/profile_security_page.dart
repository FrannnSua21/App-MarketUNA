import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import 'models/profile_models.dart';
import 'widgets/profile_widgets.dart';

/// -----------------------------------------------------------------------
/// PRIVACIDAD Y SEGURIDAD
/// Cambio de contraseña, preferencias de seguridad, sesiones activas y
/// zona de peligro (eliminar cuenta).
/// -----------------------------------------------------------------------
class ProfileSecurityPage extends StatefulWidget {
  const ProfileSecurityPage({super.key});

  @override
  State<ProfileSecurityPage> createState() => _ProfileSecurityPageState();
}

class _ProfileSecurityPageState extends State<ProfileSecurityPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _biometricEnabled = false;
  bool _twoFactorEnabled = false;
  bool _savingPassword = false;

  late List<ActiveSession> _sessions = List.of(MockProfileRepository.activeSessions);

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientSubHeader(
        title: 'Privacidad y seguridad',
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.horizontalPadding,
            vertical: AppSpacing.lg,
          ),
          children: [
            const SectionLabel('Cambiar contraseña'),
            const SizedBox(height: AppSpacing.sm),
            _Card(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _PasswordField(
                      controller: _currentCtrl,
                      label: 'Contraseña actual',
                      obscure: _obscureCurrent,
                      onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                      validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu contraseña actual' : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _PasswordField(
                      controller: _newCtrl,
                      label: 'Nueva contraseña',
                      obscure: _obscureNew,
                      onToggle: () => setState(() => _obscureNew = !_obscureNew),
                      validator: (v) =>
                          (v == null || v.length < 6) ? 'Debe tener al menos 6 caracteres' : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _PasswordField(
                      controller: _confirmCtrl,
                      label: 'Confirmar nueva contraseña',
                      obscure: _obscureConfirm,
                      onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      validator: (v) => v != _newCtrl.text ? 'Las contraseñas no coinciden' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _savingPassword ? null : _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                        child: _savingPassword
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                              )
                            : const Text('Actualizar contraseña',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionLabel('Preferencias de seguridad'),
            const SizedBox(height: AppSpacing.sm),
            MenuCard(
              children: [
                MenuTile(
                  icon: Icons.fingerprint,
                  color: AppColors.primary,
                  label: 'Inicio de sesión biométrico',
                  subtitle: 'Usa tu huella o Face ID para entrar',
                  trailing: Switch(
                    value: _biometricEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) => setState(() => _biometricEnabled = v),
                  ),
                ),
                MenuTile(
                  icon: Icons.verified_user_outlined,
                  color: AppColors.success,
                  label: 'Verificación en dos pasos',
                  subtitle: 'Añade una capa extra de seguridad',
                  trailing: Switch(
                    value: _twoFactorEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) => setState(() => _twoFactorEnabled = v),
                  ),
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionLabel('Sesiones activas'),
            const SizedBox(height: AppSpacing.sm),
            _Card(
              child: Column(
                children: List.generate(_sessions.length, (index) {
                  final session = _sessions[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(session.deviceIcon, size: 18, color: AppColors.primary),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      session.deviceName,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                    ),
                                  ),
                                  if (session.isCurrent) ...[
                                    const SizedBox(width: 6),
                                    const StatusChip(label: 'Este dispositivo', color: AppColors.success),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${session.location} · ${_lastActiveLabel(session)}',
                                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        if (!session.isCurrent)
                          TextButton(
                            onPressed: () => _closeSession(session),
                            child: const Text(
                              'Cerrar',
                              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionLabel('Zona de peligro'),
            const SizedBox(height: AppSpacing.sm),
            MenuCard(
              children: [
                MenuTile(
                  icon: Icons.delete_forever_outlined,
                  color: AppColors.error,
                  label: 'Eliminar mi cuenta',
                  labelColor: AppColors.error,
                  showChevron: false,
                  onTap: _confirmDeleteAccount,
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  String _lastActiveLabel(ActiveSession session) {
    if (session.isCurrent) return 'Activa ahora';
    final diff = DateTime.now().difference(session.lastActive);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} días';
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _savingPassword = true);

    // TODO: reemplaza por tu llamada real al backend/AuthService.
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _savingPassword = false);
    _currentCtrl.clear();
    _newCtrl.clear();
    _confirmCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contraseña actualizada correctamente')),
    );
  }

  void _closeSession(ActiveSession session) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        title: const Text('Cerrar sesión'),
        content: Text('¿Cerrar la sesión en "${session.deviceName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _sessions.removeWhere((s) => s.id == session.id);
                MockProfileRepository.activeSessions
                  ..clear()
                  ..addAll(_sessions);
              });
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Cerrar sesión', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        title: const Text('Eliminar mi cuenta'),
        content: const Text(
          'Esta acción es permanente. Se eliminarán tus publicaciones, historial y datos guardados. ¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // TODO: llama a tu backend para eliminar la cuenta real.
              context.go('/login');
            },
            child: const Text('Eliminar', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: child,
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppColors.textSecondary),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 20,
            color: AppColors.textSecondary,
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: AppSpacing.sm),
      ),
    );
  }
}