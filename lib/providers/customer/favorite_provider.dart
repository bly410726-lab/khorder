import 'package:flutter/foundation.dart';

import '../../core/network/api_service.dart';
import '../../models/product_model.dart';
import '../../services/favorite_service.dart';

class FavoriteProvider extends ChangeNotifier {
  final FavoriteService _favoriteService = FavoriteService();

  List<ProductModel> _favorites = [];
  bool _isLoading = false;
  final Set<int> _pendingUpdates = {};
  String? _errorMessage;

  List<ProductModel> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool isFavorite(int? productId) {
    return _favorites.any((product) => product.id == productId);
  }

  bool isUpdating(int? productId) {
    return productId != null && _pendingUpdates.contains(productId);
  }

  Future<void> fetchFavorites() async {
    _setLoading(true);
    try {
      _favorites = await _favoriteService.fetchFavorites();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = _friendlyError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleFavorite(ProductModel product) async {
    if (product.id == null) return false;

    final wasFavorite = isFavorite(product.id);
    _pendingUpdates.add(product.id!);
    notifyListeners();

    // Optimistic update.
    if (wasFavorite) {
      _favorites.removeWhere((item) => item.id == product.id);
    } else {
      _favorites.add(product);
    }
    notifyListeners();

    try {
      if (wasFavorite) {
        await _favoriteService.removeFavorite(product.id!);
      } else {
        await _favoriteService.addFavorite(product.id!);
      }
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      // Revert on failure.
      if (wasFavorite) {
        _favorites.add(product);
      } else {
        _favorites.removeWhere((item) => item.id == product.id);
      }
      return false;
    } finally {
      _pendingUpdates.remove(product.id!);
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