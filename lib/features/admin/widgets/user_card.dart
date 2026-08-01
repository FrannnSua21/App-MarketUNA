import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../profile/models/profile_models.dart';

class UserCard extends StatelessWidget {
  final UserProfile user;

  final VoidCallback onChangeRole;

  final VoidCallback onToggleStatus;

  final VoidCallback? onViewProfile;

  const UserCard({
    super.key,
    required this.user,
    required this.onChangeRole,
    required this.onToggleStatus,
    this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Text(
            user.firstName.isNotEmpty
                ? user.firstName[0].toUpperCase()
                : "?",
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ),

        title: Text(
          "${user.firstName} ${user.lastName}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 5),

            Text(user.email),

            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [

                Chip(
                  label: Text(
                    user.role.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor:
                      user.role == "admin"
                          ? Colors.deepOrange
                          : AppColors.primary,
                ),

                Chip(
                  label: Text(
                    user.active
                        ? "Activo"
                        : "Desactivado",
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor:
                      user.active
                          ? AppColors.success
                          : AppColors.error,
                ),
              ],
            ),
          ],
        ),

        trailing: PopupMenuButton<String>(
          onSelected: (value) {

            switch (value) {

              case "profile":
                if (onViewProfile != null) {
                  onViewProfile!();
                }
                break;

              case "role":
                onChangeRole();
                break;

              case "status":
                onToggleStatus();
                break;
            }
          },
          itemBuilder: (_) => [

            const PopupMenuItem(
              value: "profile",
              child: Text("Ver perfil"),
            ),

            const PopupMenuItem(
              value: "role",
              child: Text("Cambiar rol"),
            ),

            PopupMenuItem(
              value: "status",
              child: Text(
                user.active
                    ? "Desactivar cuenta"
                    : "Activar cuenta",
              ),
            ),
          ],
        ),
      ),
    );
  }
}