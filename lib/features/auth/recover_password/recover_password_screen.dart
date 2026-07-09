import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/auth_shared_widgets.dart';
import '../../../core/theme/app_theme.dart';

class RecoverPasswordScreen extends StatefulWidget {
  const RecoverPasswordScreen({super.key});

  @override
  State<RecoverPasswordScreen> createState() => _RecoverPasswordScreenState();
}

class _RecoverPasswordScreenState extends State<RecoverPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleRecover() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // TODO: conectar con tu AuthService / AuthProvider real
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _emailSent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: FadeSlideIn(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                child: _emailSent ? _buildSuccess() : _buildForm(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return const SuccessCheckAnimation(
      key: ValueKey('sent'),
      title: 'Enlace enviado',
      message: 'Si el correo existe, te enviamos un enlace de recuperación.',
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.mail_outline,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            'Olvidé mi contraseña',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Ingresa tu correo institucional y te enviaremos un enlace para restablecer tu contraseña.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.lg),

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
          const SizedBox(height: AppSpacing.lg),

          PrimaryGlassButton(
            label: 'Enviar enlace',
            isLoading: _isLoading,
            onPressed: _handleRecover,
          ),
        ],
      ),
    );
  }
}
