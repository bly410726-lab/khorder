import 'package:flutter/foundation.dart';

import '../../core/network/api_service.dart';
import '../../models/order_model.dart';
import '../../services/admin_order_service.dart';

class AdminOrderProvider extends ChangeNotifier {
  final AdminOrderService _orderService = AdminOrderService();

  List<OrderModel> _orders = [];
  OrderModel? _selectedOrder;
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _errorMessage;

  List<OrderModel> get orders => _orders;
  OrderModel? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;

  Future<void> fetchOrders() async {
    _setLoading(true);
    try {
      _orders = await _orderService.fetchOrders();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = _friendlyError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> fetchOrderById(int orderId) async {
    try {
      _selectedOrder = await _orderService.fetchOrderById(orderId);
      notifyListeners();
      return _selectedOrder != null;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateOrderStatus(int orderId, String status) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _orderService.updateOrderStatus(orderId, status);
      _selectedOrder = _selectedOrder?.copyWith(status: status);
      await fetchOrders();
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      return false;
    } finally {
      _isUpdating = false;
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