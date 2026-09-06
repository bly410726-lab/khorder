import 'package:flutter/foundation.dart';

import '../../core/network/api_service.dart';
import '../../models/order_model.dart';
import '../../services/admin_dashboard_service.dart';

class AdminDashboardProvider extends ChangeNotifier {
  final AdminDashboardService _dashboardService = AdminDashboardService();

  bool _isLoading = false;
  String? _errorMessage;

  int _totalRevenue = 0;
  int _totalOrders = 0;
  int _totalProducts = 0;
  int _totalCustomers = 0;
  int _pendingOrders = 0;
  int _completedOrders = 0;

  List<OrderModel> _recentOrders = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalRevenue => _totalRevenue;
  int get totalOrders => _totalOrders;
  int get totalProducts => _totalProducts;
  int get totalCustomers => _totalCustomers;
  int get pendingOrders => _pendingOrders;
  int get completedOrders => _completedOrders;

  List<OrderModel> get recentOrders => _recentOrders;

  Future<void> fetchDashboardData() async {
    _setLoading(true);
    try {
      final data = await _dashboardService.fetchDashboardData();
      _totalRevenue = data.totalRevenue.round();
      _totalOrders = data.totalOrders;
      _totalProducts = data.totalProducts;
      _totalCustomers = data.totalCustomers;
      _pendingOrders = data.pendingOrders;
      _completedOrders = data.completedOrders;
      _recentOrders = data.recentOrders;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = _friendlyError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _errorMessage = null;
    notifyListeners();
  }

  String _friendlyError(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return 'Could not connect to the server. Please try again.';
  }
}