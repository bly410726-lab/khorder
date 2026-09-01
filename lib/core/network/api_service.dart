import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../app/constants/api_constants.dart';

class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  static const Duration _timeout = Duration(seconds: 20);

  /// Temporary debug logging for API connectivity diagnosis. Set to false to disable.
  static const bool _debugLogEnabled = true;

  static void _debugLog(String tag, String message) {
    if (!_debugLogEnabled) return;
    // ignore: avoid_print
    print('[API $tag] $message');
  }

  static String _snippet(String body) {
    if (body.isEmpty) return '';
    final trimmed = body.trim();
    return trimmed.length <= 250 ? trimmed : '${trimmed.substring(0, 250)}...';
  }

  String? _token;

  String? get token => _token;

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Uri _buildUri(String path) {
    return Uri.parse('${ApiConstants.baseUrl}$path');
  }

  Future<dynamic> get(String path) async {
    final uri = _buildUri(path);
    _debugLog('REQUEST', 'GET $uri');
    try {
      final response = await http.get(uri, headers: _headers).timeout(_timeout);
      _debugLog('RESPONSE', 'GET $uri -> ${response.statusCode}');
      final body = _snippet(response.body);
      if (body.isNotEmpty) _debugLog('BODY', body);
      return _decodeResponse(response);
    } on TimeoutException {
      _debugLog('ERROR', 'TimeoutException on GET $uri');
      throw ApiException('The request timed out. Please try again.');
    } on http.ClientException catch (e) {
      _debugLog('ERROR', 'ClientException on GET $uri: ${e.message}');
      throw ApiException('Could not connect to the server. Please check your internet connection.');
    } on FormatException catch (e) {
      _debugLog('ERROR', 'FormatException on GET $uri: $e');
      throw ApiException('Received an unexpected response from the server.');
    } catch (e) {
      _debugLog('ERROR', '${e.runtimeType} on GET $uri: $e');
      rethrow;
    }
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    _debugLog('REQUEST', 'POST $uri');
    try {
      final response = await http
          .post(
            uri,
            headers: _headers,
            body: jsonEncode(body ?? {}),
          )
          .timeout(_timeout);
      _debugLog('RESPONSE', 'POST $uri -> ${response.statusCode}');
      final snippet = _snippet(response.body);
      if (snippet.isNotEmpty) _debugLog('BODY', snippet);
      return _decodeResponse(response);
    } on TimeoutException {
      _debugLog('ERROR', 'TimeoutException on POST $uri');
      throw ApiException('The request timed out. Please try again.');
    } on http.ClientException catch (e) {
      _debugLog('ERROR', 'ClientException on POST $uri: ${e.message}');
      throw ApiException('Could not connect to the server. Please check your internet connection.');
    } on FormatException catch (e) {
      _debugLog('ERROR', 'FormatException on POST $uri: $e');
      throw ApiException('Received an unexpected response from the server.');
    } catch (e) {
      _debugLog('ERROR', '${e.runtimeType} on POST $uri: $e');
      rethrow;
    }
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    _debugLog('REQUEST', 'PUT $uri');
    try {
      final response = await http
          .put(
            uri,
            headers: _headers,
            body: jsonEncode(body ?? {}),
          )
          .timeout(_timeout);
      _debugLog('RESPONSE', 'PUT $uri -> ${response.statusCode}');
      final snippet = _snippet(response.body);
      if (snippet.isNotEmpty) _debugLog('BODY', snippet);
      return _decodeResponse(response);
    } on TimeoutException {
      _debugLog('ERROR', 'TimeoutException on PUT $uri');
      throw ApiException('The request timed out. Please try again.');
    } on http.ClientException catch (e) {
      _debugLog('ERROR', 'ClientException on PUT $uri: ${e.message}');
      throw ApiException('Could not connect to the server. Please check your internet connection.');
    } on FormatException catch (e) {
      _debugLog('ERROR', 'FormatException on PUT $uri: $e');
      throw ApiException('Received an unexpected response from the server.');
    } catch (e) {
      _debugLog('ERROR', '${e.runtimeType} on PUT $uri: $e');
      rethrow;
    }
  }

  Future<dynamic> delete(String path) async {
    final uri = _buildUri(path);
    _debugLog('REQUEST', 'DELETE $uri');
    try {
      final response = await http.delete(uri, headers: _headers).timeout(_timeout);
      _debugLog('RESPONSE', 'DELETE $uri -> ${response.statusCode}');
      final snippet = _snippet(response.body);
      if (snippet.isNotEmpty) _debugLog('BODY', snippet);
      return _decodeResponse(response);
    } on TimeoutException {
      _debugLog('ERROR', 'TimeoutException on DELETE $uri');
      throw ApiException('The request timed out. Please try again.');
    } on http.ClientException catch (e) {
      _debugLog('ERROR', 'ClientException on DELETE $uri: ${e.message}');
      throw ApiException('Could not connect to the server. Please check your internet connection.');
    } on FormatException catch (e) {
      _debugLog('ERROR', 'FormatException on DELETE $uri: $e');
      throw ApiException('Received an unexpected response from the server.');
    } catch (e) {
      _debugLog('ERROR', '${e.runtimeType} on DELETE $uri: $e');
      rethrow;
    }
  }

  dynamic _decodeResponse(http.Response response) {
    final statusCode = response.statusCode;
    Map<String, dynamic>? body;
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        body = null;
      }
    }

    if (statusCode >= 200 && statusCode < 300) {
      if (body == null) {
        return null;
      }
      final success = body['success'];
      if (success == false) {
        throw ApiException(
          _extractMessage(body) ?? 'The request could not be completed.',
        );
      }
      return body['data'] ?? body;
    }

    if (statusCode == 401) {
      throw ApiException(
        _extractMessage(body) ?? 'Your session has expired. Please log in again.',
      );
    }
    if (statusCode == 403) {
      throw ApiException(
        _extractMessage(body) ?? 'You do not have permission to perform this action.',
      );
    }
    if (statusCode == 404) {
      throw ApiException(
        _extractMessage(body) ?? 'The requested resource was not found.',
      );
    }
    if (statusCode == 422) {
      final message = _extractMessage(body) ?? 'Please check your information and try again.';
      final validationErrors = body?['errors'];
      throw ApiException(
        message,
        validationErrors: validationErrors is Map<String, dynamic>
            ? validationErrors
            : null,
      );
    }
    throw ApiException(
      _extractMessage(body) ?? 'Something went wrong. Please try again later.',
    );
  }

  String? _extractMessage(Map<String, dynamic>? body) {
    if (body == null) return null;
    final message = body['message'];
    if (message is String && message.isNotEmpty) {
      return message;
    }
    return null;
  }
}

class ApiException implements Exception {
  ApiException(this.message, {this.validationErrors});

  final String message;

  /// Map of field name -> list of error messages (from 422 validation).
  final Map<String, dynamic>? validationErrors;

  String? fieldError(String field) {
    final errors = validationErrors?[field];
    if (errors is List && errors.isNotEmpty) {
      return errors.first.toString();
    }
    return null;
  }

  @override
  String toString() => message;
}
