import 'package:flutter/material.dart';
import '../../core/services/firestore_service.dart';
import '../category/models/category.dart';
import '../category/category_from_page.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Categorías"),
      ),
      body: StreamBuilder<List<Category>>(
        stream: FirestoreService.watchAllCategories(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final categories = snapshot.data!;

          if (categories.isEmpty) {
            return const Center(
              child: Text("No existen categorías."),
            );
          }

          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {

              final category = categories[index];

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: ListTile(

                  title: Text(category.name),

                  subtitle: Text(
                    category.active
                        ? "Activa"
                        : "Desactivada",
                  ),

                  trailing: PopupMenuButton<String>(

                    onSelected: (value) async {

                      if (value == "edit") {

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CategoryFormPage(
                              category: category,
                            ),
                          ),
                        );

                      }

                      if (value == "delete") {

                        final confirm = await showDialog<bool>(

                          context: context,

                          builder: (_) => AlertDialog(

                            title: const Text("Eliminar categoría"),

                            content: Text(
                              "¿Eliminar ${category.name}?"
                            ),

                            actions: [

                              TextButton(
                                onPressed: (){
                                  Navigator.pop(context,false);
                                },
                                child: const Text("Cancelar"),
                              ),

                              ElevatedButton(
                                onPressed: (){
                                  Navigator.pop(context,true);
                                },
                                child: const Text("Eliminar"),
                              ),

                            ],

                          ),

                        );

                        if(confirm==true){

                          await FirestoreService.deleteCategory(
                            category.id,
                          );

                        }

                      }

                    },

                    itemBuilder: (_) => const [

                      PopupMenuItem(
                        value: "edit",
                        child: Text("Editar"),
                      ),

                      PopupMenuItem(
                        value: "delete",
                        child: Text("Eliminar"),
                      ),

                    ],

                  ),

                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CategoryFormPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}