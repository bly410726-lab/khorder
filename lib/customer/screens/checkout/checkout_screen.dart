import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../models/delivery_location_model.dart';
import '../../../models/order_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/customer/cart_provider.dart';
import '../../../providers/customer/order_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const double deliveryFee = 2.0;

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  DeliveryLocation? _deliveryLocation;
  String _paymentMethod = 'cod';
  bool _isInitialized = false;

  static const _paymentMethods = [
    (
    'cod',
    'Cash on Delivery',
    Icons.payments_outlined,
    ),
    (
    'khqr',
    'KHQR / ABA Pay',
    Icons.qr_code_2,
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Autofill user information if available asynchronously
    if (!_isInitialized) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        if (_nameController.text.isEmpty) _nameController.text = user.name ?? '';
        if (_phoneController.text.isEmpty) _phoneController.text = user.phone ?? '';
      }
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final orderProvider = context.watch<OrderProvider>();

    final items = cartProvider.items;
    final subtotal = cartProvider.subtotal;
    final total = subtotal + deliveryFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: items.isEmpty
          ? const Center(
        child: Text('Your cart is empty'),
      )
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // =========================================================
            // DELIVERY INFORMATION
            // =========================================================
            _SectionCard(
              title: 'Delivery Information',
              icon: Icons.local_shipping_outlined,
              child: Column(
                children: [
                  CustomTextField(
                    controller: _nameController,
                    labelText: 'Full Name',
                    icon: Icons.person_outline,
                    validator: Validators.validateName,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _phoneController,
                    labelText: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: Validators.validatePhone,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _addressController,
                    labelText: 'Delivery Address',
                    icon: Icons.location_on_outlined,
                    validator: Validators.validateAddress,
                    readOnly: true,
                    onTap: _pickDeliveryLocation,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.map_outlined, color: AppColors.primary),
                      onPressed: _pickDeliveryLocation,
                    ),
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _notesController,
                    labelText: 'Note (optional)',
                    icon: Icons.notes_outlined,
                    maxLines: 2,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // =========================================================
            // PAYMENT METHOD
            // =========================================================
            _SectionCard(
              title: 'Payment Method',
              icon: Icons.credit_card_outlined,
              child: Column(
                children: _paymentMethods.map((method) {
                  final key = method.$1;
                  final title = method.$2;
                  final icon = method.$3;

                  return RadioListTile<String>(
                    value: key,
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _paymentMethod = value;
                        });
                      }
                    },
                    title: Text(title),
                    secondary: Icon(
                      icon,
                      color: AppColors.primary,
                    ),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 14),

            // =========================================================
            // ORDER SUMMARY
            // =========================================================
            _SectionCard(
              title: 'Order Summary',
              icon: Icons.receipt_long_outlined,
              child: Column(
                children: [
                  ...items.map(
                        (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.product?.name ?? 'Product'} × ${item.quantity}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            '\$${item.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 16),
                  _Row(
                    label: 'Subtotal',
                    value: '\$${subtotal.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 4),
                  _Row(
                    label: 'Delivery fee',
                    value: '\$${deliveryFee.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 4),
                  _Row(
                    label: 'Total',
                    value: '\$${total.toStringAsFixed(2)}',
                    emphasized: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // =========================================================
            // PLACE ORDER BUTTON
            // =========================================================
            FilledButton(
              onPressed: orderProvider.isPlacingOrder
                  ? null
                  : () => _handlePlaceOrder(orderProvider, cartProvider),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
              ),
              child: orderProvider.isPlacingOrder
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text(
                'Place Order',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  // DELIVERY LOCATION PICKER
  // ===========================================================

  Future<void> _pickDeliveryLocation() async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.mapPicker,
      arguments: _deliveryLocation,
    );
    if (result is DeliveryLocation && mounted) {
      setState(() {
        _deliveryLocation = result;
        _addressController.text = result.address;
      });
    }
  }

  // ===========================================================
  // PLACE ORDER ACTION
  // ===========================================================

  Future<void> _handlePlaceOrder(
      OrderProvider orderProvider,
      CartProvider cartProvider,
      ) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_paymentMethod == 'khqr') {
      _showKhqrModal(orderProvider, cartProvider);
    } else {
      await _processOrderPlacement(orderProvider, cartProvider);
    }
  }

  Future<void> _processOrderPlacement(
      OrderProvider orderProvider,
      CartProvider cartProvider,
      ) async {
    try {
      final order = await orderProvider.placeOrder(
        deliveryAddress: _addressController.text.trim(),
        shippingPhone: _phoneController.text.trim(),
        paymentMethod: _paymentMethod,
        deliveryFee: deliveryFee,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;

      if (order != null) {
        await cartProvider.clearCart();
        _showSuccessAndNavigate(order);
      } else {
        Helpers.showSnackBar(
          context,
          'Failed to place order. Please try again.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      Helpers.showSnackBar(
        context,
        'An error occurred: ${e.toString()}',
      );
    }
  }

  // ===========================================================
  // KHQR MODAL DIALOG
  // ===========================================================

  void _showKhqrModal(
      OrderProvider orderProvider,
      CartProvider cartProvider,
      ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.qr_code_2, color: AppColors.primary),
              SizedBox(width: 8),
              Text('KHQR Payment'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.qr_code_2,
                    size: 160,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Customer: ${_nameController.text}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text(
                'Scan this QR code with any mobile banking app to complete payment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _processOrderPlacement(orderProvider, cartProvider);
              },
              child: const Text('Confirm & Pay'),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================
  // SUCCESS & NAVIGATION
  // ===========================================================

  void _showSuccessAndNavigate(OrderModel order) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 56,
        ),
        title: const Text('Order Placed!'),
        content: const Text(
          'Thank you for your order. You can track its status in My Orders.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
              Navigator.pushNamed(
                context,
                AppRoutes.orderDetail,
                arguments: order.id,
              );
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size(150, 46),
            ),
            child: const Text('View Order'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SECTION CARD
// ============================================================================

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SUMMARY ROW
// ============================================================================

class _Row extends StatelessWidget {
  const _Row({
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
            fontSize: emphasized ? 16 : 14,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
            color: emphasized ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasized ? 16 : 14,
            fontWeight: FontWeight.w700,
            color: emphasized ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}