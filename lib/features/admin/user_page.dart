import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import '../../core/services/firestore_service.dart';
import '../profile/models/profile_models.dart';
import '../auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'widgets/user_card.dart';


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

              return UserCard(
                user: user,

                onChangeRole: () async {

                  final newRole =
                      user.role == "admin"
                          ? "user"
                          : "admin";

                  await FirestoreService.updateUserRole(
                    user.id,
                    newRole,
                  );
                },

                onToggleStatus: () async {

                  await FirestoreService.updateUserStatus(
                    user.id,
                    !user.active,
                  );

                },

                onViewProfile: () {

                  context.push(
                    '/admin/user',
                    extra: user,
                  );

                },
              );
            },
          );
        }
      ),
    );
  }
}