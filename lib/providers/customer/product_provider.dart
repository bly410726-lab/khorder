import 'package:flutter/foundation.dart';

import '../../core/network/api_service.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();

  List<ProductModel> _products = [];
  List<ProductModel> _featuredProducts = [];
  ProductModel? _selectedProduct;
  bool _isLoading = false;
  String? _errorMessage;

  String _searchQuery = '';
  int? _selectedCategoryId;

  List<ProductModel> get products => _products;
  List<ProductModel> get featuredProducts => _featuredProducts;
  ProductModel? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int? get selectedCategoryId => _selectedCategoryId;

  List<ProductModel> get filteredProducts {
    final query = _searchQuery.trim().toLowerCase();
    return _products.where((product) {
      final matchesSearch = query.isEmpty ||
          (product.name?.toLowerCase().contains(query) ?? false) ||
          (product.description?.toLowerCase().contains(query) ?? false);
      final matchesCategory =
          _selectedCategoryId == null ||
              product.categoryId == _selectedCategoryId;
      return matchesSearch && matchesCategory;
    }).toList();
  }

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

  Future<void> fetchFeaturedProducts() async {
    try {
      _featuredProducts = await _productService.fetchFeaturedProducts();
      notifyListeners();
    } catch (_) {
      // Featured products are optional; home falls back to all products.
    }
  }

  Future<ProductModel?> fetchProductById(int id) async {
    try {
      _selectedProduct = await _productService.fetchProductById(id);
      notifyListeners();
      return _selectedProduct;
    } catch (_) {
      return null;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> search(String query) async {
    _searchQuery = query.trim();
    notifyListeners();
    if (_searchQuery.isEmpty) {
      return;
    }
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

  void setSelectedCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
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