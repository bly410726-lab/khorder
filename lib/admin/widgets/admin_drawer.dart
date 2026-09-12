import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../providers/auth_provider.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final adminName = authProvider.user?.name ?? 'Administrator';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  adminName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'KhOrder Admin Panel',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          _DrawerItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            route: AppRoutes.adminDashboard,
          ),
          _DrawerItem(
            icon: Icons.inventory_2_outlined,
            label: 'Products',
            route: AppRoutes.adminProducts,
          ),
          _DrawerItem(
            icon: Icons.category_outlined,
            label: 'Categories',
            route: AppRoutes.adminCategories,
          ),
          _DrawerItem(
            icon: Icons.view_carousel_outlined,
            label: 'Banners',
            route: AppRoutes.adminBanners,
          ),
          _DrawerItem(
            icon: Icons.receipt_long_outlined,
            label: 'Orders',
            route: AppRoutes.adminOrders,
          ),
          _DrawerItem(
            icon: Icons.people_outline,
            label: 'Users',
            route: AppRoutes.adminUsers,
          ),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: () async {
              await authProvider.logout();
              if (!context.mounted) return;
              Helpers.showSnackBar(context, 'Logged out');
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    final isCurrent = ModalRoute.of(context)?.settings.name == route;
    return ListTile(
      leading: Icon(icon, color: isCurrent ? AppColors.primary : null),
      title: Text(
        label,
        style: TextStyle(
          color: isCurrent ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: isCurrent,
      onTap: () {
        Navigator.pushReplacementNamed(context, route);
      },
    );
  }
}