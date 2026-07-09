import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import 'models/product.dart';

/// -----------------------------------------------------------------------
/// EDICIÓN DE PRODUCTO
/// Formulario prellenado con los datos del producto. Sirve tanto para
/// "editar publicación" como de base para "publicar" (en ese caso solo
/// pásale un productId nuevo/opcional y ajusta el título del AppBar).
/// -----------------------------------------------------------------------
class ProductEditPage extends StatefulWidget {
  final String productId;
  const ProductEditPage({super.key, required this.productId});

  @override
  State<ProductEditPage> createState() => _ProductEditPageState();
}

class _ProductEditPageState extends State<ProductEditPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;

  late List<String> _imageUrls;
  late String _category;
  late ProductCondition _condition;

  bool _isSaving = false;

  Product? get _product => findProductById(widget.productId);

  @override
  void initState() {
    super.initState();
    final product = _product;
    _titleController = TextEditingController(text: product?.title ?? '');
    _priceController = TextEditingController(
      text: product != null ? product.price.toStringAsFixed(0) : '',
    );
    _descriptionController = TextEditingController(
      text: product?.description ?? '',
    );
    _locationController = TextEditingController(
      text: product?.location ?? 'Arequipa, Perú',
    );
    _imageUrls = List.of(product?.imageUrls ?? const []);
    _category =
        product?.category ?? productCategories.firstWhere((c) => c != 'Todos');
    _condition = product?.condition ?? ProductCondition.buenEstado;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final product = _product;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          'Editar publicación',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: product == null
          ? const Center(child: Text('Producto no encontrado'))
          : Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.horizontalPadding,
                  vertical: AppSpacing.md,
                ),
                children: [
                  const _FieldLabel('Fotos'),
                  const SizedBox(height: AppSpacing.sm),
                  _ImagesEditor(
                    imageUrls: _imageUrls,
                    onAdd: () {
                      // TODO: abre el selector de imágenes (image_picker) y
                      // agrega la url/ruta resultante a _imageUrls.
                      setState(() {
                        _imageUrls.add(
                          'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600',
                        );
                      });
                    },
                    onRemove: (index) =>
                        setState(() => _imageUrls.removeAt(index)),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _FieldLabel('Título'),
                  const SizedBox(height: AppSpacing.sm),
                  _FormTextField(
                    controller: _titleController,
                    hint: 'Ej. MacBook Air M1 2020',
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Ingresa un título'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _FieldLabel('Precio (S/)'),
                  const SizedBox(height: AppSpacing.sm),
                  _FormTextField(
                    controller: _priceController,
                    hint: 'Ej. 850',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    prefixText: 'S/ ',
                    validator: (value) {
                      final parsed = double.tryParse(value ?? '');
                      if (parsed == null || parsed <= 0) {
                        return 'Ingresa un precio válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _FieldLabel('Categoría'),
                  const SizedBox(height: AppSpacing.sm),
                  _CategoryDropdown(
                    value: _category,
                    onChanged: (value) => setState(() => _category = value),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _FieldLabel('Estado del producto'),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ProductCondition.values.map((condition) {
                      final isSelected = condition == _condition;
                      return ChoiceChip(
                        label: Text(condition.label),
                        selected: isSelected,
                        onSelected: (_) =>
                            setState(() => _condition = condition),
                        selectedColor: condition.color,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        backgroundColor: AppColors.fieldFill,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? condition.color
                                : AppColors.border,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _FieldLabel('Descripción'),
                  const SizedBox(height: AppSpacing.sm),
                  _FormTextField(
                    controller: _descriptionController,
                    hint: 'Cuenta más detalles sobre tu producto...',
                    maxLines: 5,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _FieldLabel('Ubicación'),
                  const SizedBox(height: AppSpacing.sm),
                  _FormTextField(
                    controller: _locationController,
                    hint: 'Ej. Arequipa, Perú',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Guardar cambios',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => context.pop(),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageUrls.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Agrega al menos una foto')));
      return;
    }

    setState(() => _isSaving = true);

    // TODO: reemplaza esto por la llamada real a tu backend
    // (Firestore/API) para actualizar el producto con:
    // _titleController.text, _priceController.text, _category,
    // _condition, _descriptionController.text, _locationController.text,
    // _imageUrls.
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Publicación actualizada')));
    context.pop();
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _FormTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? prefixText;
  final String? Function(String?)? validator;

  const _FormTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.prefixText,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14.5),
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefixText,
        hintStyle: const TextStyle(color: Color(0xFFB0B6C3)),
        filled: true,
        fillColor: AppColors.fieldFill,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _CategoryDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = productCategories.where((c) => c != 'Todos').toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: options.contains(value) ? value : options.first,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          style: const TextStyle(fontSize: 14.5, color: AppColors.textPrimary),
          items: options
              .map(
                (option) =>
                    DropdownMenuItem(value: option, child: Text(option)),
              )
              .toList(),
          onChanged: (newValue) {
            if (newValue != null) onChanged(newValue);
          },
        ),
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// EDITOR DE FOTOS: grid con las imágenes actuales + botón de agregar
/// -----------------------------------------------------------------------
class _ImagesEditor extends StatelessWidget {
  final List<String> imageUrls;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _ImagesEditor({
    required this.imageUrls,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == imageUrls.length) {
            return GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.fieldFill,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: AppColors.primary,
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Icon(
                  Icons.add_a_photo_outlined,
                  color: AppColors.primary,
                ),
              ),
            );
          }

          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Image.network(
                  imageUrls[index],
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 90,
                    height: 90,
                    color: AppColors.fieldFill,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => onRemove(index),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
