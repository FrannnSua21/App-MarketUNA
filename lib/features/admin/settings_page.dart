import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Claves de preferencia
  static const String _keyNotifications = 'admin_notifications';
  static const String _keyDarkMode = 'admin_dark_mode';
  static const String _keyAutoBackup = 'admin_auto_backup';

  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _autoBackup = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  // Cargar las preferencias guardadas
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool(_keyNotifications) ?? true;
      _darkModeEnabled = prefs.getBool(_keyDarkMode) ?? false;
      _autoBackup = prefs.getBool(_keyAutoBackup) ?? true;
      _isLoading = false;
    });
  }

  // Guardar un valor de tipo bool en SharedPreferences
  Future<void> _toggleSetting(String key, bool value, Function(bool) updateState) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    setState(() {
      updateState(value);
    });
  }

  // Simulación de función para limpiar caché
  Future<void> _clearCache() async {
    // Mostrar indicador de carga breve
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    await Future.delayed(const Duration(seconds: 1)); // Simula la limpieza
    if (!mounted) return;

    Navigator.pop(context); // Cerrar diálogo de carga

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Caché limpiada con éxito"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin');
            }
          },
        ),
        title: const Text("Configuración"),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                _buildSectionHeader(context, "Preferencias Generales"),
                
                // Función: Notificaciones
                SwitchListTile(
                  title: const Text("Notificaciones del sistema"),
                  subtitle: const Text("Recibir alertas sobre compras y usuarios"),
                  value: _notificationsEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    _toggleSetting(_keyNotifications, val, (v) => _notificationsEnabled = v);
                  },
                ),
                
                // Función: Modo Oscuro
                SwitchListTile(
                  title: const Text("Modo Oscuro"),
                  subtitle: const Text("Cambiar el tema visual de la aplicación"),
                  value: _darkModeEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    _toggleSetting(_keyDarkMode, val, (v) => _darkModeEnabled = v);
                    // AQUÍ: Si manejas tema dinámico global mediante Provider/Riverpod,
                    // llamarías al método de tu ThemeProvider aquí.
                  },
                ),

                const Divider(height: 30),
                _buildSectionHeader(context, "Mantenimiento y Datos"),

                // Función: Respaldo Automático
                SwitchListTile(
                  title: const Text("Copia de seguridad automática"),
                  subtitle: const Text("Respaldar datos diariamente"),
                  value: _autoBackup,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    _toggleSetting(_keyAutoBackup, val, (v) => _autoBackup = v);
                  },
                ),

                // Función: Limpiar Caché
                ListTile(
                  leading: const Icon(Icons.cleaning_services_outlined),
                  title: const Text("Limpiar Caché"),
                  subtitle: const Text("Liberar espacio local almacenado"),
                  onTap: _clearCache,
                ),

                const Divider(height: 30),
                _buildSectionHeader(context, "Información"),

                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text("Versión de la App"),
                  subtitle: Text("1.0.0"),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/admin');
                      }
                    },
                    icon: const Icon(Icons.dashboard_outlined),
                    label: const Text("Volver al Panel Principal"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}