import '../app/constants/api_constants.dart';
import '../core/network/api_service.dart';
import '../models/order_model.dart';

class AdminOrderService {
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
    final response = await ApiService.instance.get(ApiConstants.adminOrders);
    return _parseList(response);
  }

  Future<OrderModel?> fetchOrderById(int orderId) async {
    final response = await ApiService.instance
        .get('${ApiConstants.adminOrders}/$orderId');
    if (response is Map<String, dynamic>) {
      final data = response['order'] is Map<String, dynamic>
          ? response['order'] as Map<String, dynamic>
          : response;
      return OrderModel.fromJson(data);
    }
    return null;
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    await ApiService.instance.put(
      '${ApiConstants.adminOrders}/$orderId',
      body: {'status': status},
    );
  }
}
