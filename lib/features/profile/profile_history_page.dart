import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/services/firestore_service.dart'; // ajusta la ruta real
import 'models/profile_models.dart';
import 'widgets/profile_widgets.dart';

const _months = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

String _formatDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';

/// -----------------------------------------------------------------------
/// HISTORIAL DE COMPRAS Y VENTAS (datos reales de Firestore)
/// -----------------------------------------------------------------------
class ProfileHistoryPage extends StatefulWidget {
  const ProfileHistoryPage({super.key});

  @override
  State<ProfileHistoryPage> createState() => _ProfileHistoryPageState();
}

class _ProfileHistoryPageState extends State<ProfileHistoryPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  // FIX: el stream se cachea aquí y NO se crea dentro de build().
  // Antes, cada letra escrita en el buscador hacía setState() -> build()
  // -> se llamaba watchUserTransactions(uid) de nuevo -> Firestore cerraba
  // la suscripción anterior a medio camino -> pantalla "colgada"
  // parpadeando. Igual que pasaba en el Home con "Tecnología".
  String? _cachedUid;
  Stream<List<ProfileTransaction>>? _transactionsStream;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  void _ensureStream(String uid) {
    if (_cachedUid != uid || _transactionsStream == null) {
      _cachedUid = uid;
      _transactionsStream = FirestoreService.watchUserTransactions(uid);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final uid = _uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    _ensureStream(uid);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: GradientSubHeader(
          title: 'Historial',
          onBack: () => context.pop(),
        ),
        body: SafeArea(
          top: false,
          child: StreamBuilder<List<ProfileTransaction>>(
            stream: _transactionsStream,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                debugPrint('Error cargando historial: ${snap.error}');
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No se pudo cargar tu historial. Intenta de nuevo en unos minutos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                );
              }
              final all = snap.data ?? [];

              return Column(
                children: [
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.fromLTRB(
                      responsive.horizontalPadding,
                      AppSpacing.sm,
                      responsive.horizontalPadding,
                      0,
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) =>
                          setState(() => _query = v.trim().toLowerCase()),
                      decoration: InputDecoration(
                        hintText: 'Buscar por producto o persona…',
                        hintStyle: const TextStyle(fontSize: 13.5),
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    color: Colors.white,
                    child: const TabBar(
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primary,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      tabs: [
                        Tab(text: 'Compras'),
                        Tab(text: 'Ventas'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _HistoryList(
                          items: all
                              .where((t) => t.type == TransactionType.compra)
                              .toList(),
                          type: TransactionType.compra,
                          query: _query,
                          responsive: responsive,
                        ),
                        _HistoryList(
                          items: all
                              .where((t) => t.type == TransactionType.venta)
                              .toList(),
                          type: TransactionType.venta,
                          query: _query,
                          responsive: responsive,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  final List<ProfileTransaction> items;
  final TransactionType type;
  final String query;
  final Responsive responsive;

  const _HistoryList({
    required this.items,
    required this.type,
    required this.query,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    var filtered = items;
    if (query.isNotEmpty) {
      filtered = filtered
          .where(
            (t) =>
                t.productName.toLowerCase().contains(query) ||
                t.counterpartName.toLowerCase().contains(query),
          )
          .toList();
    }
    filtered.sort((a, b) => b.date.compareTo(a.date));

    if (filtered.isEmpty) {
      return ListView(
        padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
        children: [
          ProfileEmptyState(
            icon: type == TransactionType.compra
                ? Icons.shopping_bag_outlined
                : Icons.sell_outlined,
            title: query.isNotEmpty
                ? 'Sin resultados'
                : 'Aún no hay movimientos',
            message: query.isNotEmpty
                ? 'No encontramos nada para "$query".'
                : type == TransactionType.compra
                ? 'Tus compras aparecerán aquí.'
                : 'Tus ventas aparecerán aquí.',
          ),
        ],
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.horizontalPadding,
        vertical: AppSpacing.md,
      ),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) =>
          _TransactionTile(transaction: filtered[index]),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final ProfileTransaction transaction;
  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCompra = transaction.type == TransactionType.compra;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: transaction.productImageUrl.isNotEmpty
                  ? Image.network(
                      transaction.productImageUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _fallbackIcon(isCompra),
                    )
                  : _fallbackIcon(isCompra),
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
                    '${isCompra ? 'Vendedor' : 'Comprador'}: ${transaction.counterpartName}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(transaction.date),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'S/ ${transaction.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 4),
                StatusChip(
                  label: transaction.status.label,
                  color: transaction.status.color,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackIcon(bool isCompra) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: (isCompra ? AppColors.primary : AppColors.success).withValues(
          alpha: 0.1,
        ),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(
        isCompra ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
        size: 20,
        color: isCompra ? AppColors.primary : AppColors.success,
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final isCompra = transaction.type == TransactionType.compra;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (transaction.productImageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Image.network(
                    transaction.productImageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                transaction.productName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _DetailRow(label: 'Tipo', value: isCompra ? 'Compra' : 'Venta'),
              _DetailRow(
                label: isCompra ? 'Vendedor' : 'Comprador',
                value: transaction.counterpartName,
              ),
              _DetailRow(label: 'Fecha', value: _formatDate(transaction.date)),
              _DetailRow(
                label: 'Monto',
                value: 'S/ ${transaction.amount.toStringAsFixed(2)}',
              ),
              _DetailRow(label: 'Código', value: '#${transaction.id}'),
              const SizedBox(height: AppSpacing.sm),
              StatusChip(
                label: transaction.status.label,
                color: transaction.status.color,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
          ),
        ],
      ),
    );
  }
}
