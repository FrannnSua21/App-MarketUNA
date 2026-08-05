import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/services/transaction_service.dart';
import 'models/profile_models.dart';
import 'widgets/profile_widgets.dart';

/// -----------------------------------------------------------------------
/// MIS SOLICITUDES DE COMPRA (lado del comprador)
///
/// Muestra TODAS las solicitudes que YO envié (a distintos vendedores),
/// con su estado actual: En proceso, Completado o Cancelado. Mientras
/// siga "En proceso", el comprador puede cancelarla.
/// -----------------------------------------------------------------------
class ProfileMyRequestsPage extends StatefulWidget {
  const ProfileMyRequestsPage({super.key});

  @override
  State<ProfileMyRequestsPage> createState() => _ProfileMyRequestsPageState();
}

class _ProfileMyRequestsPageState extends State<ProfileMyRequestsPage> {
  String? _cachedUid;
  Stream<List<ProfileTransaction>>? _requestsStream;
  final Set<String> _processingIds = {};

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  void _ensureStream(String uid) {
    if (_cachedUid != uid || _requestsStream == null) {
      _cachedUid = uid;
      _requestsStream = TransactionService.watchMyOutgoingRequests(uid);
    }
  }

  Future<void> _cancel(ProfileTransaction t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        title: const Text('Cancelar solicitud'),
        content: Text(
          '¿Seguro que quieres cancelar tu solicitud de compra para '
          '"${t.productName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'No, mantenerla',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Sí, cancelar',
              style: TextStyle(
                color: AppColors.error,
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
      await TransactionService.cancelMyRequest(t.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Solicitud cancelada')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _processingIds.remove(t.id));
    }
  }

  Future<void> _contactSeller(ProfileTransaction t) async {
    final phone = t.counterpartPhone ?? '';
    if (phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El vendedor no tiene un teléfono registrado'),
        ),
      );
      return;
    }

    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final message = Uri.encodeComponent(
      'Hola ${t.counterpartName}, te escribo por mi solicitud de compra '
      'para "${t.productName}".',
    );
    final whatsappUri = Uri.parse('https://wa.me/$cleanPhone?text=$message');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        final phoneUri = Uri.parse('tel:$cleanPhone');
        if (await canLaunchUrl(phoneUri)) {
          await launchUrl(phoneUri);
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir WhatsApp ni la app de llamadas'),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al abrir el contacto: $e')));
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
        title: 'Mis solicitudes de compra',
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
              debugPrint('Error cargando mis solicitudes: ${snap.error}');
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No se pudieron cargar tus solicitudes. Intenta de nuevo en unos minutos.',
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
                    icon: Icons.send_outlined,
                    title: 'Aún no has enviado solicitudes',
                    message:
                        'Cuando pidas comprar un producto, tu solicitud aparecerá aquí.',
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
                return _MyRequestTile(
                  transaction: t,
                  isProcessing: isProcessing,
                  onCancel: () => _cancel(t),
                  onContact: () => _contactSeller(t),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MyRequestTile extends StatelessWidget {
  final ProfileTransaction transaction;
  final bool isProcessing;
  final VoidCallback onCancel;
  final VoidCallback onContact;

  const _MyRequestTile({
    required this.transaction,
    required this.isProcessing,
    required this.onCancel,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    final canCancel = transaction.status == TransactionStatus.enProceso;

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
                      'Vendedor: ${transaction.counterpartName}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                tooltip: 'Contactar al vendedor',
                onPressed: onContact,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: transaction.status.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  transaction.status.label,
                  style: TextStyle(
                    color: transaction.status.color,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'S/ ${transaction.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
          if (canCancel) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: isProcessing ? null : onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                child: isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Cancelar solicitud'),
              ),
            ),
          ],
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
