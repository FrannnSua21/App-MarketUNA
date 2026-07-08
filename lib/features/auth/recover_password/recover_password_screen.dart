import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/auth_shared_widgets.dart';

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
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
      _emailSent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Volver'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2E5BFF),
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 24),

                GlassCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF2E5BFF,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.mail_outline,
                            color: Color(0xFF2E5BFF),
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'Olvidé mi contraseña',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ingresa tu correo institucional y te enviaremos un enlace para restablecer tu contraseña.',
                          style: TextStyle(color: Colors.black54, height: 1.4),
                        ),
                        const SizedBox(height: 24),

                        if (_emailSent)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.green.withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Si el correo existe, te enviamos un enlace de recuperación.',
                                  ),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          GlassTextField(
                            controller: _emailController,
                            label: 'Correo institucional',
                            hint: 'usuario@universidad.edu',
                            icon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa tu correo';
                              }
                              if (!value.contains('@')) {
                                return 'Correo inválido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          PrimaryGlassButton(
                            label: 'Enviar enlace',
                            isLoading: _isLoading,
                            onPressed: _handleRecover,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
