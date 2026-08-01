import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../profile/models/profile_models.dart';

class UserDetailPage extends StatelessWidget {
  final UserProfile user;

  const UserDetailPage({
    super.key,
    required this.user,
  });

  Widget _infoTile(
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: AppColors.primary,
        ),
        title: Text(title),
        subtitle: Text(value.isEmpty ? "-" : value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalle del usuario"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            CircleAvatar(
              radius: 45,
              backgroundColor: AppColors.primary,
              child: Text(
                user.firstName.isNotEmpty
                    ? user.firstName[0].toUpperCase()
                    : "?",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              "${user.firstName} ${user.lastName}",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            _infoTile(
              "Correo",
              user.email,
              Icons.email,
            ),

            _infoTile(
              "Teléfono",
              user.phone,
              Icons.phone,
            ),

            _infoTile(
              "Carrera",
              user.career,
              Icons.school,
            ),

            _infoTile(
              "Código universitario",
              user.universityCode,
              Icons.badge,
            ),

            _infoTile(
              "Dirección",
              user.address,
              Icons.location_on,
            ),

            _infoTile(
              "Biografía",
              user.bio,
              Icons.description,
            ),

            _infoTile(
              "Rol",
              user.role.toUpperCase(),
              Icons.admin_panel_settings,
            ),

            _infoTile(
              "Ventas",
              user.totalVentas.toString(),
              Icons.shopping_bag,
            ),

            _infoTile(
              "Compras",
              user.totalCompras.toString(),
              Icons.shopping_cart,
            ),

            _infoTile(
              "Seguidores",
              user.followers.toString(),
              Icons.people,
            ),

            _infoTile(
              "Calificación",
              user.rating.toString(),
              Icons.star,
            ),
          ],
        ),
      ),
    );
  }
}