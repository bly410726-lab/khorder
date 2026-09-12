import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'providers/admin/admin_banner_provider.dart';
import 'providers/admin/admin_category_provider.dart';
import 'providers/admin/admin_dashboard_provider.dart';
import 'providers/admin/admin_order_provider.dart';
import 'providers/admin/admin_product_provider.dart';
import 'providers/admin/admin_user_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/customer/ai_chat_provider.dart';
import 'providers/customer/banner_provider.dart';
import 'providers/customer/cart_provider.dart';
import 'providers/customer/category_provider.dart';
import 'providers/customer/favorite_provider.dart';
import 'providers/customer/order_provider.dart';
import 'providers/customer/product_provider.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
WidgetsFlutterBinding.ensureInitialized();

runApp(
MultiProvider(
providers: [
ChangeNotifierProvider(create: (_) => AuthProvider()),
ChangeNotifierProvider(create: (_) => ThemeProvider()),

ChangeNotifierProvider(create: (_) => CategoryProvider()),
ChangeNotifierProvider(create: (_) => ProductProvider()),
ChangeNotifierProvider(create: (_) => CartProvider()),
ChangeNotifierProvider(create: (_) => FavoriteProvider()),
ChangeNotifierProvider(create: (_) => OrderProvider()),
ChangeNotifierProvider(create: (_) => AIChatProvider()),
ChangeNotifierProvider(create: (_) => BannerProvider()),

ChangeNotifierProvider(create: (_) => AdminProductProvider()),
ChangeNotifierProvider(create: (_) => AdminCategoryProvider()),
ChangeNotifierProvider(create: (_) => AdminOrderProvider()),
ChangeNotifierProvider(create: (_) => AdminDashboardProvider()),
ChangeNotifierProvider(create: (_) => AdminUserProvider()),
ChangeNotifierProvider(create: (_) => AdminBannerProvider()),
],
child: const KhOrderApp(),
),
);
}
