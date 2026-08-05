import 'package:flutter/material.dart';

import '../../core/services/transaction_service.dart';
import 'models/admin_transaction.dart';
import 'transaction_detail_page.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Administración de Transacciones"),
        centerTitle: true,
      ),

      body: StreamBuilder<List<AdminTransaction>>(
        stream: TransactionService.watchAllTransactions(),

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

          final transactions = snapshot.data ?? [];

          if (transactions.isEmpty) {
            return const Center(
              child: Text("No existen transacciones."),
            );
          }

          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {

              final tx = transactions[index];

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),

                child: ListTile(

                  leading: CircleAvatar(
                    child: const Icon(Icons.shopping_bag),
                  ),

                  title: Text(tx.productTitle),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        "Comprador: ${tx.buyerName}",
                      ),
                      Text(
                        "Vendedor: ${tx.sellerName}",
                      ),
                      Text(
                        "S/. ${tx.amount.toStringAsFixed(2)}",
                      ),
                      Text(
                        tx.status.label,
                      ),
                    ],
                  ),

                  trailing: PopupMenuButton<String>(
                    itemBuilder: (_) => const [

                      PopupMenuItem(
                        value: "view",
                        child: Text("Ver"),
                      ),

                      PopupMenuItem(
                        value: "delete",
                        child: Text("Eliminar"),
                      ),

                    ],

                    onSelected: (value) async {

                      if (value == "view") {

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TransactionDetailPage(
                              transaction: tx,
                            ),
                          ),
                        );
                        
                      }

                      if (value == "delete") {

                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Eliminar transacción"),
                            content: const Text(
                              "¿Desea eliminar esta transacción?",
                            ),
                            actions: [

                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, false);
                                },
                                child: const Text("Cancelar"),
                              ),

                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context, true);
                                },
                                child: const Text("Eliminar"),
                              ),

                            ],
                          ),
                        );

                        if (confirm == true) {

                          await TransactionService.deleteTransaction(
                            tx.id,
                          );

                          if (context.mounted) {

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Transacción eliminada",
                                ),
                              ),
                            );
                          }
                        }
                      }
                    },
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