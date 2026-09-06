import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/network/api_service.dart';
import '../core/storage/local_storage.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  String? _token;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  bool _isRestoring = false;
  String? _errorMessage;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  bool get isRestoring => _isRestoring;
  String? get errorMessage => _errorMessage;

  bool get isAdmin => _user?.role == 'admin';

  Future<void> restoreSession() async {
    _isRestoring = true;
    notifyListeners();
    final savedToken = await LocalStorage.instance.getToken();
    final savedUserData = await LocalStorage.instance.getUserData();
    if (savedToken == null || savedUserData == null) {
      _isRestoring = false;
      notifyListeners();
      return;
    }
    try {
      final userJson = jsonDecode(savedUserData) as Map<String, dynamic>;
      _user = UserModel.fromJson(userJson);
      _token = savedToken;
      _isLoggedIn = true;
      ApiService.instance.setToken(savedToken);
    } catch (_) {
      await LocalStorage.instance.clear();
    }
    _isRestoring = false;
    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);

    try {
      final user = await _authService.login(
        email: email,
        password: password,
      );

      if (user == null) {
        throw ApiException('Unable to log in. Please check your credentials and try again.');
      }

      _user = user;
      _token = ApiService.instance.token;
      _isLoggedIn = true;
      _errorMessage = null;

      await _persistSession(user);
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String password,
  }) async {
    _setLoading(true);

    try {
      final user = await _authService.register(
        name: name,
        email: email,
        phone: phone,
        address: address,
        password: password,
      );

      if (user == null) {
        throw ApiException('Unable to create your account. Please try again.');
      }

      _user = user;
      _token = ApiService.instance.token;
      _isLoggedIn = true;
      _errorMessage = null;

      await _persistSession(user);
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> fetchCurrentUser() async {
    try {
      final user = await _authService.fetchCurrentUser();
      if (user != null) {
        _user = user;
        await _persistSession(user);
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? address,
  }) async {
    _setLoading(true);

    try {
      final user = await _authService.updateProfile({
        'name': ?name,
        'phone': ?phone,
        'address': ?address,
      });
      if (user != null) {
        _user = user;
        await _persistSession(user);
        _errorMessage = null;
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _token = null;
    _isLoggedIn = false;
    _errorMessage = null;
    await LocalStorage.instance.clear();
    notifyListeners();
  }

  bool hasValidationError(String field) => false;

  String? fieldErrorFor(String field) {
    return null;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _persistSession(UserModel user) async {
    await LocalStorage.instance.saveToken(_token ?? '');
    await LocalStorage.instance.saveUserData(jsonEncode(user.toJson()));
    await LocalStorage.instance.saveRole(user.role ?? '');
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _errorMessage = null;
    notifyListeners();
  }

  String _friendlyError(Object error) {
    if (error is ApiException) {
      final message = error.message;
      if (message == 'These credentials do not match our records.') {
        return 'Incorrect email or password. Please try again.';
      }
      if (message == 'The given data was invalid.') {
        return 'Please check your information and try again.';
      }
      return message;
    }
    return 'Could not connect to server. Please check your connection and try again.';
  }
}