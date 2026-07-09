import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import 'models/product.dart';
import 'widgets/product_card.dart';

enum SortOption { relevancia, menorPrecio, mayorPrecio, masRecientes }

extension SortOptionX on SortOption {
  String get label {
    switch (this) {
      case SortOption.relevancia:
        return 'Relevancia';
      case SortOption.menorPrecio:
        return 'Menor precio';
      case SortOption.mayorPrecio:
        return 'Mayor precio';
      case SortOption.masRecientes:
        return 'Más recientes';
    }
  }
}

/// -----------------------------------------------------------------------
/// LISTADO / BUSCADOR DE PRODUCTOS
/// Pantalla con el catálogo completo. Incluye buscador en vivo, chips de
/// categoría, filtros (estado y precio) y toggle grid/lista.
/// -----------------------------------------------------------------------
class ProductListPage extends StatefulWidget {
  /// Categoría inicial opcional (por ejemplo si se llega desde un chip
  /// del Home ya con una categoría preseleccionada).
  final String? initialCategory;
  final String? initialQuery;

  const ProductListPage({super.key, this.initialCategory, this.initialQuery});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  late final TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();

  String _query = '';
  String _selectedCategory = 'Todos';
  bool _isGridView = true;
  SortOption _sortOption = SortOption.relevancia;
  RangeValues _priceRange = const RangeValues(0, 1000);
  final Set<ProductCondition> _selectedConditions = {};

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery ?? '';
    _selectedCategory = widget.initialCategory ?? 'Todos';
    _searchController = TextEditingController(text: _query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<Product> get _filteredProducts {
    var results = mockProducts.where((product) {
      final matchesQuery =
          _query.trim().isEmpty ||
          product.title.toLowerCase().contains(_query.trim().toLowerCase());
      final matchesCategory =
          _selectedCategory == 'Todos' || product.category == _selectedCategory;
      final matchesCondition =
          _selectedConditions.isEmpty ||
          _selectedConditions.contains(product.condition);
      final matchesPrice =
          product.price >= _priceRange.start &&
          product.price <= _priceRange.end;
      return matchesQuery &&
          matchesCategory &&
          matchesCondition &&
          matchesPrice;
    }).toList();

    switch (_sortOption) {
      case SortOption.menorPrecio:
        results.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortOption.mayorPrecio:
        results.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortOption.masRecientes:
        // TODO: ordena por fecha real cuando conectes tu backend.
        results = results.reversed.toList();
        break;
      case SortOption.relevancia:
        break;
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final results = _filteredProducts;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.horizontalPadding,
                AppSpacing.sm,
                responsive.horizontalPadding,
                0,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Padding(
                      padding: EdgeInsets.only(right: AppSpacing.sm),
                      child: Icon(
                        Icons.arrow_back,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _SearchField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: (value) => setState(() => _query = value),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  GestureDetector(
                    onTap: _openFiltersSheet,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 38,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.horizontalPadding,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: productCategories.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final category = productCategories[index];
                  final isSelected = category == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = category),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.horizontalPadding,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${results.length} resultado${results.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                  Row(
                    children: [
                      _ViewToggleButton(
                        icon: Icons.grid_view_rounded,
                        isSelected: _isGridView,
                        onTap: () => setState(() => _isGridView = true),
                      ),
                      const SizedBox(width: 6),
                      _ViewToggleButton(
                        icon: Icons.view_list_rounded,
                        isSelected: !_isGridView,
                        onTap: () => setState(() => _isGridView = false),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: results.isEmpty
                  ? _EmptyResults(query: _query)
                  : _isGridView
                  ? GridView.builder(
                      padding: EdgeInsets.fromLTRB(
                        responsive.horizontalPadding,
                        0,
                        responsive.horizontalPadding,
                        AppSpacing.xl,
                      ),
                      itemCount: results.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: AppSpacing.md,
                            crossAxisSpacing: AppSpacing.md,
                            childAspectRatio: 0.68,
                          ),
                      itemBuilder: (context, index) {
                        final product = results[index];
                        return ProductCard(
                          product: product,
                          onTap: () => context.push('/product/${product.id}'),
                        );
                      },
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        responsive.horizontalPadding,
                        0,
                        responsive.horizontalPadding,
                        AppSpacing.xl,
                      ),
                      itemCount: results.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final product = results[index];
                        return _ProductListTile(
                          product: product,
                          onTap: () => context.push('/product/${product.id}'),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFiltersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _FiltersSheet(
          sortOption: _sortOption,
          priceRange: _priceRange,
          selectedConditions: _selectedConditions,
          onApply: (sort, price, conditions) {
            setState(() {
              _sortOption = sort;
              _priceRange = price;
              _selectedConditions
                ..clear()
                ..addAll(conditions);
            });
          },
        );
      },
    );
  }
}

/// -----------------------------------------------------------------------
/// BUSCADOR EDITABLE (a diferencia del Home, aquí sí se escribe)
/// -----------------------------------------------------------------------
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 14.5),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Buscar productos...',
                hintStyle: TextStyle(color: Color(0xFFB0B6C3)),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewToggleButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Tarjeta horizontal usada en la vista de lista (toggle de lista).
class _ProductListTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductListTile({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Image.network(
                product.imageUrl,
                width: 84,
                height: 84,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 84,
                  height: 84,
                  color: AppColors.fieldFill,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'S/${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: product.condition.color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          product.condition.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${product.category} · ${product.timeAgo}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  final String query;
  const _EmptyResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              query.trim().isEmpty
                  ? 'No hay productos con estos filtros'
                  : 'Sin resultados para "$query"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Prueba con otra palabra o quita algunos filtros.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// HOJA DE FILTROS (orden, precio, estado)
/// -----------------------------------------------------------------------
class _FiltersSheet extends StatefulWidget {
  final SortOption sortOption;
  final RangeValues priceRange;
  final Set<ProductCondition> selectedConditions;
  final void Function(
    SortOption sort,
    RangeValues price,
    Set<ProductCondition> conditions,
  )
  onApply;

  const _FiltersSheet({
    required this.sortOption,
    required this.priceRange,
    required this.selectedConditions,
    required this.onApply,
  });

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late SortOption _sortOption = widget.sortOption;
  late RangeValues _priceRange = widget.priceRange;
  late Set<ProductCondition> _conditions = {...widget.selectedConditions};

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const Text(
            'Filtros',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Ordenar por',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SortOption.values.map((option) {
              final isSelected = option == _sortOption;
              return ChoiceChip(
                label: Text(option.label),
                selected: isSelected,
                onSelected: (_) => setState(() => _sortOption = option),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontSize: 13,
                ),
                backgroundColor: AppColors.fieldFill,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Estado',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ProductCondition.values.map((condition) {
              final isSelected = _conditions.contains(condition);
              return FilterChip(
                label: Text(condition.label),
                selected: isSelected,
                onSelected: (selected) => setState(() {
                  if (selected) {
                    _conditions.add(condition);
                  } else {
                    _conditions.remove(condition);
                  }
                }),
                selectedColor: condition.color.withValues(alpha: 0.15),
                checkmarkColor: condition.color,
                labelStyle: TextStyle(
                  color: isSelected ? condition.color : AppColors.textPrimary,
                  fontSize: 13,
                ),
                backgroundColor: AppColors.fieldFill,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? condition.color : AppColors.border,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rango de precio',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
              ),
              Text(
                'S/${_priceRange.start.round()} - S/${_priceRange.end.round()}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 1000,
            divisions: 20,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.border,
            onChanged: (values) => setState(() => _priceRange = values),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _sortOption = SortOption.relevancia;
                      _priceRange = const RangeValues(0, 1000);
                      _conditions = {};
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  child: const Text(
                    'Limpiar',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_sortOption, _priceRange, _conditions);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  child: const Text(
                    'Aplicar filtros',
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
}
