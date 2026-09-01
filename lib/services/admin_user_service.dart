import '../app/constants/api_constants.dart';
import '../core/network/api_service.dart';
import '../models/user_model.dart';

class AdminUserService {
  List<UserModel> _parseList(dynamic response) {
    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(UserModel.fromJson)
          .toList();
    }
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(UserModel.fromJson)
            .toList();
      }
      final items = response['items'];
      if (items is List) {
        return items
            .whereType<Map<String, dynamic>>()
            .map(UserModel.fromJson)
            .toList();
      }
      final users = response['users'];
      if (users is List) {
        return users
            .whereType<Map<String, dynamic>>()
            .map(UserModel.fromJson)
            .toList();
      }
    }
    return [];
  }

  Future<List<UserModel>> fetchUsers() async {
    final response = await ApiService.instance.get(ApiConstants.adminUsers);
    return _parseList(response);
  }
}
