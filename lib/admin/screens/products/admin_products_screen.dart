import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../models/product_model.dart';
import '../../../providers/admin/admin_product_provider.dart';
import '../../widgets/admin_drawer.dart';
import '../../widgets/admin_product_card.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProductProvider>().fetchProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProductModel> _filtered(List<ProductModel> products) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return products;
    return products.where((p) {
      return (p.name?.toLowerCase().contains(q) ?? false) ||
          (p.category?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProductProvider>();
    final products = _filtered(provider.products);

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      drawer: const AdminDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.adminAddProduct);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ),
          ),
          Expanded(
            child: _buildContent(provider, products),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AdminProductProvider provider, List<ProductModel> products) {
    if (provider.isLoading && provider.products.isEmpty) {
      return const LoadingWidget();
    }
    if (provider.errorMessage != null && provider.products.isEmpty) {
      return AppErrorWidget(
        message: provider.errorMessage!,
        onRetry: () => provider.fetchProducts(),
      );
    }
    if (products.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        title: provider.products.isEmpty
            ? 'No products yet'
            : 'No matching products',
        message: provider.products.isEmpty
            ? 'Tap the Add Product button to create your first product.'
            : 'Try a different search.',
      );
    }
    return RefreshIndicator(
      onRefresh: () => provider.fetchProducts(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final product = products[index];
          return AdminProductCard(
            product: product,
            onEdit: () {
              Navigator.pushNamed(
                context,
                AppRoutes.adminEditProduct,
                arguments: product,
              );
            },
            onDelete: () => _deleteProduct(context, provider, product),
          );
        },
      ),
    );
  }

  Future<void> _deleteProduct(
    BuildContext context,
    AdminProductProvider provider,
    ProductModel product,
  ) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Product',
      message: 'Are you sure you want to delete this product?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final success = await provider.deleteProduct(product.id ?? -1);
    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Could not delete product'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}