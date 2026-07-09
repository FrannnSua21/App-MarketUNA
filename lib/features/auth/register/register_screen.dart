import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/auth_shared_widgets.dart';
import '../../../core/theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _registered = false;

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // TODO: guardar estos datos (paso 1) y navegar al Paso 2 (contraseña, etc.)
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _registered = true;
    });

    // Deja ver la animación de éxito un momento antes de navegar.
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: FadeSlideIn(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_registered)
              TextButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Volver'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
              ),
            const SizedBox(height: AppSpacing.lg),

            GlassCard(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.94, end: 1.0).animate(anim),
                    child: child,
                  ),
                ),
                child: _registered ? _buildSuccess() : _buildForm(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return const SuccessCheckAnimation(
      key: ValueKey('success'),
      title: '¡Cuenta creada!',
      message: 'Te estamos llevando a tu panel principal…',
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Crear cuenta',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          const Text(
            'Paso 1 de 2 — Datos personales',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.md),

          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(
              value: 0.5,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          GlassTextField(
            controller: _nameController,
            label: 'Nombre',
            hint: 'Tu nombre',
            icon: Icons.person_outline,
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Ingresa tu nombre' : null,
          ),
          const SizedBox(height: AppSpacing.md),

          GlassTextField(
            controller: _lastNameController,
            label: 'Apellidos',
            hint: 'Tus apellidos',
            icon: Icons.person_outline,
            validator: (value) => (value == null || value.isEmpty)
                ? 'Ingresa tus apellidos'
                : null,
          ),
          const SizedBox(height: AppSpacing.md),

          GlassTextField(
            controller: _emailController,
            label: 'Correo institucional',
            hint: 'usuario@universidad.edu',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Ingresa tu correo';
              if (!value.contains('@')) return 'Correo inválido';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),

          GlassTextField(
            controller: _phoneController,
            label: 'Teléfono',
            hint: '+57 300 000 0000',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Ingresa tu teléfono' : null,
          ),
          const SizedBox(height: AppSpacing.xl),

          PrimaryGlassButton(
            label: 'Continuar',
            isLoading: _isLoading,
            onPressed: _handleContinue,
          ),
        ],
      ),
    );
  }
}
