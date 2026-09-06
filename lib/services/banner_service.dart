import '../app/constants/api_constants.dart';
import '../core/network/api_service.dart';
import '../models/banner_model.dart';

class BannerService {
  List<BannerModel> _parseList(dynamic response) {
    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(BannerModel.fromJson)
          .toList();
    }
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(BannerModel.fromJson)
            .toList();
      }
    }
    return [];
  }

  Future<List<BannerModel>> fetchActiveBanners() async {
    final response = await ApiService.instance.get(ApiConstants.banners);
    return _parseList(response);
  }
}
