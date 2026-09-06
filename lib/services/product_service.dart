import '../app/constants/api_constants.dart';
import '../core/network/api_service.dart';
import '../models/product_model.dart';

class ProductService {
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
    }
    return [];
  }

  Future<List<ProductModel>> fetchProducts() async {
    final response = await ApiService.instance.get(ApiConstants.products);
    return _parseList(response);
  }

  Future<List<ProductModel>> fetchFeaturedProducts() async {
    final response = await ApiService.instance.get(ApiConstants.products);
    final products = _parseList(response);
    final featured = products.where((p) => p.isFeatured == true).toList();
    return featured.isNotEmpty ? featured : products;
  }

  Future<ProductModel?> fetchProductById(int id) async {
    final response = await ApiService.instance.get('${ApiConstants.products}/$id');
    if (response is Map<String, dynamic>) {
      final data = response['product'] is Map<String, dynamic>
          ? response['product'] as Map<String, dynamic>
          : response;
      return ProductModel.fromJson(data);
    }
    return null;
  }

  Future<List<ProductModel>> fetchProductsByCategory(int categoryId) async {
    final response = await ApiService.instance
        .get('${ApiConstants.products}?category_id=$categoryId');
    return _parseList(response);
  }
}
