import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _autoBackup = true;

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
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          _buildSectionHeader(context, "Preferencias Generales"),
          
          SwitchListTile(
            title: const Text("Notificaciones del sistema"),
            subtitle: const Text("Recibir alertas sobre compras y usuarios"),
            value: _notificationsEnabled,
            activeColor: AppColors.primary,
            onChanged: (val) {
              setState(() => _notificationsEnabled = val);
            },
          ),
          
          SwitchListTile(
            title: const Text("Modo Oscuro"),
            subtitle: const Text("Cambiar el tema visual de la aplicación"),
            value: _darkModeEnabled,
            activeColor: AppColors.primary,
            onChanged: (val) {
              setState(() => _darkModeEnabled = val);
            },
          ),

          const Divider(height: 30),
          _buildSectionHeader(context, "Mantenimiento y Datos"),

          SwitchListTile(
            title: const Text("Copia de seguridad automática"),
            subtitle: const Text("Respaldar datos diariamente"),
            value: _autoBackup,
            activeColor: AppColors.primary,
            onChanged: (val) {
              setState(() => _autoBackup = val);
            },
          ),

          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text("Limpiar Caché"),
            subtitle: const Text("Liberar espacio local almacenado"),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Caché limpiada con éxito")),
              );
            },
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