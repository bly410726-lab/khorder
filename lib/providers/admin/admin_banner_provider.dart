import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/network/api_service.dart';
import '../../models/banner_model.dart';
import '../../services/admin_banner_service.dart';

class AdminBannerProvider extends ChangeNotifier {
  final AdminBannerService _bannerService = AdminBannerService();

  List<BannerModel> _banners = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  List<BannerModel> get banners => _banners;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  Future<void> fetchBanners() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _banners = await _bannerService.fetchBanners();
    } catch (e) {
      _errorMessage = _friendlyError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addBanner({
    required File imageFile,
    String? title,
    bool isActive = true,
    int sortOrder = 0,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _bannerService.createBanner(
        imageFile: imageFile,
        title: title,
        isActive: isActive,
        sortOrder: sortOrder,
      );
      await fetchBanners();
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateBanner({
    required int id,
    File? imageFile,
    String? title,
    bool? isActive,
    int? sortOrder,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _bannerService.updateBanner(
        id: id,
        imageFile: imageFile,
        title: title,
        isActive: isActive,
        sortOrder: sortOrder,
      );
      await fetchBanners();
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> toggleBanner(BannerModel banner) async {
    try {
      await _bannerService.updateBanner(
        id: banner.id ?? -1,
        isActive: !(banner.isActive ?? true),
      );
      await fetchBanners();
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBanner(int id) async {
    try {
      await _bannerService.deleteBanner(id);
      await fetchBanners();
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

  String _friendlyError(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return 'Could not connect to the server. Please try again.';
  }
}
