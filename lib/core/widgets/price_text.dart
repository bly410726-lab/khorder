import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class PriceText extends StatelessWidget {
  const PriceText({
    super.key,
    required this.price,
    this.oldPrice,
    this.size = 16,
    this.weight = FontWeight.w600,
    this.color = AppColors.primary,
  });

  final num? price;
  final num? oldPrice;
  final double size;
  final FontWeight weight;
  final Color color;

  static String _fmt(num? value) {
    if (value == null) return '\$0.00';
    return '\$${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final hasDiscount = oldPrice != null && oldPrice! > (price ?? 0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          _fmt(price),
          style: TextStyle(
            fontSize: size,
            fontWeight: weight,
            color: color,
          ),
        ),
        if (hasDiscount) ...[
          const SizedBox(width: 6),
          Text(
            _fmt(oldPrice),
            style: TextStyle(
              fontSize: size - 4,
              color: AppColors.textSecondary,
              decoration: TextDecoration.lineThrough,
              decorationColor: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
