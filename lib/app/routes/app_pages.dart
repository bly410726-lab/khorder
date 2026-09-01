import 'package:flutter/material.dart';

import '../../core/navigation/route_guard.dart';

import '../../customer/screens/auth/login_screen.dart';
import '../../customer/screens/auth/register_screen.dart';
import '../../customer/screens/main_shell.dart';
import '../../customer/screens/product/product_detail_screen.dart';
import '../../customer/screens/product/search_screen.dart';
import '../../customer/screens/category/category_screen.dart';
import '../../customer/screens/cart/cart_screen.dart';
import '../../customer/screens/favorite/favorite_screen.dart';
import '../../customer/screens/checkout/checkout_screen.dart';
import '../../customer/screens/orders/orders_screen.dart';
import '../../customer/screens/orders/order_detail_screen.dart';
import '../../customer/screens/profile/profile_screen.dart';
import '../../customer/screens/profile/edit_profile_screen.dart';

import '../../admin/screens/auth/admin_login_screen.dart';
import '../../admin/screens/dashboard/admin_dashboard_screen.dart';
import '../../admin/screens/products/admin_products_screen.dart';
import '../../admin/screens/products/add_product_screen.dart';
import '../../admin/screens/products/edit_product_screen.dart';
import '../../admin/screens/categories/admin_categories_screen.dart';
import '../../admin/screens/categories/add_category_screen.dart';
import '../../admin/screens/categories/edit_category_screen.dart';
import '../../admin/screens/orders/admin_orders_screen.dart';
import '../../admin/screens/orders/admin_order_detail_screen.dart';
import '../../admin/screens/users/admin_users_screen.dart';

import 'app_routes.dart';

class AppPages {
  AppPages._();

  static const String initialRoute = AppRoutes.login;

  static Map<String, WidgetBuilder> get routes {
    return {
      AppRoutes.login: (context) => const LoginScreen(),
      AppRoutes.register: (context) => const RegisterScreen(),

      AppRoutes.home: (context) => const RouteGuard(child: MainShell()),
      AppRoutes.productDetail: (context) =>
          const RouteGuard(child: ProductDetailScreen()),
      AppRoutes.search: (context) => const RouteGuard(child: SearchScreen()),
      AppRoutes.category: (context) => const RouteGuard(child: CategoryScreen()),
      AppRoutes.cart: (context) => const RouteGuard(child: CartScreen()),
      AppRoutes.favorite: (context) => const RouteGuard(child: FavoriteScreen()),
      AppRoutes.checkout: (context) => const RouteGuard(child: CheckoutScreen()),
      AppRoutes.orders: (context) => const RouteGuard(child: OrdersScreen()),
      AppRoutes.orderDetail: (context) =>
          const RouteGuard(child: OrderDetailScreen()),
      AppRoutes.profile: (context) => const RouteGuard(child: ProfileScreen()),
      AppRoutes.editProfile: (context) =>
          const RouteGuard(child: EditProfileScreen()),

      AppRoutes.adminLogin: (context) => const AdminLoginScreen(),
      AppRoutes.adminDashboard: (context) =>
          const RouteGuard(requiresAdmin: true, child: AdminDashboardScreen()),
      AppRoutes.adminProducts: (context) =>
          const RouteGuard(requiresAdmin: true, child: AdminProductsScreen()),
      AppRoutes.adminAddProduct: (context) =>
          const RouteGuard(requiresAdmin: true, child: AddProductScreen()),
      AppRoutes.adminEditProduct: (context) =>
          const RouteGuard(requiresAdmin: true, child: EditProductScreen()),
      AppRoutes.adminCategories: (context) =>
          const RouteGuard(requiresAdmin: true, child: AdminCategoriesScreen()),
      AppRoutes.adminAddCategory: (context) =>
          const RouteGuard(requiresAdmin: true, child: AddCategoryScreen()),
      AppRoutes.adminEditCategory: (context) =>
          const RouteGuard(requiresAdmin: true, child: EditCategoryScreen()),
      AppRoutes.adminOrders: (context) =>
          const RouteGuard(requiresAdmin: true, child: AdminOrdersScreen()),
      AppRoutes.adminOrderDetail: (context) =>
          const RouteGuard(requiresAdmin: true, child: AdminOrderDetailScreen()),
      AppRoutes.adminUsers: (context) =>
          const RouteGuard(requiresAdmin: true, child: AdminUsersScreen()),
    };
  }
}