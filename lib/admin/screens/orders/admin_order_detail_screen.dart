import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/order_model.dart';
import '../../../providers/admin/admin_order_provider.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  const AdminOrderDetailScreen({super.key});

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  int? _orderId;

  static const _statuses = [
    ('pending', 'Pending'),
    ('confirmed', 'Confirmed'),
    ('processing', 'Processing'),
    ('completed', 'Completed'),
    ('cancelled', 'Cancelled'),
  ];

  @override
  void initState() {
    super.initState();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int) {
      _orderId = args;
    } else if (args is OrderModel) {
      _orderId = args.id;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_orderId != null) {
        context.read<AdminOrderProvider>().fetchOrderById(_orderId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminOrderProvider>();
    final order = provider.selectedOrder;

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: _buildContent(provider, order),
    );
  }

  Widget _buildContent(AdminOrderProvider provider, OrderModel? order) {
    if (provider.isLoading && order == null) {
      return const LoadingWidget();
    }
    if (order == null) {
      return AppErrorWidget(
        message: provider.errorMessage ?? 'Order details could not be loaded.',
        onRetry: () {
          if (_orderId != null) {
            provider.fetchOrderById(_orderId!);
          }
        },
      );
    }

    final items = order.items ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderNumber ?? 'Order #${order.id}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Helpers.formatDateTime(order.createdAt),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            StatusBadge(status: order.status),
          ],
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Update Status',
          icon: Icons.update,
          children: [
            DropdownButtonFormField<String>(
              key: ValueKey('status-${order.status}'),
              initialValue: _currentStatus(order.status),
              decoration: InputDecoration(
                labelText: 'Order Status',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
              ),
              items: _statuses
                  .map((s) => DropdownMenuItem(value: s.$1, child: Text(s.$2)))
                  .toList(),
              onChanged: provider.isUpdating
                  ? null
                  : (value) {
                      if (value != null && value != order.status) {
                        _updateStatus(provider, order, value);
                      }
                    },
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Customer',
          icon: Icons.person_outline,
          children: [
            _InfoRow(label: 'Name', value: order.user?.name ?? ''),
            _InfoRow(
              label: 'Email',
              value: order.user?.email ?? '',
            ),
            _InfoRow(label: 'Phone', value: order.shippingPhone ?? ''),
            _InfoRow(label: 'Address', value: order.shippingAddress ?? ''),
            if (order.notes?.isNotEmpty == true)
              _InfoRow(label: 'Notes', value: order.notes!),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Items',
          icon: Icons.receipt_long_outlined,
          children: [
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: AppNetworkImage(
                          url: item.product?.image,
                          icon: Icons.fastfood_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName ?? item.product?.name ?? 'Product',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '\$${(item.price ?? 0).toStringAsFixed(2)} × ${item.quantity}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${item.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 8),
            _InfoRow(label: 'Subtotal', value: '\$${(order.subtotal ?? 0).toStringAsFixed(2)}'),
            _InfoRow(
              label: 'Delivery Fee',
              value: '\$${(order.deliveryFee ?? 0).toStringAsFixed(2)}',
            ),
            _InfoRow(
              label: 'Total',
              value: '\$${(order.total ?? 0).toStringAsFixed(2)}',
              emphasized: true,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Payment',
          icon: Icons.credit_card_outlined,
          children: [
            _InfoRow(label: 'Method', value: _paymentLabel(order.paymentMethod)),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  String? _currentStatus(String? status) {
    for (final s in _statuses) {
      if (s.$1 == status) return status;
    }
    return _statuses.first.$1;
  }

  String _paymentLabel(String? method) {
    switch (method?.toLowerCase()) {
      case 'cod':
        return 'Cash on Delivery';
      case 'khqr':
        return 'KHQR / ABA Pay';
      default:
        return method?.toUpperCase() ?? '--';
    }
  }

  Future<void> _updateStatus(
    AdminOrderProvider provider,
    OrderModel order,
    String newStatus,
  ) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Update Status',
      message:
          'Are you sure you want to change this order status to "${_statusLabel(newStatus)}"?',
      confirmLabel: 'Update',
    );
    if (!confirmed || !context.mounted) return;

    final success = await provider.updateOrderStatus(order.id ?? -1, newStatus);
    if (!mounted) return;
    Helpers.showSnackBar(
      context,
      success ? 'Order status updated' : (provider.errorMessage ?? 'Update failed'),
      isError: !success,
    );
  }

  String _statusLabel(String status) {
    for (final s in _statuses) {
      if (s.$1 == status) return s.$2;
    }
    return status;
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: emphasized ? 15 : 13,
                color: AppColors.textSecondary,
                fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: emphasized ? 15 : 13,
                fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
                color: emphasized ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}