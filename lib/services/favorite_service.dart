import '../app/constants/api_constants.dart';
import '../core/network/api_service.dart';
import '../models/product_model.dart';

class FavoriteService {
  List<ProductModel> _parseList(dynamic response) {
    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(ProductModel.fromJson)
          .toList();
    }
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(ProductModel.fromJson)
            .toList();
      }
      final items = response['items'];
      if (items is List) {
        return items
            .whereType<Map<String, dynamic>>()
            .map(ProductModel.fromJson)
            .toList();
      }
      final favorites = response['favorites'];
      if (favorites is List) {
        return favorites
            .whereType<Map<String, dynamic>>()
            .map(ProductModel.fromJson)
            .toList();
      }
    }
    return [];
  }

  Future<List<ProductModel>> fetchFavorites() async {
    final response = await ApiService.instance.get(ApiConstants.favorites);
    return _parseList(response);
  }

  Future<void> addFavorite(int productId) async {
    await ApiService.instance.post(
      ApiConstants.favorites,
      body: {'product_id': productId},
    );
  }

  Future<void> removeFavorite(int productId) async {
    await ApiService.instance.delete('${ApiConstants.favorites}/$productId');
  }
}