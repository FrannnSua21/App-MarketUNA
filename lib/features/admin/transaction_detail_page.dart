import 'package:flutter/material.dart';

import 'models/admin_transaction.dart';

class TransactionDetailPage extends StatelessWidget {
  final AdminTransaction transaction;

  const TransactionDetailPage({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalle de la transacción"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            if (transaction.productImageUrl.isNotEmpty)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    transaction.productImageUrl,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            Text(
              "Producto",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(transaction.productTitle),

            const SizedBox(height: 15),

            Text(
              "Comprador",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(transaction.buyerName),

            const SizedBox(height: 15),

            Text(
              "Vendedor",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(transaction.sellerName),

            const SizedBox(height: 15),

            Text(
              "Monto",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              "S/. ${transaction.amount.toStringAsFixed(2)}",
            ),

            const SizedBox(height: 15),

            Text(
              "Estado",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(transaction.status.label),

            const SizedBox(height: 15),

            Text(
              "ID",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            SelectableText(transaction.id),

          ],
        ),
      ),
    );
  }
}