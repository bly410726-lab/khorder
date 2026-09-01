import '../app/constants/api_constants.dart';
import '../core/network/api_service.dart';
import '../models/user_model.dart';

class AuthService {
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiService.instance.post(
      ApiConstants.login,
      body: {
        'email': email,
        'password': password,
      },
    );

    final data = _asMap(response);
    _ensureSuccess(data);

    final token = data['token'] as String?;
    final user = data['user'] as Map<String, dynamic>?;

    if (token == null || user == null) {
      throw ApiException('Unable to log in. Please check your credentials and try again.');
    }

    ApiService.instance.setToken(token);

    return UserModel.fromJson(user);
  }

  Future<UserModel?> register({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String password,
  }) async {
    final response = await ApiService.instance.post(
      ApiConstants.register,
      body: {
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'password': password,
      },
    );

    final data = _asMap(response);
    _ensureSuccess(data);

    final token = data['token'] as String?;
    final user = data['user'] as Map<String, dynamic>?;

    if (token == null || user == null) {
      throw ApiException('Unable to create your account. Please try again.');
    }

    ApiService.instance.setToken(token);

    return UserModel.fromJson(user);
  }

  Future<void> logout() async {
    try {
      await ApiService.instance.post(ApiConstants.logout);
    } catch (_) {
      // Even if the server logout fails, clear the local session.
    }
    ApiService.instance.clearToken();
  }

  Future<UserModel?> fetchCurrentUser() async {
    final response = await ApiService.instance.get(ApiConstants.user);
    final data = _asMap(response);
    return UserModel.fromJson(data);
  }

  Future<UserModel?> updateProfile(Map<String, dynamic> data) async {
    final response = await ApiService.instance.put(ApiConstants.profile, body: data);
    final map = _asMap(response);
    final userData = map['user'] is Map<String, dynamic>
        ? map['user'] as Map<String, dynamic>
        : map;
    return UserModel.fromJson(userData);
  }

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      return response;
    }
    throw ApiException('Unexpected response from server.');
  }

  void _ensureSuccess(Map<String, dynamic> data) {
    final success = data['success'];
    if (success == false) {
      throw ApiException(data['message']?.toString() ?? 'Request failed');
    }
  }
}
