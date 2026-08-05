import 'package:cloud_firestore/cloud_firestore.dart';

enum AdminTransactionStatus {
  enProceso,
  completado,
  cancelado,
}

extension AdminTransactionStatusX on AdminTransactionStatus {
  String get label {
    switch (this) {
      case AdminTransactionStatus.enProceso:
        return "En proceso";
      case AdminTransactionStatus.completado:
        return "Completado";
      case AdminTransactionStatus.cancelado:
        return "Cancelado";
    }
  }
}

class AdminTransaction {
  final String id;
  final String productId;
  final String productTitle;
  final String productImageUrl;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName;

  final double amount;
  final AdminTransactionStatus status;
  final DateTime createdAt;

  const AdminTransaction({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.productImageUrl,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory AdminTransaction.fromMap(
    Map<String, dynamic> map,
    String id,
  ) {
    final timestamp = map['createdAt'];

    return AdminTransaction(
      id: id,

      productId: map['productId'] ?? '',
      productTitle: map['productTitle'] ?? '',
      productImageUrl: map['productImageUrl'] ?? '',
      buyerId: map['buyerId'] ?? '',
      buyerName: map['buyerName'] ?? '',
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      status: AdminTransactionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AdminTransactionStatus.enProceso,
      ),

      createdAt: timestamp is Timestamp
          ? timestamp.toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productTitle': productTitle,
      'productImageUrl': productImageUrl,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'amount': amount,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}