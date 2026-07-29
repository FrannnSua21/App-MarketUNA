import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel de Administración"),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(20),
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        children: [

          _adminCard(
            context,
            Icons.people,
            "Usuarios",
            () {
              // Ir a la pantalla de usuarios
            },
          ),

          _adminCard(
            context,
            Icons.inventory,
            "Productos",
            () {
              // Ir a la pantalla de productos
            },
          ),

          _adminCard(
            context,
            Icons.shopping_cart,
            "Ventas",
            () {
              // Ir a la pantalla de ventas
            },
          ),

          _adminCard(
            context,
            Icons.report,
            "Reportes",
            () {
              // Ir a la pantalla de reportes
            },
          ),

          _adminCard(
            context,
            Icons.settings,
            "Configuración",
            () {
              // Ir a configuración
            },
          ),

          _adminCard(
            context,
            Icons.logout,
            "Cerrar sesión",
            () async {
              // cerrar sesión
            },
          ),
        ],
      ),
    );
  }

  Widget _adminCard(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Icon(
              icon,
              size: 50,
              color: Colors.blue,
            ),

            const SizedBox(height: 15),

            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}