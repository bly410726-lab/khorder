import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class ApiConstants {
  ApiConstants._();

  static String get baseUrl {
    return "https://replacing-seek-predict-fence.trycloudflare.com/api";
    // if (kIsWeb) { https://few-celebs-height-instant.trycloudflare.com
    //   return 'http://127.0.0.1:8000/api';
    // }
    // if (defaultTargetPlatform == TargetPlatform.android) {
    //   return 'http://10.0.2.2:8000/api';
    // }
    // return 'http://127.0.0.1:8000/api';
  }
  //
  static const String login = '/login';
  static const String register = '/register';
  static const String logout = '/logout';
  static const String user = '/me';
  static const String profile = '/profile';

  //
  static const String products = '/products';
  static const String categories = '/categories';
  static const String cart = '/cart';
  static const String cartItems = '/cart/items';
  static const String favorites = '/favorites';
  static const String orders = '/orders';
  static const String aiChat = '/ai/chat';
  //
  static const String banners = '/banners';

  //
  static const String adminDashboard = '/admin/dashboard';
  static const String adminProducts = '/admin/products';
  static const String adminCategories = '/admin/categories';
  static const String adminOrders = '/admin/orders';
  static const String adminUsers = '/admin/users';
  static const String adminBanners = '/admin/banners';
}