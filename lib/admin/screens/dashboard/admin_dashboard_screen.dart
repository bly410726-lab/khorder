import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/order_model.dart';
import '../../../providers/admin/admin_dashboard_provider.dart';
import '../../widgets/admin_drawer.dart';
import '../../widgets/dashboard_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminDashboardProvider>().fetchDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<AdminDashboardProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      drawer: const AdminDrawer(),
      body: _buildBody(dashboardProvider),
    );
  }

  Widget _buildBody(AdminDashboardProvider provider) {
    if (provider.isLoading) {
      return const LoadingWidget();
    }
    if (provider.errorMessage != null) {
      return AppErrorWidget(
        message: provider.errorMessage!,
        onRetry: () => provider.fetchDashboardData(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchDashboardData(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.35,
            children: [
              DashboardCard(
                title: 'Revenue',
                value: '\$${provider.totalRevenue.toStringAsFixed(2)}',
                icon: Icons.payments_outlined,
                color: AppColors.success,
              ),
              DashboardCard(
                title: 'Orders',
                value: '${provider.totalOrders}',
                icon: Icons.receipt_long_outlined,
                color: AppColors.primary,
              ),
              DashboardCard(
                title: 'Products',
                value: '${provider.totalProducts}',
                icon: Icons.inventory_2_outlined,
                color: AppColors.accent,
              ),
              DashboardCard(
                title: 'Customers',
                value: '${provider.totalCustomers}',
                icon: Icons.people_outlined,
                color: const Color(0xFF7B61FF),
              ),
              DashboardCard(
                title: 'Pending Orders',
                value: '${provider.pendingOrders}',
                icon: Icons.hourglass_top,
                color: AppColors.warning,
              ),
              DashboardCard(
                title: 'Completed Orders',
                value: '${provider.completedOrders}',
                icon: Icons.check_circle_outline,
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Recent Orders',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Battambang',
            ),
          ),
          const SizedBox(height: 10),
          if (provider.recentOrders.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No recent orders',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ...provider.recentOrders.take(5).map(
                  (order) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _RecentOrderTile(order: order),
                  ),
                ),
        ],
      ),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  const _RecentOrderTile({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.receipt_long, color: AppColors.primary),
        title: Text(
          order.orderNumber ?? 'Order #${order.id}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${order.user?.name ?? 'Customer'} • ${Helpers.formatDateTime(order.createdAt)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${(order.total ?? 0).toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 2),
            StatusBadge(status: order.status),
          ],
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.adminOrderDetail,
            arguments: order.id,
          );
        },
      ),
    );
  }
}