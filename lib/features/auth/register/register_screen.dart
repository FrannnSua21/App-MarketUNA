import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/auth_shared_widgets.dart';

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
                        const Text(
                          'Crear cuenta',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Paso 1 de 2 — Datos personales',
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                        const SizedBox(height: 12),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: 0.5,
                            minHeight: 6,
                            backgroundColor: Colors.black.withValues(
                              alpha: 0.08,
                            ),
                            valueColor: const AlwaysStoppedAnimation(
                              Color(0xFF2E5BFF),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        GlassTextField(
                          controller: _nameController,
                          label: 'Nombre',
                          hint: 'Tu nombre',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa tu nombre';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        GlassTextField(
                          controller: _lastNameController,
                          label: 'Apellidos',
                          hint: 'Tus apellidos',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa tus apellidos';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

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
                        const SizedBox(height: 16),

                        GlassTextField(
                          controller: _phoneController,
                          label: 'Teléfono',
                          hint: '+57 300 000 0000',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa tu teléfono';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),

                        PrimaryGlassButton(
                          label: 'Continuar',
                          isLoading: _isLoading,
                          onPressed: _handleContinue,
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
