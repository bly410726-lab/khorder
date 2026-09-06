import 'package:flutter/foundation.dart';

import '../../core/network/api_service.dart';
import '../../models/product_model.dart';
import '../../services/admin_product_service.dart';

class AdminProductProvider extends ChangeNotifier {
  final AdminProductService _productService = AdminProductService();

  List<ProductModel> _products = [];
  ProductModel? _selectedProduct;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  List<ProductModel> get products => _products;
  ProductModel? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  Future<void> fetchProducts() async {
    _setLoading(true);
    try {
      _products = await _productService.fetchProducts();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = _friendlyError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addProduct(Map<String, dynamic> data) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _productService.addProduct(data);
      await fetchProducts();
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateProduct(int id, Map<String, dynamic> data) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _productService.updateProduct(id, data);
      await fetchProducts();
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      await _productService.deleteProduct(id);
      await fetchProducts();
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