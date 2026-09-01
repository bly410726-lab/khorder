import '../app/constants/api_constants.dart';
import '../core/network/api_service.dart';
import '../models/cart_item_model.dart';

class CartService {
  List<CartItemModel> _parseList(dynamic response) {
    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(CartItemModel.fromJson)
          .toList();
    }
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(CartItemModel.fromJson)
            .toList();
      }
      final items = response['items'];
      if (items is List) {
        return items
            .whereType<Map<String, dynamic>>()
            .map(CartItemModel.fromJson)
            .toList();
      }
      final cart = response['cart'];
      if (cart is Map<String, dynamic>) {
        final cartItems = cart['items'];
        if (cartItems is List) {
          return cartItems
              .whereType<Map<String, dynamic>>()
              .map(CartItemModel.fromJson)
              .toList();
        }
      }
    }
    return [];
  }

  Future<List<CartItemModel>> fetchCart() async {
    final response = await ApiService.instance.get(ApiConstants.cart);
    return _parseList(response);
  }

  Future<void> addItem(int productId, {int quantity = 1}) async {
    await ApiService.instance.post(
      ApiConstants.cartItems,
      body: {
        'product_id': productId,
        'quantity': quantity,
      },
    );
  }

  Future<void> removeItem(int productId) async {
    await ApiService.instance.delete(
      '${ApiConstants.cartItems}/$productId',
    );
  }

  Future<void> updateQuantity(int productId, int quantity) async {
    await ApiService.instance.put(
      '${ApiConstants.cartItems}/$productId',
      body: {'quantity': quantity},
    );
  }

  Future<void> clearCart() async {
    await ApiService.instance.delete(ApiConstants.cart);
  }
}
