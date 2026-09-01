import '../app/constants/api_constants.dart';
import '../core/network/api_service.dart';
import '../models/product_model.dart';

class AdminProductService {
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
    final response = await ApiService.instance.get(ApiConstants.adminProducts);
    return _parseList(response);
  }

  ProductModel _single(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['product'] is Map<String, dynamic>
          ? response['product'] as Map<String, dynamic>
          : response;
      return ProductModel.fromJson(data);
    }
    throw ApiException('Unexpected response from server.');
  }

  Future<ProductModel> addProduct(Map<String, dynamic> data) async {
    final response = await ApiService.instance.post(
      ApiConstants.adminProducts,
      body: data,
    );
    return _single(response);
  }

  Future<ProductModel> updateProduct(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await ApiService.instance.put(
      '${ApiConstants.adminProducts}/$id',
      body: data,
    );
    return _single(response);
  }

  Future<void> deleteProduct(int id) async {
    await ApiService.instance.delete('${ApiConstants.adminProducts}/$id');
  }
}
