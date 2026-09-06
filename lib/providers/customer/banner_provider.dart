import 'package:flutter/foundation.dart';

import '../../core/network/api_service.dart';
import '../../models/banner_model.dart';
import '../../services/banner_service.dart';

class BannerProvider extends ChangeNotifier {
  final BannerService _bannerService = BannerService();

  List<BannerModel> _banners = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BannerModel> get banners => _banners;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchActiveBanners() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _banners = await _bannerService.fetchActiveBanners();
    } catch (e) {
      _errorMessage = _friendlyError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
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
    return 'Could not load banners. Please try again.';
  }
}
