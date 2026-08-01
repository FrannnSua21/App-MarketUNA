import 'package:flutter/material.dart';

import '../../core/services/firestore_service.dart';
import '../profile/models/profile_models.dart';
import '../auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';


class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Usuarios"),
      ),
      body: StreamBuilder<List<UserProfile>>(
        stream: FirestoreService.watchAllUsers(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return const Center(
              child: Text("No existen usuarios"),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {

              final user = users[index];

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                child: ListTile(

                  leading: CircleAvatar(
                    child: Text(
                      user.firstName.isEmpty
                          ? "?"
                          : user.firstName[0],
                    ),
                  ),

                  title: Text(
                    "${user.firstName} ${user.lastName}",
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(user.email),

                      const SizedBox(height: 4),

                      Chip(
                        label: Text(
                          user.role.toUpperCase(),
                        ),
                      ),

                    ],
                  ),

                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {

                      if (value == "role") {

                        final newRole =
                            user.role == "admin"
                                ? "user"
                                : "admin";

                        final auth = context.read<AuthProvider>();

                        if (user.id == auth.currentUid) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "No puedes cambiar tu propio rol.",
                              ),
                            ),
                          );
                          return;
                        }

                        await FirestoreService.updateUserRole(
                          user.id,
                          newRole,
                        );




                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Rol cambiado a $newRole",
                            ),
                          ),
                        );
                      }

                    },
                    itemBuilder: (_) => [

                      const PopupMenuItem(
                        value: "role",
                        child: Text("Cambiar rol"),
                      ),

                    ],
                  ),
                ),
              );
            },
          );
        }
      ),
    );
  }
}