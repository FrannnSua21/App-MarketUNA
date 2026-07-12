import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/services/transaction_service.dart';
import 'models/profile_models.dart';
import 'widgets/profile_widgets.dart';

/// -----------------------------------------------------------------------
/// SOLICITUDES DE COMPRA (lado del vendedor)
///
/// Muestra las transacciones con status "enProceso" donde el usuario
/// logueado es el vendedor. Desde aquí puede Aceptar (marca el producto
/// como vendido y cancela las demás solicitudes de ese producto) o
/// Rechazar (solo esa solicitud puntual).
/// -----------------------------------------------------------------------
class ProfilePurchaseRequestsPage extends StatefulWidget {
  const ProfilePurchaseRequestsPage({super.key});

  @override
  State<ProfilePurchaseRequestsPage> createState() =>
      _ProfilePurchaseRequestsPageState();
}

class _ProfilePurchaseRequestsPageState
    extends State<ProfilePurchaseRequestsPage> {
  String? _cachedUid;
  Stream<List<ProfileTransaction>>? _requestsStream;

  final Set<String> _processingIds = {};

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  void _ensureStream(String uid) {
    if (_cachedUid != uid || _requestsStream == null) {
      _cachedUid = uid;
      _requestsStream = TransactionService.watchIncomingRequests(uid);
    }
  }

  Future<void> _accept(ProfileTransaction t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        title: const Text('Aceptar solicitud'),
        content: Text(
          'Vas a marcar "${t.productName}" como vendido a ${t.counterpartName}. '
          'Las demás solicitudes pendientes de este producto se cancelarán. '
          '¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Aceptar',
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _processingIds.add(t.id));
    try {
      await TransactionService.acceptRequest(
        transactionId: t.id,
        productId: t.productId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Venta confirmada con ${t.counterpartName}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _processingIds.remove(t.id));
    }
  }

  Future<void> _reject(ProfileTransaction t) async {
    setState(() => _processingIds.add(t.id));
    try {
      await TransactionService.rejectRequest(t.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Solicitud de ${t.counterpartName} rechazada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _processingIds.remove(t.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final uid = _uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    _ensureStream(uid);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientSubHeader(
        title: 'Solicitudes de compra',
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<ProfileTransaction>>(
          stream: _requestsStream,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              debugPrint('Error cargando solicitudes: ${snap.error}');
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No se pudieron cargar las solicitudes. Intenta de nuevo en unos minutos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              );
            }

            final requests = snap.data ?? [];
            if (requests.isEmpty) {
              return ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.horizontalPadding,
                ),
                children: const [
                  ProfileEmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'Sin solicitudes pendientes',
                    message:
                        'Cuando alguien quiera comprar tus productos, aparecerá aquí.',
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.horizontalPadding,
                vertical: AppSpacing.md,
              ),
              itemCount: requests.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final t = requests[index];
                final isProcessing = _processingIds.contains(t.id);
                return _RequestTile(
                  transaction: t,
                  isProcessing: isProcessing,
                  onAccept: () => _accept(t),
                  onReject: () => _reject(t),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final ProfileTransaction transaction;
  final bool isProcessing;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RequestTile({
    required this.transaction,
    required this.isProcessing,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: transaction.productImageUrl.isNotEmpty
                    ? Image.network(
                        transaction.productImageUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _fallbackIcon(),
                      )
                    : _fallbackIcon(),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Comprador: ${transaction.counterpartName}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'S/ ${transaction.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isProcessing ? null : onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  child: const Text('Rechazar'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  onPressed: isProcessing ? null : onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Aceptar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fallbackIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: const Icon(
        Icons.shopping_bag_outlined,
        size: 20,
        color: AppColors.primary,
      ),
    );
  }
}