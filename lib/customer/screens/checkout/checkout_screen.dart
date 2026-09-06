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
import 'map_picker_screen.dart';

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
  String _paymentMethod = 'cod';
  DeliveryLocation? _deliveryLocation;

  static const _paymentMethods = [
    ('cod', 'Cash on Delivery', Icons.payments_outlined),
    ('khqr', 'KHQR / ABA Pay', Icons.qr_code_2),
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController.text = user?.name ?? '';
    _phoneController.text = user?.phone ?? '';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: items.isEmpty
          ? const Center(child: Text('Your cart is empty'))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
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
                          hintText: 'Tap to choose your delivery location on the map',
                          icon: Icons.location_on_outlined,
                          readOnly: true,
                          onTap: _openMapPicker,
                          suffixIcon: const Icon(Icons.map_outlined),
                          validator: (value) {
                            if (_deliveryLocation == null ||
                                _deliveryLocation!.address.isEmpty) {
                              return 'Please select your delivery location on the map';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              _deliveryLocation == null
                                  ? Icons.info_outline
                                  : Icons.check_circle,
                              size: 14,
                              color: _deliveryLocation == null
                                  ? AppColors.textSecondary
                                  : AppColors.success,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _deliveryLocation == null
                                    ? 'Tap the field to choose your location on the map.'
                                    : 'Location selected. Tap to change.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
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
                  _SectionCard(
                    title: 'Payment Method',
                    icon: Icons.credit_card_outlined,
                    child: RadioGroup<String>(
                      groupValue: _paymentMethod,
                      onChanged: (value) {
                        setState(() => _paymentMethod = value ?? 'cod');
                      },
                      child: Column(
                        children: _paymentMethods.map((method) {
                          final key = method.$1;
                          return RadioListTile<String>(
                            value: key,
                            title: Text(method.$2),
                            secondary:
                                Icon(method.$3, color: AppColors.primary),
                            activeColor: AppColors.primary,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
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
                        _Row(label: 'Subtotal', value: '\$${subtotal.toStringAsFixed(2)}'),
                        const SizedBox(height: 4),
                        _Row(label: 'Delivery fee', value: '\$${deliveryFee.toStringAsFixed(2)}'),
                        const SizedBox(height: 4),
                        _Row(
                          label: 'Total',
                          value: '\$${(subtotal + deliveryFee).toStringAsFixed(2)}',
                          emphasized: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: orderProvider.isPlacingOrder
                        ? null
                        : () => _placeOrder(orderProvider),
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

  Future<void> _openMapPicker() async {
    final result = await Navigator.of(context).push<DeliveryLocation>(
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          initialLocation: _deliveryLocation,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _deliveryLocation = result;
        _addressController.text = result.address;
      });
    }
  }

  Future<void> _placeOrder(OrderProvider orderProvider) async {
    if (!_formKey.currentState!.validate()) return;

    final location = _deliveryLocation;

    final order = await orderProvider.placeOrder(
      shippingAddress: location?.address.isNotEmpty == true
          ? location!.address
          : _addressController.text.trim(),
      shippingPhone: _phoneController.text.trim(),
      paymentMethod: _paymentMethod,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (!mounted) return;

    if (order != null && order.id != null) {
      await context.read<CartProvider>().clearCart();
      if (!mounted) return;
      _showSuccessAndNavigate(order);
    } else {
      Helpers.showSnackBar(
        context,
        orderProvider.errorMessage ?? 'Could not place your order. Please try again.',
        isError: true,
      );
    }
  }

  void _showSuccessAndNavigate(OrderModel order) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.success, size: 56),
        title: const Text('Order Placed!'),
        content: const Text(
          'Thank you for your order. You can track its status in My Orders.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              final orderId = order.id;
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.orderDetail,
                (route) => false,
                arguments: orderId,
              );
            },
            style: FilledButton.styleFrom(minimumSize: const Size(150, 46)),
            child: const Text('View Order'),
          ),
        ],
      ),
    );
  }
}

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