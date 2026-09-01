import 'package:flutter/foundation.dart';

import '../../core/network/api_service.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _orderService = OrderService();

  List<OrderModel> _orders = [];
  OrderModel? _selectedOrder;
  bool _isLoading = false;
  bool _isPlacingOrder = false;
  String? _errorMessage;

  List<OrderModel> get orders => _orders;
  OrderModel? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  bool get isPlacingOrder => _isPlacingOrder;
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

  Future<OrderModel?> placeOrder({
    required String shippingAddress,
    required String shippingPhone,
    required String paymentMethod,
    String? notes,
  }) async {
    _isPlacingOrder = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final order = await _orderService.placeOrder(
        shippingAddress: shippingAddress,
        shippingPhone: shippingPhone,
        paymentMethod: paymentMethod,
        notes: notes,
      );
      if (order != null) {
        await fetchOrders();
      }
      return order;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      return null;
    } finally {
      _isPlacingOrder = false;
      notifyListeners();
    }
  }

  Future<bool> cancelOrder(int orderId) async {
    try {
      await _orderService.cancelOrder(orderId);
      await fetchOrders();
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      notifyListeners();
      return false;
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