import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../app/constants/api_constants.dart';
import '../core/network/api_service.dart';
import '../models/banner_model.dart';

class AdminBannerService {
  final ApiService _api = ApiService.instance;

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

  BannerModel _single(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : response;
      return BannerModel.fromJson(data);
    }
    throw ApiException('Unexpected response from server.');
  }

  Future<List<BannerModel>> fetchBanners() async {
    final response = await _api.get(ApiConstants.adminBanners);
    return _parseList(response);
  }

  Future<BannerModel> createBanner({
    required File imageFile,
    String? title,
    bool isActive = true,
    int sortOrder = 0,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminBanners}');
    final request = http.MultipartRequest('POST', uri);

    if (_api.token != null && _api.token!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer ${_api.token}';
    }
    request.headers['Accept'] = 'application/json';

    final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
    final mimeSplit = mimeType.split('/');

    request.files.add(await http.MultipartFile.fromPath(
      'image',
      imageFile.path,
      contentType: MediaType(mimeSplit[0], mimeSplit[1]),
    ));

    request.fields['title'] = title ?? '';
    request.fields['is_active'] = isActive.toString();
    request.fields['sort_order'] = sortOrder.toString();

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
    );
    final response = await http.Response.fromStream(streamedResponse);
    final body = _tryDecodeBody(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body is Map<String, dynamic>) {
        return _single(body);
      }
      throw ApiException('Failed to parse server response.');
    }

    if (response.statusCode == 422) {
      final message = body is Map<String, dynamic>
          ? (body['message'] as String? ?? 'Validation failed.')
          : 'Validation failed.';
      final errors = body is Map<String, dynamic> ? body['errors'] : null;
      throw ApiException(
        message,
        validationErrors: errors is Map<String, dynamic> ? errors : null,
        statusCode: 422,
      );
    }

    final message = body is Map<String, dynamic>
        ? (body['message'] as String? ?? 'Upload failed.')
        : 'Upload failed.';
    throw ApiException(message, statusCode: response.statusCode);
  }

  Future<BannerModel> updateBanner({
    required int id,
    File? imageFile,
    String? title,
    bool? isActive,
    int? sortOrder,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.adminBanners}/$id',
    );
    final request = http.MultipartRequest('POST', uri);

    request.fields['_method'] = 'PUT';

    if (_api.token != null && _api.token!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer ${_api.token}';
    }
    request.headers['Accept'] = 'application/json';

    if (imageFile != null) {
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      final mimeSplit = mimeType.split('/');

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType(mimeSplit[0], mimeSplit[1]),
      ));
    }

    if (title != null) request.fields['title'] = title;
    if (isActive != null) request.fields['is_active'] = isActive.toString();
    if (sortOrder != null) request.fields['sort_order'] = sortOrder.toString();

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
    );
    final response = await http.Response.fromStream(streamedResponse);
    final body = _tryDecodeBody(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body is Map<String, dynamic>) {
        return _single(body);
      }
      throw ApiException('Failed to parse server response.');
    }

    if (response.statusCode == 422) {
      final message = body is Map<String, dynamic>
          ? (body['message'] as String? ?? 'Validation failed.')
          : 'Validation failed.';
      final errors = body is Map<String, dynamic> ? body['errors'] : null;
      throw ApiException(
        message,
        validationErrors: errors is Map<String, dynamic> ? errors : null,
        statusCode: 422,
      );
    }

    final message = body is Map<String, dynamic>
        ? (body['message'] as String? ?? 'Update failed.')
        : 'Update failed.';
    throw ApiException(message, statusCode: response.statusCode);
  }

  Future<void> deleteBanner(int id) async {
    await _api.delete('${ApiConstants.adminBanners}/$id');
  }

  dynamic _tryDecodeBody(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return null;
    }
  }
}
