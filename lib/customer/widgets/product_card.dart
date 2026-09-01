import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/app_network_image.dart';
import '../../core/widgets/price_text.dart';
import '../../models/product_model.dart';
import '../../providers/customer/cart_provider.dart';
import '../../providers/customer/favorite_provider.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.showAddToCart = true,
  });

  final ProductModel product;
  final bool showAddToCart;

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = context.watch<FavoriteProvider>();
    final cartProvider = context.watch<CartProvider>();
    final available = (product.quantity ?? 0) > 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.productDetail,
            arguments: product,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(url: product.image),
                  if (product.isFeatured == true)
                    const Positioned(
                      top: 8,
                      left: 8,
                      child: _Badge(
                        icon: Icons.star,
                        color: AppColors.accent,
                      ),
                    ),
                  if (!available)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.45),
                        alignment: Alignment.center,
                        child: const Text(
                          'Out of stock',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: product.id == null
                            ? null
                            : () => favoriteProvider.toggleFavorite(product),
                        borderRadius: BorderRadius.circular(20),
                        child: Ink(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            favoriteProvider.isFavorite(product.id)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 18,
                            color: favoriteProvider.isFavorite(product.id)
                                ? AppColors.error
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name ?? 'No name',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  PriceText(
                    price: product.offerPrice ?? product.price,
                    oldPrice: product.offerPrice != null ? product.price : null,
                    size: 15,
                    weight: FontWeight.w700,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (product.quantity != null)
                        Expanded(
                          child: Text(
                            available
                                ? '${product.quantity} in stock'
                                : 'Unavailable',
                            style: TextStyle(
                              fontSize: 11,
                              color: available
                                  ? AppColors.textSecondary
                                  : AppColors.error,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (showAddToCart && product.id != null)
                        IconButton(
                          onPressed: available && !cartProvider.isAdding
                              ? () => _addToCart(context, cartProvider)
                              : null,
                          icon: cartProvider.isAdding
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add_shopping_cart),
                          iconSize: 20,
                          color: AppColors.primary,
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Add to cart',
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

  Future<void> _addToCart(
    BuildContext context,
    CartProvider cartProvider,
  ) async {
    final success = await cartProvider.addItem(product);
    if (!success && context.mounted) {
      Helpers.showSnackBar(
        context,
        cartProvider.errorMessage ?? 'Could not add to cart.',
        isError: true,
      );
    }
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 14, color: Colors.white),
    );
  }
}