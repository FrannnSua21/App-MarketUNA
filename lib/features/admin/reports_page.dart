import 'package:flutter/material.dart';

import '../../core/services/firestore_service.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool _loading = true;

  int totalUsers = 0;
  int totalProducts = 0;
  int totalCategories = 0;
  int totalTransactions = 0;
  int activeProducts = 0;
  int soldProducts = 0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      totalUsers = await FirestoreService.getTotalUsers();
      totalProducts = await FirestoreService.getTotalProducts();
      totalCategories = await FirestoreService.getTotalCategories();
      totalTransactions = await FirestoreService.getTotalTransactions();
      activeProducts = await FirestoreService.getActiveProducts();
      soldProducts = await FirestoreService.getSoldProducts();
    } catch (e) {
      debugPrint(e.toString());
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reportes"),
        centerTitle: true,
      ),

      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.85,
                children: [

                  _reportCard(
                    Icons.people,
                    "Usuarios",
                    totalUsers.toString(),
                    Colors.blue,
                  ),

                  _reportCard(
                    Icons.shopping_bag,
                    "Productos",
                    totalProducts.toString(),
                    Colors.green,
                  ),

                  _reportCard(
                    Icons.category,
                    "Categorías",
                    totalCategories.toString(),
                    Colors.orange,
                  ),

                  _reportCard(
                    Icons.receipt_long,
                    "Transacciones",
                    totalTransactions.toString(),
                    Colors.purple,
                  ),

                  _reportCard(
                    Icons.check_circle,
                    "Productos Activos",
                    activeProducts.toString(),
                    Colors.teal,
                  ),

                  _reportCard(
                    Icons.sell,
                    "Productos Vendidos",
                    soldProducts.toString(),
                    Colors.red,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _reportCard(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),

            const SizedBox(height: 15),

            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}