import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../providers/admin/admin_order_provider.dart';
import '../../widgets/admin_drawer.dart';
import '../../widgets/admin_order_card.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final List<String?> _filters = [
    null,
    'pending',
    'confirmed',
    'processing',
    'completed',
    'cancelled',
  ];
  String? _selectedFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminOrderProvider>().fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminOrderProvider>();

    final orders = _selectedFilter == null
        ? provider.orders
        : provider.orders
            .where((o) =>
                (o.status ?? '').toLowerCase() == _selectedFilter!.toLowerCase())
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          const SizedBox(height: 4),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _selectedFilter == null,
                  onTap: () => setState(() => _selectedFilter = null),
                ),
                ..._filters.skip(1).map(
                      (status) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _FilterChip(
                          label: _capitalize(status!),
                          selected: _selectedFilter == status,
                          onTap: () => setState(() => _selectedFilter = status),
                        ),
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildContent(provider, orders)),
        ],
      ),
    );
  }

  Widget _buildContent(AdminOrderProvider provider, List orders) {
    if (provider.isLoading && provider.orders.isEmpty) {
      return const LoadingWidget();
    }
    if (provider.errorMessage != null && provider.orders.isEmpty) {
      return AppErrorWidget(
        message: provider.errorMessage!,
        onRetry: () => provider.fetchOrders(),
      );
    }
    if (orders.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: provider.orders.isEmpty ? 'No orders yet' : 'No orders here',
        message: provider.orders.isEmpty
            ? 'Orders placed by customers will appear here.'
            : 'Try a different status filter.',
      );
    }
    return RefreshIndicator(
      onRefresh: () => provider.fetchOrders(),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final order = orders[index];
          return AdminOrderCard(
            order: order,
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.adminOrderDetail,
                arguments: order.id,
              );
            },
          );
        },
      ),
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}