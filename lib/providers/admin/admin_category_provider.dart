import 'package:flutter/foundation.dart';

import '../../core/network/api_service.dart';
import '../../models/category_model.dart';
import '../../services/admin_category_service.dart';

class AdminCategoryProvider extends ChangeNotifier {
  final AdminCategoryService _categoryService = AdminCategoryService();

  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  List<CategoryModel> get categories => _categories;
  CategoryModel? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  Future<void> fetchCategories() async {
    _setLoading(true);
    try {
      _categories = await _categoryService.fetchCategories();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = _friendlyError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCategory(Map<String, dynamic> data) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _categoryService.addCategory(data);
      await fetchCategories();
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateCategory(int id, Map<String, dynamic> data) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _categoryService.updateCategory(id, data);
      await fetchCategories();
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      await _categoryService.deleteCategory(id);
      await fetchCategories();
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