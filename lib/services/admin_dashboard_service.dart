import '../app/constants/api_constants.dart';
import '../core/network/api_service.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';

class AdminDashboardData {
  const AdminDashboardData({
    this.totalProducts = 0,
    this.totalOrders = 0,
    this.totalCustomers = 0,
    this.totalRevenue = 0,
    this.pendingOrders = 0,
    this.completedOrders = 0,
    this.recentOrders = const [],
    this.recentUsers = const [],
  });

  final int totalProducts;
  final int totalOrders;
  final int totalCustomers;
  final double totalRevenue;
  final int pendingOrders;
  final int completedOrders;
  final List<OrderModel> recentOrders;
  final List<UserModel> recentUsers;
}

class AdminDashboardService {
  int _toInt(dynamic value) {
    return value is num ? value.toInt() : (int.tryParse(value?.toString() ?? '') ?? 0);
  }

  double _toDouble(dynamic value) {
    return value is num ? value.toDouble() : (double.tryParse(value?.toString() ?? '') ?? 0);
  }

  List<OrderModel> _parseOrders(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .map(OrderModel.fromJson)
          .toList();
    }
    if (value is Map<String, dynamic>) {
      final data = value['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(OrderModel.fromJson)
            .toList();
      }
    }
    return [];
  }

  List<UserModel> _parseUsers(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .map(UserModel.fromJson)
          .toList();
    }
    if (value is Map<String, dynamic>) {
      final data = value['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(UserModel.fromJson)
            .toList();
      }
    }
    return [];
  }

  Future<AdminDashboardData> fetchDashboardData() async {
    final response = await ApiService.instance.get(ApiConstants.adminDashboard);
    final Map<String, dynamic> data;
    if (response is Map<String, dynamic>) {
      data = response;
    } else {
      data = const {};
    }

    return AdminDashboardData(
      totalProducts: _toInt(data['total_products']),
      totalOrders: _toInt(data['total_orders']),
      totalCustomers: _toInt(data['total_customers']),
      totalRevenue: _toDouble(data['total_revenue']),
      pendingOrders: _toInt(data['pending_orders']),
      completedOrders: _toInt(data['completed_orders']),
      recentOrders: _parseOrders(data['recent_orders']),
      recentUsers: _parseUsers(data['recent_users']),
    );
  }
}
