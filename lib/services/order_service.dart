import '../app/constants/api_constants.dart';
import '../core/network/api_service.dart';
import '../models/order_model.dart';

class OrderService {
  List<OrderModel> _parseList(dynamic response) {
    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(OrderModel.fromJson)
          .toList();
    }
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(OrderModel.fromJson)
            .toList();
      }
      final items = response['items'];
      if (items is List) {
        return items
            .whereType<Map<String, dynamic>>()
            .map(OrderModel.fromJson)
            .toList();
      }
      final orders = response['orders'];
      if (orders is List) {
        return orders
            .whereType<Map<String, dynamic>>()
            .map(OrderModel.fromJson)
            .toList();
      }
    }
    return [];
  }

  Future<List<OrderModel>> fetchOrders() async {
    final response = await ApiService.instance.get(ApiConstants.orders);
    return _parseList(response);
  }

  Future<OrderModel?> fetchOrderById(int orderId) async {
    final response = await ApiService.instance.get('${ApiConstants.orders}/$orderId');
    if (response is Map<String, dynamic>) {
      final data = response['order'] is Map<String, dynamic>
          ? response['order'] as Map<String, dynamic>
          : response;
      return OrderModel.fromJson(data);
    }
    return null;
  }

  Future<OrderModel?> placeOrder({
    required String shippingAddress,
    required String shippingPhone,
    required String paymentMethod,
    String? notes,
  }) async {
    final response = await ApiService.instance.post(
      ApiConstants.orders,
      body: {
        'shipping_address': shippingAddress,
        'shipping_phone': shippingPhone,
        'payment_method': paymentMethod,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    if (response is Map<String, dynamic>) {
      final data = response['order'] is Map<String, dynamic>
          ? response['order'] as Map<String, dynamic>
          : response;
      if (data['id'] == null && response['success'] == false) {
        throw ApiException(response['message']?.toString() ?? 'Order could not be placed.');
      }
      return OrderModel.fromJson(data);
    }
    return null;
  }

  Future<void> cancelOrder(int orderId) async {
    await ApiService.instance.put(
      '${ApiConstants.orders}/$orderId',
      body: {'status': 'cancelled'},
    );
  }
}
