import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/price_text.dart';
import '../../../core/widgets/quantity_selector.dart';
import '../../../models/product_model.dart';
import '../../../providers/customer/cart_provider.dart';
import '../../../providers/customer/favorite_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  ProductModel? _product;

  @override
  void initState() {
    super.initState();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ProductModel) {
      _product = args;
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product')),
        body: const Center(child: Text('Product not found')),
      );
    }

    final cartProvider = context.watch<CartProvider>();
    final favoriteProvider = context.watch<FavoriteProvider>();
    final available = (product.quantity ?? 0) > 0;
    final price = product.offerPrice ?? product.price;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          IconButton(
            icon: Icon(
              favoriteProvider.isFavorite(product.id)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: favoriteProvider.isFavorite(product.id)
                  ? AppColors.error
                  : null,
            ),
            onPressed: () {
              favoriteProvider.toggleFavorite(product);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                AspectRatio(
                  aspectRatio: 1.15,
                  child: AppNetworkImage(
                    url: product.image,
                    icon: Icons.storefront,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name ?? 'Product',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (product.category != null) ...[
                                  const SizedBox(height: 6),
                                  _Tag(label: product.category!),
                                ],
                              ],
                            ),
                          ),
                          if (product.isFeatured == true)
                            const _Tag(label: 'Featured', featured: true),
                        ],
                      ),
                      const SizedBox(height: 12),
                      PriceText(
                        price: price,
                        oldPrice: product.offerPrice != null
                            ? product.price
                            : null,
                        size: 24,
                        weight: FontWeight.w800,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        available
                            ? 'In stock: ${product.quantity} available'
                            : 'Out of stock',
                        style: TextStyle(
                          color: available
                              ? AppColors.success
                              : AppColors.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Divider(height: 32),
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFamily: 'Battambang',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description?.isNotEmpty == true
                            ? product.description!
                            : 'No description available for this product.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  if (available)
                    QuantitySelector(
                      quantity: _quantity,
                      max: product.quantity,
                      onChanged: (value) => setState(() => _quantity = value),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          available && !cartProvider.isAdding
                              ? () => _addToCart(context, cartProvider)
                              : null,
                      icon: cartProvider.isAdding
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add_shopping_cart),
                      label: Text(
                        available
                            ? 'Add to Cart'
                            : 'Out of Stock',
                        style: const TextStyle(fontSize: 15),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addToCart(BuildContext context, CartProvider cartProvider) async {
    final success = await cartProvider.addItem(
      _product!,
      quantity: _quantity,
    );
    if (!context.mounted) return;
    if (success) {
      Helpers.showSnackBar(context, 'Added to cart');
    } else {
      Helpers.showSnackBar(
        context,
        cartProvider.errorMessage ?? 'Could not add to cart.',
        isError: true,
      );
    }
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, this.featured = false});

  final String label;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: featured ? AppColors.accent : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: featured ? Colors.white : AppColors.primary,
        ),
      ),
    );
  }
}