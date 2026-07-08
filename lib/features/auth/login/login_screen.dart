import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/auth_shared_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // TODO: conectar con tu AuthService / AuthProvider real
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isLoading = false);
    if (mounted) context.go('/home');
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
                // Logo + nombre de la app
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E5BFF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.shopping_bag_outlined,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Campus Market',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Bienvenido de vuelta',
                            style: TextStyle(
                                fontSize: 13, color: Colors.black54)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                GlassCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Iniciar sesión',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),

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
                            if (!value.contains('@')) return 'Correo inválido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        GlassTextField(
                          controller: _passwordController,
                          label: 'Contraseña',
                          hint: '••••••••',
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa tu contraseña';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.go('/recover-password'),
                            child: const Text('¿Olvidé mi contraseña?'),
                          ),
                        ),
                        const SizedBox(height: 8),

                        PrimaryGlassButton(
                          label: 'Iniciar sesión',
                          isLoading: _isLoading,
                          onPressed: _handleLogin,
                        ),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                                child: Divider(
                                    color:
                                        Colors.black.withValues(alpha: 0.15))),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('o',
                                  style: TextStyle(color: Colors.black45)),
                            ),
                            Expanded(
                                child: Divider(
                                    color:
                                        Colors.black.withValues(alpha: 0.15))),
                          ],
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.6),
                              side: BorderSide(
                                  color: Colors.black.withValues(alpha: 0.1)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              // TODO: conectar login con Google
                            },
                            icon: const Text('G',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color(0xFF2E5BFF))),
                            label: const Text('Continuar con Google',
                                style: TextStyle(color: Colors.black87)),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('¿No tienes cuenta? '),
                            GestureDetector(
                              onTap: () => context.go('/register'),
                              child: const Text(
                                'Crear cuenta',
                                style: TextStyle(
                                    color: Color(0xFF2E5BFF),
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Center(
                          child: TextButton(
                            onPressed: () {
                              // TODO: navegación como invitado
                            },
                            child: const Text('Continuar como invitado',
                                style: TextStyle(color: Colors.black45)),
                          ),
                        ),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              // TODO: solo para pruebas, quitar en producción
                            },
                            child: Text('[Demo: Entrar como Admin]',
                                style: TextStyle(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    fontSize: 12)),
                          ),
                        ),
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