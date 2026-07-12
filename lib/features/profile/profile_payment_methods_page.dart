import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import 'models/profile_models.dart';
import 'widgets/profile_widgets.dart';

/// -----------------------------------------------------------------------
/// MÉTODOS DE PAGO
/// -----------------------------------------------------------------------
class ProfilePaymentMethodsPage extends StatefulWidget {
  const ProfilePaymentMethodsPage({super.key});

  @override
  State<ProfilePaymentMethodsPage> createState() => _ProfilePaymentMethodsPageState();
}

class _ProfilePaymentMethodsPageState extends State<ProfilePaymentMethodsPage> {
  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final methods = MockProfileRepository.paymentMethods;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientSubHeader(
        title: 'Métodos de pago',
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        top: false,
        child: methods.isEmpty
            ? ListView(
                padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
                children: [
                  const ProfileEmptyState(
                    icon: Icons.credit_card_outlined,
                    title: 'Sin métodos de pago',
                    message: 'Agrega una tarjeta para comprar más rápido.',
                  ),
                ],
              )
            : ListView.separated(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.horizontalPadding,
                  vertical: AppSpacing.lg,
                ),
                itemCount: methods.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) => _PaymentCard(
                  method: methods[index],
                  onChanged: () => setState(() {}),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Agregar tarjeta'),
        onPressed: () => _openAddSheet(context),
      ),
    );
  }

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetContext) => _AddCardSheet(
        onAdded: () => setState(() {}),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final PaymentMethod method;
  final VoidCallback onChanged;

  const _PaymentCard({required this.method, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: method.type.gradient,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                method.type.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  if (method.isDefault)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Text(
                        'Predeterminada',
                        style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) => _handleAction(context, value),
                    itemBuilder: (context) => [
                      if (!method.isDefault)
                        const PopupMenuItem(value: 'default', child: Text('Marcar como predeterminada')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Eliminar', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '•••• •••• •••• ${method.last4}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                method.holderName,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12.5),
              ),
              Text(
                method.expiry,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, String action) {
    final methods = MockProfileRepository.paymentMethods;
    switch (action) {
      case 'default':
        for (var i = 0; i < methods.length; i++) {
          methods[i] = methods[i].copyWith(isDefault: methods[i].id == method.id);
        }
        onChanged();
        return;
      case 'delete':
        _confirmDelete(context);
        return;
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        title: const Text('Eliminar tarjeta'),
        content: Text('¿Eliminar la tarjeta terminada en ${method.last4}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              MockProfileRepository.paymentMethods.removeWhere((m) => m.id == method.id);
              Navigator.of(dialogContext).pop();
              onChanged();
            },
            child: const Text('Eliminar', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _AddCardSheet extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddCardSheet({required this.onAdded});

  @override
  State<_AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends State<_AddCardSheet> {
  final _formKey = GlobalKey<FormState>();
  final _holderCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  @override
  void dispose() {
    _holderCtrl.dispose();
    _numberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Agregar tarjeta',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _holderCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Nombre del titular'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _numberCtrl,
              keyboardType: TextInputType.number,
              maxLength: 16,
              decoration: const InputDecoration(labelText: 'Número de tarjeta'),
              validator: (v) => (v == null || v.trim().length < 13) ? 'Número inválido' : null,
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryCtrl,
                    decoration: const InputDecoration(labelText: 'MM/AA'),
                    validator: (v) =>
                        (v == null || !RegExp(r'^\d{2}/\d{2}$').hasMatch(v)) ? 'MM/AA' : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextFormField(
                    controller: _cvvCtrl,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    decoration: const InputDecoration(labelText: 'CVV'),
                    validator: (v) => (v == null || v.length < 3) ? 'CVV inválido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                child: const Text('Guardar tarjeta', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final number = _numberCtrl.text.trim();
    final newMethod = PaymentMethod(
      id: 'p-${DateTime.now().millisecondsSinceEpoch}',
      type: PaymentMethodTypeX.fromNumber(number),
      holderName: _holderCtrl.text.trim().toUpperCase(),
      last4: number.substring(number.length - 4),
      expiry: _expiryCtrl.text.trim(),
      isDefault: MockProfileRepository.paymentMethods.isEmpty,
    );

    MockProfileRepository.paymentMethods.add(newMethod);
    widget.onAdded();
    Navigator.of(context).pop();
  }
}