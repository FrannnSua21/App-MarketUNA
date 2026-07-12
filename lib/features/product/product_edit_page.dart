import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../core/services/firestore_service.dart'; // ajusta la ruta real
import 'models/product.dart';

/// API key gratuita de https://api.imgbb.com (no pide tarjeta).
const String _imgbbApiKey = 'cc88c73fafa9ce4a884d123dea16157e';

class ProductEditPage extends StatefulWidget {
  /// null = crear publicación nueva. Con valor = editar esa existente.
  final String? productId;
  const ProductEditPage({super.key, this.productId});

  @override
  State<ProductEditPage> createState() => _ProductEditPageState();
}

class _ProductEditPageState extends State<ProductEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;

  /// Cada elemento es String (url ya subida) o File (foto local sin subir).
  List<dynamic> _images = [];
  String _category = productCategories.firstWhere((c) => c != 'Todos');
  ProductCondition _condition = ProductCondition.buenEstado;

  bool _isSaving = false;
  bool _isLoadingProduct = true;
  Product? _existingProduct;

  bool get _isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _priceController = TextEditingController();
    _descriptionController = TextEditingController();
    _locationController = TextEditingController(text: 'Arequipa, Perú');
    _loadIfEditing();
  }

  Future<void> _loadIfEditing() async {
    if (_isEditing) {
      final product = await FirestoreService.getProductById(widget.productId!);
      if (product != null) {
        _existingProduct = product;
        _titleController.text = product.title;
        _priceController.text = product.price.toStringAsFixed(0);
        _descriptionController.text = product.description;
        _locationController.text = product.location;
        _images = List.of(product.imageUrls);
        _category = product.category;
        _condition = product.condition;
      }
    }
    if (mounted) setState(() => _isLoadingProduct = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final xfile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1280,
    );
    if (xfile != null) {
      setState(() => _images.add(File(xfile.path)));
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  Future<List<String>> _uploadPendingImages() async {
    final result = <String>[];
    for (final item in _images) {
      if (item is String) {
        result.add(item);
      } else if (item is File) {
        result.add(await _uploadSingleImageToImgbb(item));
      }
    }
    return result;
  }

  Future<String> _uploadSingleImageToImgbb(File file) async {
    final bytes = await file.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http.post(
      Uri.parse('https://api.imgbb.com/1/upload?key=$_imgbbApiKey'),
      body: {'image': base64Image},
    );

    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      return data['data']['url'] as String;
    }
    throw Exception(
      'No se pudo subir la imagen: ${data['error']?['message'] ?? 'error desconocido'}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          _isEditing ? 'Editar publicación' : 'Publicar producto',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoadingProduct
          ? const Center(child: CircularProgressIndicator())
          : (_isEditing && _existingProduct == null)
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
                    images: _images,
                    onAdd: _pickImage,
                    onRemove: _removeImage,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _FieldLabel('Título'),
                  const SizedBox(height: AppSpacing.sm),
                  _FormTextField(
                    controller: _titleController,
                    hint: 'Ej. MacBook Air M1 2020',
                    validator: (v) => (v == null || v.trim().isEmpty)
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
                    validator: (v) {
                      final parsed = double.tryParse(v ?? '');
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
                    onChanged: (v) => setState(() => _category = v),
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
                          : Text(
                              _isEditing ? 'Guardar cambios' : 'Publicar',
                              style: const TextStyle(
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
    if (_images.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Agrega al menos una foto')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final price = double.parse(_priceController.text);
      final urls = await _uploadPendingImages();

      if (_isEditing) {
        await FirestoreService.updateProduct(widget.productId!, {
          'title': _titleController.text.trim(),
          'price': price,
          'category': _category,
          'condition': _condition.name,
          'description': _descriptionController.text.trim(),
          'location': _locationController.text.trim(),
          'imageUrls': urls,
        });
      } else {
        final docRef = FirestoreService.newProductRef();
        final product = Product(
          id: docRef.id,
          sellerId: uid,
          title: _titleController.text.trim(),
          price: price,
          category: _category,
          timeAgo: '',
          condition: _condition,
          imageUrls: urls,
          description: _descriptionController.text.trim(),
          location: _locationController.text.trim(),
        );

        final data = product.toMap();
        data['createdAt'] = FieldValue.serverTimestamp();
        data['updatedAt'] = FieldValue.serverTimestamp();
        await docRef.set(data);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Publicación actualizada' : 'Producto publicado',
          ),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
  );
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
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _ImagesEditor extends StatelessWidget {
  final List<dynamic> images;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _ImagesEditor({
    required this.images,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == images.length) {
            return GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.fieldFill,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.primary),
                ),
                child: const Icon(
                  Icons.add_a_photo_outlined,
                  color: AppColors.primary,
                ),
              ),
            );
          }

          final item = images[index];
          Widget imageWidget;
          if (item is String) {
            imageWidget = Image.network(
              item,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 90,
                height: 90,
                color: AppColors.fieldFill,
                child: const Icon(Icons.image_not_supported_outlined),
              ),
            );
          } else {
            imageWidget = Image.file(
              item as File,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
            );
          }

          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: imageWidget,
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
