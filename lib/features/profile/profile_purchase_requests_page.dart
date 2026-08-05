import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/services/transaction_service.dart';
import '../../core/services/firestore_service.dart';
import 'models/profile_models.dart';
import 'widgets/profile_widgets.dart';

/// -----------------------------------------------------------------------
/// SOLICITUDES DE COMPRA (lado del vendedor)
///
/// Muestra las transacciones con status "enProceso" donde el usuario
/// logueado es el vendedor. Desde aquí puede Aceptar (marca el producto
/// como vendido y cancela las demás solicitudes de ese producto),
/// Rechazar (solo esa solicitud puntual) o Contactar al comprador por
/// WhatsApp usando el teléfono real registrado en su perfil.
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
  final Set<String> _contactingIds = {};

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

  // ==========================================================================
  // Modal "Escribir al WhatsApp" + redirección al número real del
  // comprador (se consulta en vivo su perfil, no un campo guardado en
  // la transacción, así siempre está actualizado).
  // ==========================================================================

  Future<void> _openWhatsAppModal(ProfileTransaction t) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chat,
                        color: Color(0xFF25D366),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: Text(
                        'Escribir al WhatsApp',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Se abrirá WhatsApp para chatear con ${t.counterpartName} '
                  'sobre "${t.productName}".',
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _contactBuyer(t);
                    },
                    icon: const Icon(Icons.chat, size: 18, color: Colors.white),
                    label: const Text(
                      'Ir a WhatsApp',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _contactBuyer(ProfileTransaction t) async {
    if (t.counterpartId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo identificar al comprador')),
      );
      return;
    }

    setState(() => _contactingIds.add(t.id));
    try {
      // Consultamos el teléfono real y actualizado del comprador,
      // en vez de depender de un campo guardado en la transacción.
      final buyerProfile = await FirestoreService.getUserProfile(
        t.counterpartId,
      );
      final phone = buyerProfile?.phone ?? t.counterpartPhone ?? '';

      if (phone.trim().isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'El comprador no tiene un número de WhatsApp registrado',
            ),
          ),
        );
        return;
      }

      final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
      final message = Uri.encodeComponent(
        'Hola ${t.counterpartName}, te escribo por tu solicitud de compra '
        'para "${t.productName}".',
      );

      final whatsappAppUri = Uri.parse(
        'whatsapp://send?phone=$cleanPhone&text=$message',
      );
      final whatsappWebUri = Uri.parse(
        'https://wa.me/$cleanPhone?text=$message',
      );

      bool launched = false;
      try {
        launched = await launchUrl(
          whatsappAppUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        launched = false;
      }

      if (!launched) {
        try {
          launched = await launchUrl(
            whatsappWebUri,
            mode: LaunchMode.externalApplication,
          );
        } catch (_) {
          launched = false;
        }
      }

      if (!launched) {
        // Último recurso: intento de llamada telefónica tradicional.
        final phoneUri = Uri.parse('tel:$cleanPhone');
        try {
          launched = await launchUrl(phoneUri);
        } catch (_) {
          launched = false;
        }
      }

      if (!launched) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir WhatsApp ni la app de llamadas'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al abrir el contacto: $e')));
    } finally {
      if (mounted) setState(() => _contactingIds.remove(t.id));
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
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final t = requests[index];
                final isProcessing = _processingIds.contains(t.id);
                final isContacting = _contactingIds.contains(t.id);
                return _RequestTile(
                  transaction: t,
                  isProcessing: isProcessing,
                  isContacting: isContacting,
                  onAccept: () => _accept(t),
                  onReject: () => _reject(t),
                  onContact: () => _openWhatsAppModal(t),
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
  final bool isContacting;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onContact;

  const _RequestTile({
    required this.transaction,
    required this.isProcessing,
    required this.isContacting,
    required this.onAccept,
    required this.onReject,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: transaction.productImageUrl.isNotEmpty
                    ? Image.network(
                        transaction.productImageUrl,
                        width: 52,
                        height: 52,
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
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            transaction.counterpartName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'S/ ${transaction.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // ---- Botón de contacto por WhatsApp, estilo tarjeta ----
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isContacting ? null : onContact,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: const Color(0xFF25D366).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_rounded,
                      size: 17,
                      color: Color(0xFF25D366),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Contactar por WhatsApp',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF128C41),
                        ),
                      ),
                    ),
                    if (isContacting)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF25D366),
                        ),
                      )
                    else
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: Color(0xFF25D366),
                      ),
                  ],
                ),
              ),
            ),
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
      width: 52,
      height: 52,
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
