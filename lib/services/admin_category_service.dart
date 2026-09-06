import '../app/constants/api_constants.dart';
import '../core/network/api_service.dart';
import '../models/category_model.dart';

class AdminCategoryService {
  List<CategoryModel> _parseList(dynamic response) {
    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(CategoryModel.fromJson)
          .toList();
    }
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(CategoryModel.fromJson)
            .toList();
      }
      final items = response['items'];
      if (items is List) {
        return items
            .whereType<Map<String, dynamic>>()
            .map(CategoryModel.fromJson)
            .toList();
      }
    }
    return [];
  }

  Future<List<CategoryModel>> fetchCategories() async {
    final response = await ApiService.instance.get(ApiConstants.adminCategories);
    return _parseList(response);
  }

  CategoryModel _single(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['category'] is Map<String, dynamic>
          ? response['category'] as Map<String, dynamic>
          : response;
      return CategoryModel.fromJson(data);
    }
    throw ApiException('Unexpected response from server.');
  }

  Future<CategoryModel> addCategory(Map<String, dynamic> data) async {
    final response = await ApiService.instance.post(
      ApiConstants.adminCategories,
      body: data,
    );
    return _single(response);
  }

  Future<CategoryModel> updateCategory(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await ApiService.instance.put(
      '${ApiConstants.adminCategories}/$id',
      body: data,
    );
    return _single(response);
  }

  Future<void> deleteCategory(int id) async {
    await ApiService.instance.delete('${ApiConstants.adminCategories}/$id');
  }
}
