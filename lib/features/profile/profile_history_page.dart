import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import 'models/profile_models.dart';
import 'widgets/profile_widgets.dart';

const _months = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

String _formatDate(DateTime date) => '${date.day} ${_months[date.month - 1]} ${date.year}';

/// -----------------------------------------------------------------------
/// HISTORIAL DE COMPRAS Y VENTAS
/// -----------------------------------------------------------------------
class ProfileHistoryPage extends StatefulWidget {
  const ProfileHistoryPage({super.key});

  @override
  State<ProfileHistoryPage> createState() => _ProfileHistoryPageState();
}

class _ProfileHistoryPageState extends State<ProfileHistoryPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

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
          child: Column(
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
                  onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Buscar por producto o persona…',
                    hintStyle: const TextStyle(fontSize: 13.5),
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
                  labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
                      type: TransactionType.compra,
                      query: _query,
                      responsive: responsive,
                    ),
                    _HistoryList(
                      type: TransactionType.venta,
                      query: _query,
                      responsive: responsive,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  final TransactionType type;
  final String query;
  final Responsive responsive;

  const _HistoryList({required this.type, required this.query, required this.responsive});

  @override
  Widget build(BuildContext context) {
    var items = MockProfileRepository.transactions.where((t) => t.type == type).toList();
    if (query.isNotEmpty) {
      items = items
          .where((t) =>
              t.productName.toLowerCase().contains(query) ||
              t.counterpartName.toLowerCase().contains(query))
          .toList();
    }
    items.sort((a, b) => b.date.compareTo(a.date));

    if (items.isEmpty) {
      return ListView(
        padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
        children: [
          ProfileEmptyState(
            icon: type == TransactionType.compra ? Icons.shopping_bag_outlined : Icons.sell_outlined,
            title: query.isNotEmpty ? 'Sin resultados' : 'Aún no hay movimientos',
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
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) => _TransactionTile(transaction: items[index]),
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (isCompra ? AppColors.primary : AppColors.success).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompra ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                size: 18,
                color: isCompra ? AppColors.primary : AppColors.success,
              ),
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
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${isCompra ? 'Vendedor' : 'Comprador'}: ${transaction.counterpartName}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(transaction.date),
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'S/ ${transaction.amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                const SizedBox(height: 4),
                StatusChip(label: transaction.status.label, color: transaction.status.color),
              ],
            ),
          ],
        ),
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
              Text(
                transaction.productName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const SizedBox(height: AppSpacing.md),
              _DetailRow(label: 'Tipo', value: isCompra ? 'Compra' : 'Venta'),
              _DetailRow(label: isCompra ? 'Vendedor' : 'Comprador', value: transaction.counterpartName),
              _DetailRow(label: 'Fecha', value: _formatDate(transaction.date)),
              _DetailRow(label: 'Monto', value: 'S/ ${transaction.amount.toStringAsFixed(2)}'),
              _DetailRow(label: 'Código', value: '#${transaction.id}'),
              const SizedBox(height: AppSpacing.sm),
              StatusChip(label: transaction.status.label, color: transaction.status.color),
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
                  child: const Text('Cerrar', style: TextStyle(fontWeight: FontWeight.w600)),
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
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
        ],
      ),
    );
  }
}