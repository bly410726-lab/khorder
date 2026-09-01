import 'package:flutter/foundation.dart';

import '../../core/network/api_service.dart';
import '../../models/cart_item_model.dart';
import '../../models/product_model.dart';
import '../../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  final CartService _cartService = CartService();

  List<CartItemModel> _items = [];
  bool _isLoading = false;
  bool _isAdding = false;
  String? _errorMessage;

  List<CartItemModel> get items => _items;
  bool get isLoading => _isLoading;
  bool get isAdding => _isAdding;
  String? get errorMessage => _errorMessage;

  int get itemCount {
    return _items.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  double get subtotal {
    return _items.fold<double>(
      0,
      (sum, item) => sum + item.totalPrice,
    );
  }

  int? quantityOf(int? productId) {
    final index = _items.indexWhere((item) => item.product?.id == productId);
    if (index == -1) return null;
    return _items[index].quantity;
  }

  Future<void> fetchCart() async {
    _setLoading(true);
    try {
      _items = await _cartService.fetchCart();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = _friendlyError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addItem(ProductModel product, {int quantity = 1}) async {
    if (product.id == null) return false;
    _isAdding = true;
    notifyListeners();

    try {
      await _cartService.addItem(product.id!, quantity: quantity);
      await fetchCart();
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      return false;
    } finally {
      _isAdding = false;
      notifyListeners();
    }
  }

  Future<bool> removeItem(int productId) async {
    final previous = List<CartItemModel>.from(_items);
    _items.removeWhere((item) => item.product?.id == productId);
    notifyListeners();

    try {
      await _cartService.removeItem(productId);
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      _items = previous;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateQuantity(int productId, int quantity) async {
    if (quantity < 1) return false;
    final previous = List<CartItemModel>.from(_items);
    final index = _items.indexWhere((item) => item.product?.id == productId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(quantity: quantity);
    }
    notifyListeners();

    try {
      await _cartService.updateQuantity(productId, quantity);
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      _items = previous;
      notifyListeners();
      return false;
    }
  }

  Future<void> clearCart() async {
    _items = [];
    notifyListeners();
    try {
      await _cartService.clearCart();
    } catch (_) {
      // Local cart cleared; take no further action.
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