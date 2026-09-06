import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_network_image.dart';
import '../../models/product_model.dart';
import '../../core/widgets/status_badge.dart';

class AdminProductCard extends StatelessWidget {
  const AdminProductCard({
    super.key,
    required this.product,
    this.onEdit,
    this.onDelete,
  });

  final ProductModel product;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final available = (product.quantity ?? 0) > 0;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 52,
            height: 52,
            child: AppNetworkImage(url: product.image, icon: Icons.fastfood),
          ),
        ),
        title: Text(
          product.name ?? 'No name',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\$${(product.price ?? 0).toStringAsFixed(2)}'
                '${product.offerPrice != null ? '  →  \$${product.offerPrice!.toStringAsFixed(2)}' : ''}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  StatusBadge(status: available ? 'available' : 'unavailable'),
                  const SizedBox(width: 8),
                  Text(
                    'Stock: ${product.quantity ?? 0}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              color: AppColors.primary,
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: AppColors.error,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}