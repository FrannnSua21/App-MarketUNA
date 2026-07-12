import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/services/firestore_service.dart';
import 'models/profile_models.dart';
import 'widgets/profile_widgets.dart';

/// -----------------------------------------------------------------------
/// EDITAR PERFIL
/// Recibe el UserProfile actual por `extra` (ver ProfilePage._openEditProfile).
/// Por ahora solo el TELÉFONO es editable; el resto de campos se muestran
/// de solo lectura. Al guardar, escribe directo en Firestore
/// (users/{uid}) — no hace falta manejar el valor de retorno porque
/// ProfilePage escucha esos cambios en vivo con un StreamBuilder.
/// -----------------------------------------------------------------------
class ProfileEditPage extends StatefulWidget {
  final UserProfile? user;
  const ProfileEditPage({this.user, super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final UserProfile _original =
      widget.user ?? MockProfileRepository.currentUser;

  late final _phoneCtrl = TextEditingController(text: _original.phone);

  bool _saving = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientSubHeader(
        title: 'Editar perfil',
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.horizontalPadding,
              vertical: AppSpacing.lg,
            ),
            children: [
              Center(child: _AvatarPicker(user: _original)),
              const SizedBox(height: AppSpacing.lg),
              const SectionLabel('Datos personales'),
              const SizedBox(height: AppSpacing.sm),
              _FieldCard(
                child: Column(
                  children: [
                    // Solo lectura: nombre
                    _ReadOnlyField(
                      label: 'Nombre completo',
                      value: _original.name,
                      icon: Icons.person_outline,
                    ),
                    const _FieldDivider(),
                    // Solo lectura: correo
                    _ReadOnlyField(
                      label: 'Correo electrónico',
                      value: _original.email,
                      icon: Icons.mail_outline,
                    ),
                    const _FieldDivider(),
                    // ÚNICO campo editable: teléfono
                    _EditField(
                      controller: _phoneCtrl,
                      label: 'Teléfono',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Ingresa tu teléfono'
                          : null,
                    ),
                    const _FieldDivider(),
                    // Solo lectura: ubicación
                    _ReadOnlyField(
                      label: 'Ubicación',
                      value: _original.address.isNotEmpty
                          ? _original.address
                          : 'Sin especificar',
                      icon: Icons.location_on_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionLabel('Acerca de ti'),
              const SizedBox(height: AppSpacing.sm),
              _FieldCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Text(
                    _original.bio.isNotEmpty
                        ? _original.bio
                        : 'Sin descripción',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Por ahora solo puedes actualizar tu teléfono. El resto de '
                'datos se muestran únicamente de referencia.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Guardar cambios',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      await FirestoreService.updateUserProfile(_original.id, {
        'phone': _phoneCtrl.text.trim(),
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      return;
    }

    if (!mounted) return;
    setState(() => _saving = false);
    context.pop();
  }
}

class _AvatarPicker extends StatelessWidget {
  final UserProfile user;
  const _AvatarPicker({required this.user});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAvatarOptions(context),
      child: Stack(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            backgroundImage: user.avatarUrl != null
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null
                ? Text(
                    user.initials,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                  )
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAvatarOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_camera_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _notify(context, 'Foto actualizada (simulado)');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Elegir de la galería'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _notify(context, 'Foto actualizada (simulado)');
                },
              ),
              if (user.avatarUrl != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  title: const Text(
                    'Quitar foto',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _notify(context, 'Foto eliminada (simulado)');
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _notify(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _FieldCard extends StatelessWidget {
  final Widget child;
  const _FieldCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _FieldDivider extends StatelessWidget {
  const _FieldDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: AppSpacing.md),
      child: Divider(height: 1, color: AppColors.border),
    );
  }
}

class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _EditField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14.5, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 12,
        ),
      ),
    );
  }
}

/// Campo de solo lectura: misma apariencia que _EditField pero
/// deshabilitado, para mostrar (no editar) nombre, correo, ubicación.
class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 12,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : '—',
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock_outline, size: 16, color: AppColors.border),
        ],
      ),
    );
  }
}
