import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../widgets/auth_shared_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

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
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _registered = false;

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final nombreCompleto =
        '${_nameController.text.trim()} ${_lastNameController.text.trim()}'
            .trim();

    final success = await auth.register(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      name: nombreCompleto,
      phone: _phoneController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Error al crear la cuenta'),
        ),
      );
      return;
    }

    setState(() => _registered = true);

    if (auth.biometricAvailable) {
      await _ofrecerBiometria(auth);
    }

    if (!mounted) return;
    context.go('/home');
  }

  Future<void> _ofrecerBiometria(AuthProvider auth) async {
    final quiere = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.fingerprint, color: AppColors.primary, size: 40),
        title: const Text('¿Activar huella digital?'),
        content: const Text(
          'La próxima vez podrás iniciar sesión más rápido usando tu huella o Face ID.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Activar'),
          ),
        ],
      ),
    );

    if (quiere == true) {
      final verificado = await auth.loginWithBiometrics();
      if (verificado) {
        await auth.enableBiometric();
      }
    }
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
          const SizedBox(height: AppSpacing.md),

          GlassTextField(
            controller: _passwordController,
            label: 'Contraseña',
            hint: 'Mínimo 6 caracteres',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa una contraseña';
              }
              if (value.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),

          GlassTextField(
            controller: _confirmPasswordController,
            label: 'Confirmar contraseña',
            hint: 'Repite tu contraseña',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Las contraseñas no coinciden';
              }
              return null;
            },
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
