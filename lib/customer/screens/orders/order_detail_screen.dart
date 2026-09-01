import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/order_model.dart';
import '../../../providers/customer/order_provider.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  int? _orderId;
  bool _cancelling = false;

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
        context.read<OrderProvider>().fetchOrderById(_orderId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final order = orderProvider.selectedOrder;

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: _buildContent(orderProvider, order),
    );
  }

  Widget _buildContent(OrderProvider orderProvider, OrderModel? order) {
    if (orderProvider.isLoading && order == null) {
      return const LoadingWidget();
    }
    if (order == null) {
      return AppErrorWidget(
        message:
            orderProvider.errorMessage ?? 'Order details could not be loaded.',
        onRetry: () {
          if (_orderId != null) {
            orderProvider.fetchOrderById(_orderId!);
          }
        },
      );
    }

    final items = order.items ?? [];
    final canCancel = order.status?.toLowerCase() == 'pending';

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
        const SizedBox(height: 8),
        _OrderTimeline(status: order.status),
        const SizedBox(height: 16),
        _InfoCard(
          title: 'Delivery Information',
          icon: Icons.local_shipping_outlined,
          children: [
            _InfoRow(label: 'Customer', value: order.user?.name ?? ''),
            _InfoRow(
              label: 'Phone',
              value: order.shippingPhone ?? order.user?.phone ?? '',
            ),
            _InfoRow(label: 'Address', value: order.shippingAddress ?? ''),
            if (order.notes?.isNotEmpty == true)
              _InfoRow(label: 'Notes', value: order.notes!),
          ],
        ),
        const SizedBox(height: 12),
        _InfoCard(
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
            _InfoRow(label: 'Delivery Fee', value: '\$${(order.deliveryFee ?? 0).toStringAsFixed(2)}'),
            _InfoRow(
              label: 'Total',
              value: '\$${(order.total ?? 0).toStringAsFixed(2)}',
              emphasized: true,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: 'Payment',
          icon: Icons.credit_card_outlined,
          children: [
            _InfoRow(label: 'Method', value: _paymentLabel(order.paymentMethod)),
          ],
        ),
        if (canCancel) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _cancelling ? null : () => _cancelOrder(orderProvider, order),
            icon: _cancelling
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cancel_outlined),
            label: const Text('Cancel Order'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
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

  Future<void> _cancelOrder(OrderProvider orderProvider, OrderModel order) async {
    setState(() => _cancelling = true);
    final success = await orderProvider.cancelOrder(order.id ?? -1);
    setState(() => _cancelling = false);
    if (!mounted) return;
    if (success) {
      Helpers.showSnackBar(context, 'Order cancelled');
    } else {
      Helpers.showSnackBar(
        context,
        orderProvider.errorMessage ?? 'Could not cancel the order.',
        isError: true,
      );
    }
  }
}

class _OrderTimeline extends StatelessWidget {
  const _OrderTimeline({required this.status});

  final String? status;

  static const _steps = [
    ('Ordered', Icons.receipt_long),
    ('Confirmed', Icons.check_circle_outline),
    ('Processing', Icons.local_shipping_outlined),
    ('Delivered', Icons.flag_outlined),
  ];

  int get _activeIndex {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 0;
      case 'confirmed':
        return 1;
      case 'processing':
        return 2;
      case 'completed':
      case 'delivered':
        return 3;
      default:
        return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _activeIndex;
    if (status?.toLowerCase() == 'cancelled' || status?.toLowerCase() == 'canceled') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel, color: AppColors.error),
            SizedBox(width: 10),
            Text(
              'Order cancelled',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }
    if (activeIndex == -1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _steps.length; i++)
            Expanded(
              child: _TimelineStep(
                label: _steps[i].$1,
                icon: _steps[i].$2,
                active: i <= activeIndex,
                last: i == _steps.length - 1,
                isCurrent: i == activeIndex,
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.label,
    required this.icon,
    required this.active,
    required this.last,
    required this.isCurrent,
  });

  final String label;
  final IconData icon;
  final bool active;
  final bool last;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.divider;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 2,
                color: color,
                margin: EdgeInsets.only(left: isCurrent ? 0 : 2),
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? AppColors.primary : AppColors.surface,
                border: Border.all(color: color),
              ),
              child: Icon(
                icon,
                size: 14,
                color: active ? Colors.white : AppColors.textSecondary,
              ),
            ),
            if (!last)
              Expanded(
                child: Container(
                  height: 2,
                  color: color,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: active ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
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