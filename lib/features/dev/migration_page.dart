import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../profile/models/profile_models.dart';

/// -----------------------------------------------------------------------
/// PANTALLA TEMPORAL DE MIGRACIÓN — úsala UNA sola vez y luego bórrala.
///
/// Recorre products donde sellerName == "Invitado", busca el perfil real
/// en users/{sellerId} y corrige sellerName/sellerRating/sellerTotalSales.
/// -----------------------------------------------------------------------
class MigrationPage extends StatefulWidget {
  const MigrationPage({super.key});

  @override
  State<MigrationPage> createState() => _MigrationPageState();
}

class _MigrationPageState extends State<MigrationPage> {
  bool _isRunning = false;
  final List<String> _log = [];

  Future<void> _runMigration() async {
    setState(() {
      _isRunning = true;
      _log.clear();
    });

    try {
      final productsSnap = await FirebaseFirestore.instance
          .collection('products')
          .where('sellerName', isEqualTo: 'Invitado')
          .get();

      _addLog(
        'Encontrados: ${productsSnap.docs.length} productos con "Invitado"',
      );

      int fixed = 0;
      int skipped = 0;
      int denied = 0;

      for (final doc in productsSnap.docs) {
        final data = doc.data();
        final sellerId = data['sellerId'] as String? ?? '';

        if (sellerId.isEmpty) {
          _addLog('⚠️ ${doc.id}: sin sellerId, se omite');
          skipped++;
          continue;
        }

        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(sellerId)
              .get();

          if (!userDoc.exists || userDoc.data() == null) {
            _addLog('⚠️ ${doc.id}: usuario $sellerId no existe, se omite');
            skipped++;
            continue;
          }

          final profile = UserProfile.fromMap(userDoc.data()!, sellerId);
          final realName = profile.name.trim().isNotEmpty
              ? profile.name
              : 'Usuario';

          await doc.reference.update({
            'sellerName': realName,
            'sellerRating': profile.rating,
            'sellerTotalSales': profile.totalVentas,
          });

          _addLog('✅ ${doc.id}: "Invitado" → "$realName"');
          fixed++;
        } on FirebaseException catch (e) {
          if (e.code == 'permission-denied') {
            _addLog('🔒 ${doc.id}: sin permiso para editar (no es tuyo)');
            denied++;
          } else {
            _addLog('❌ ${doc.id}: ${e.message}');
          }
          // NO hacemos "rethrow": seguimos con el siguiente documento.
        }
      }

      _addLog(
        '--- Terminado: $fixed corregidos, $skipped omitidos, $denied sin permiso ---',
      );
    } catch (e) {
      _addLog('❌ Error general: $e');
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
  }

  void _addLog(String msg) {
    setState(() => _log.add(msg));
    debugPrint(msg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Migración: sellerName')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isRunning ? null : _runMigration,
              child: _isRunning
                  ? const CircularProgressIndicator()
                  : const Text('Ejecutar migración'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _log.length,
                itemBuilder: (context, index) => Text(
                  _log[index],
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
