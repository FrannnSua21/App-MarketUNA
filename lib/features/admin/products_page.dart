import 'package:flutter/material.dart';

import '../../core/services/firestore_service.dart';
import '../product/models/product.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Administración de Productos"),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Product>>(
        stream: FirestoreService.watchAllProducts(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final products = snapshot.data!;

          if (products.isEmpty) {
            return const Center(
              child: Text("No hay productos."),
            );
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {

              final product = products[index];

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                elevation: 3,
                child: ListTile(

                  leading: product.imageUrls.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            product.imageUrls.first,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(
                          Icons.image,
                          size: 45,
                        ),

                  title: Text(
                    product.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        "S/. ${product.price.toStringAsFixed(2)}",
                      ),

                      Text(product.category),

                      Text(
                        "Estado: ${product.status.name}",
                      ),
                    ],
                  ),

                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {

                      if (value == "delete") {

                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Eliminar producto"),
                            content: const Text(
                              "¿Está seguro de eliminar este producto?"
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

                          await FirestoreService.deleteProduct(
                            product.id,
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Producto eliminado"),
                            ),
                          );

                        }

                      }

                    },
                    itemBuilder: (_) => const [

                      PopupMenuItem(
                        value: "view",
                        child: Row(
                          children: [
                            Icon(Icons.visibility),
                            SizedBox(width: 10),
                            Text("Ver"),
                          ],
                        ),
                      ),

                      PopupMenuItem(
                        value: "edit",
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 10),
                            Text("Editar"),
                          ],
                        ),
                      ),

                      PopupMenuItem(
                        value: "delete",
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 10),
                            Text("Eliminar"),
                          ],
                        ),
                      ),

                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}