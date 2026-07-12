import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/product/models/product.dart';
import '../../features/profile/models/profile_models.dart';

/// -----------------------------------------------------------------------
/// TransactionService
///
/// Maneja el ciclo de vida de una compra:
/// 1. El comprador pide comprar -> se crea un documento en `transactions`
///    con status "enProceso". El producto SIGUE visible/activo (varios
///    compradores pueden pedir el mismo producto a la vez).
/// 2. El vendedor ve sus solicitudes pendientes (status == enProceso) y
///    elige una para "Aceptar" -> esa pasa a "completado", el producto
///    cambia a status "vendida", y TODAS las demás solicitudes
///    pendientes de ese mismo producto se cancelan automáticamente.
/// 3. El vendedor también puede "Rechazar" una solicitud puntual sin
///    afectar las demás ni el producto.
/// -----------------------------------------------------------------------
class TransactionService {
  TransactionService._();

  static final _db = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _transactions =>
      _db.collection('transactions');
  static CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection('products');

  /// Evita que el mismo comprador pida el mismo producto dos veces
  /// mientras ya tiene una solicitud "enProceso" abierta.
  static Future<bool> hasPendingRequest({
    required String productId,
    required String buyerId,
  }) async {
    final snap = await _transactions
        .where('productId', isEqualTo: productId)
        .where('buyerId', isEqualTo: buyerId)
        .where('status', isEqualTo: TransactionStatus.enProceso.name)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }


/// Escucha en vivo la ÚLTIMA solicitud de compra que este comprador
  /// hizo sobre este producto (o null si nunca pidió). A diferencia de
  /// hasPendingRequest (que es una consulta de una sola vez), esto se
  /// actualiza solo en la UI cuando el vendedor acepta o rechaza, sin
  /// que el comprador tenga que recargar la pantalla.
  static Stream<ProfileTransaction?> watchMyLatestRequest({
    required String productId,
    required String buyerId,
  }) {
    return _transactions
        .where('productId', isEqualTo: productId)
        .where('buyerId', isEqualTo: buyerId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return null;
          final doc = snap.docs.first;
          return ProfileTransaction.fromMap(doc.data(), doc.id, buyerId);
        });
  }



  /// Crea la solicitud de compra ("enProceso"). No modifica el producto:
  /// sigue visible para que otros compradores también puedan pedirlo.
  static Future<void> createPurchaseRequest({
    required Product product,
    required String buyerId,
    required String buyerName,
  }) async {
    if (product.sellerId == buyerId) {
      throw Exception('No puedes comprar tu propia publicación');
    }

    final alreadyRequested = await hasPendingRequest(
      productId: product.id,
      buyerId: buyerId,
    );
    if (alreadyRequested) {
      throw Exception('Ya tienes una solicitud pendiente para este producto');
    }

    await _transactions.add({
      'productId': product.id,
      'productTitle': product.title,
      'productImageUrl': product.imageUrls.isNotEmpty
          ? product.imageUrls.first
          : '',
      'buyerId': buyerId,
      'buyerName': buyerName,
      'sellerId': product.sellerId,
      'sellerName': product.seller.name,
      'amount': product.price,
      'status': TransactionStatus.enProceso.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Todas las transacciones donde el usuario es vendedor, ordenadas por
  /// fecha (usa el índice sellerId+createdAt que ya tienes). El filtro
  /// "enProceso" se hace del lado del cliente para no necesitar un
  /// índice compuesto extra (sellerId+status+createdAt).
  static Stream<List<ProfileTransaction>> watchIncomingRequests(
    String sellerId,
  ) {
    return _transactions
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs
              .map(
                (doc) =>
                    ProfileTransaction.fromMap(doc.data(), doc.id, sellerId),
              )
              .where((t) => t.status == TransactionStatus.enProceso)
              .toList();
        });
  }

  /// El vendedor acepta esta solicitud:
  /// - la transacción elegida pasa a "completado"
  /// - el producto pasa a "vendida"
  /// - todas las demás solicitudes "enProceso" del mismo producto se
  ///   cancelan automáticamente (ya no hay nada que vender).
  static Future<void> acceptRequest({
    required String transactionId,
    required String productId,
  }) async {
    final batch = _db.batch();

    batch.update(_transactions.doc(transactionId), {
      'status': TransactionStatus.completado.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.update(_products.doc(productId), {
      'status': ProductStatus.vendida.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final otherPending = await _transactions
        .where('productId', isEqualTo: productId)
        .where('status', isEqualTo: TransactionStatus.enProceso.name)
        .get();

    for (final doc in otherPending.docs) {
      if (doc.id == transactionId) continue;
      batch.update(doc.reference, {
        'status': TransactionStatus.cancelado.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// El vendedor rechaza esta solicitud puntual. No afecta al producto
  /// ni a las demás solicitudes.
  static Future<void> rejectRequest(String transactionId) async {
    await _transactions.doc(transactionId).update({
      'status': TransactionStatus.cancelado.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
