import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Flutter Demo",
      theme: ThemeData(fontFamily: "Roboto", useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,

            end: Alignment.bottomRight,

            colors: [Color(0xff141E30), Color(0xff243B55)],
          ),
        ),

        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(25),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // Encabezado
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: const [
                        Text(
                          "Holiwis 👋",

                          style: TextStyle(
                            color: Colors.white,

                            fontSize: 30,

                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 5),

                        Text(
                          "Bienvenido a Flutter",

                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),

                    CircleAvatar(
                      radius: 30,

                      backgroundColor: Colors.white,

                      child: Icon(
                        Icons.person,

                        size: 35,

                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 35),

                // Tarjeta principal
                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.all(25),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.circular(30),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),

                        blurRadius: 20,

                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),

                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),

                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,

                          shape: BoxShape.circle,
                        ),

                        child: const Icon(
                          Icons.flutter_dash,

                          size: 80,

                          color: Colors.blue,
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        "Mi primera aplicación Flutter",

                        textAlign: TextAlign.center,

                        style: TextStyle(
                          fontSize: 25,

                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        "Construyendo interfaces modernas, rápidas y hermosas con Dart.",

                        textAlign: TextAlign.center,

                        style: TextStyle(color: Colors.black54, fontSize: 16),
                      ),

                      const SizedBox(height: 25),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,

                          padding: const EdgeInsets.symmetric(
                            horizontal: 45,

                            vertical: 15,
                          ),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),

                        onPressed: () {},

                        child: const Text(
                          "Comenzar 🚀",

                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  "Mis estadísticas",

                  style: TextStyle(
                    color: Colors.white,

                    fontSize: 22,

                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    StatCard(icon: Icons.code, title: "Código", value: "1200"),

                    StatCard(
                      icon: Icons.phone_android,

                      title: "Apps",

                      value: "12",
                    ),

                    StatCard(icon: Icons.star, title: "Nivel", value: "Pro"),
                  ],
                ),

                const Spacer(),

                Center(
                  child: Text(
                    "Desarrollado con Flutter 💙",

                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),

          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Buscar"),

          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Ajustes"),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;

  final String title;

  final String value;

  const StatCard({
    super.key,

    required this.icon,

    required this.title,

    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,

      height: 120,

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(25),
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Icon(icon, size: 35, color: Colors.blue),

          const SizedBox(height: 10),

          Text(
            value,

            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          Text(title, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
