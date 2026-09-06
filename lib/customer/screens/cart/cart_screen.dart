import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../providers/customer/cart_provider.dart';
import '../../widgets/cart_item_card.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const double deliveryFee = 2.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().fetchCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        actions: [
          if (cartProvider.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: () {
                  cartProvider.clearCart();
                },
                child: const Text('Clear'),
              ),
            ),
        ],
      ),
      body: _buildBody(cartProvider),
    );
  }

  Widget _buildBody(CartProvider cartProvider) {
    if (cartProvider.isLoading && cartProvider.items.isEmpty) {
      return const LoadingWidget();
    }

    if (cartProvider.items.isEmpty) {
      return EmptyState(
        icon: Icons.shopping_cart_outlined,
        title: 'Your cart is empty',
        message: 'Add some delicious products to get started.',
        actionLabel: 'Browse Products',
        onAction: () {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          );
        },
      );
    }

    final subtotal = cartProvider.subtotal;

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => cartProvider.fetchCart(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: cartProvider.items.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: CartItemCard(item: cartProvider.items[index]),
                );
              },
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                _SummaryRow(label: 'Subtotal', value: '\$${subtotal.toStringAsFixed(2)}'),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Delivery fee', value: '\$${deliveryFee.toStringAsFixed(2)}'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1),
                ),
                _SummaryRow(
                  label: 'Total',
                  value: '\$${(subtotal + deliveryFee).toStringAsFixed(2)}',
                  emphasized: true,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.checkout);
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  child: const Text('Checkout', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: emphasized ? 17 : 14,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
            color: emphasized ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasized ? 17 : 14,
            fontWeight: FontWeight.w700,
            color: emphasized ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}