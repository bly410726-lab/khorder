import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../models/category_model.dart';
import '../../../providers/customer/category_provider.dart';
import '../../../providers/customer/product_provider.dart';
import '../../widgets/product_card.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  int? _selectedCategoryId;
  bool _isInitialized = false;
  @override
  void didChangeDependencies(){
    super.didChangeDependencies();

    if(!_isInitialized ){
      final args = ModalRoute.of(context)?.settings.arguments as CategoryModel? ;
      final productProvider = context.read<ProductProvider>();

      _selectedCategoryId = args?.id ?? productProvider.selectedCategoryId ;
      _load() ;

      _isInitialized = true ;

    }
  }

  // @override
  // void initState() {
  //   super.initState();
  //   final args = ModalRoute.of(context)?.settings.arguments as CategoryModel?;
  //   final productProvider = context.read<ProductProvider>();
  //   _selectedCategoryId = args?.id ?? productProvider.selectedCategoryId;
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     _load();
  //   });
  // }

  Future<void> _load() async {
    final categoryProvider = context.read<CategoryProvider>();
    await categoryProvider.fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final categories = categoryProvider.categories;

    final products = _selectedCategoryId == null
        ? productProvider.products
        : productProvider.products
            .where((p) => p.categoryId == _selectedCategoryId)
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: Column(
        children: [
          const SizedBox(height: 4),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _CategoryChip(
                  label: 'All',
                  selected: _selectedCategoryId == null,
                  onTap: () {
                    setState(() => _selectedCategoryId = null);
                    productProvider.setSelectedCategory(null);
                  },
                ),
                const SizedBox(width: 8),
                ...categories.map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _CategoryChip(
                      label: category.name ?? 'Category',
                      selected: _selectedCategoryId == category.id,
                      onTap: () {
                        setState(() => _selectedCategoryId = category.id);
                        productProvider.setSelectedCategory(category.id);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: categoryProvider.isLoading && categories.isEmpty
                ? const LoadingWidget()
                : categoryProvider.errorMessage != null && categories.isEmpty
                    ? AppErrorWidget(
                        message: categoryProvider.errorMessage!,
                        onRetry: _load,
                      )
                    : products.isEmpty
                        ? EmptyState(
                            icon: Icons.category_outlined,
                            title: 'No products in this category',
                            message: 'Check back later for new items.',
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(12),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.68,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: products.length,
                            itemBuilder: (context, index) =>
                                ProductCard(product: products[index]),
                          ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}