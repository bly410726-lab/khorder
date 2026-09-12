import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import '../models/delivery_location_model.dart';

class GeocodingResult {
  final DeliveryLocation? location;
  final String? errorMessage;

  const GeocodingResult({this.location, this.errorMessage});
}

class GeocodingService {
  GeocodingService._();

  static final GeocodingService instance = GeocodingService._();

  static const Duration _timeout = Duration(seconds: 15);

  /// Nominatim requires a valid User-Agent header per its usage policy.
  static const String _userAgent = 'com.khorder.app';

  Future<GeocodingResult> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    if (latitude < -90 || latitude > 90) {
      developer.log(
        '[REVERSE GEOCODING] Invalid latitude: $latitude',
        name: 'GeocodingService',
      );
      return const GeocodingResult(errorMessage: 'Invalid latitude value.');
    }
    if (longitude < -180 || longitude > 180) {
      developer.log(
        '[REVERSE GEOCODING] Invalid longitude: $longitude',
        name: 'GeocodingService',
      );
      return const GeocodingResult(errorMessage: 'Invalid longitude value.');
    }

    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/reverse',
      {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'format': 'json',
        'addressdetails': '1',
        'accept-language': 'en',
      },
    );

    developer.log(
      '[REVERSE GEOCODING REQUEST]\n'
          'Latitude: $latitude\n'
          'Longitude: $longitude\n'
          'Endpoint: ${uri.scheme}://${uri.host}${uri.path}\n'
          'HTTP method: GET',
      name: 'GeocodingService',
    );

    try {
      final response = await http
          .get(uri, headers: {'User-Agent': _userAgent})
          .timeout(_timeout);

      developer.log(
        '[REVERSE GEOCODING RESPONSE]\n'
            'HTTP Status: ${response.statusCode}\n'
            'Response body: ${response.body}',
        name: 'GeocodingService',
      );

      if (response.statusCode != 200) {
        return GeocodingResult(
          errorMessage:
          'Geocoding server returned HTTP ${response.statusCode}.',
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;

      final displayName = decoded['display_name'] as String?;
      if (displayName == null || displayName.isEmpty) {
        return const GeocodingResult(
          errorMessage: 'No address found for this location.',
        );
      }

      final address = _buildLocalAddress(
        displayName: displayName,
        addressData: decoded['address'] as Map<String, dynamic>?,
      );

      return GeocodingResult(
        location: DeliveryLocation(
          address: address,
          latitude: latitude,
          longitude: longitude,
        ),
      );
    } on http.ClientException catch (e) {
      developer.log(
        '[REVERSE GEOCODING ERROR] ClientException: ${e.message}',
        name: 'GeocodingService',
      );
      return const GeocodingResult(
        errorMessage: 'Network error while finding address. Please check your connection.',
      );
    } on TimeoutException {
      developer.log(
        '[REVERSE GEOCODING ERROR] Request timed out',
        name: 'GeocodingService',
      );
      return const GeocodingResult(
        errorMessage: 'Geocoding request timed out. Check your connection.',
      );
    } on FormatException catch (e) {
      developer.log(
        '[REVERSE GEOCODING ERROR] FormatException: ${e.message}',
        name: 'GeocodingService',
      );
      return const GeocodingResult(
        errorMessage: 'Invalid response from geocoding service.',
      );
    } catch (e) {
      developer.log(
        '[REVERSE GEOCODING ERROR] Unexpected: $e',
        name: 'GeocodingService',
      );
      return const GeocodingResult(
        errorMessage: 'An unexpected error occurred while finding address.',
      );
    }
  }

  String _buildLocalAddress({
    required String displayName,
    Map<String, dynamic>? addressData,
  }) {
    if (addressData == null || addressData.isEmpty) {
      return displayName;
    }

    String? houseNumber;
    String? street;
    String? commune;
    String? district;
    String? city;
    String? state;
    String? country;

    houseNumber = addressData['house_number'] as String?;
    street = addressData['road'] as String?;
    commune = addressData['commune'] as String?;
    district = addressData['suburb'] as String? ??
        addressData['neighbourhood'] as String?;
    city = addressData['city'] as String? ??
        addressData['town'] as String? ??
        addressData['village'] as String?;
    state = addressData['state'] as String?;
    country = addressData['country'] as String?;

    final addressParts = <String>[
      if (houseNumber != null && street != null) '$street $houseNumber',
      if (houseNumber == null && street != null) street,
    ];

    final localityParts = <String>[
      if (commune != null) commune,
      if (district != null) district,
    ].where((e) => e.isNotEmpty).join(', ');

    final regionParts = <String>[
      if (city != null) city,
      if (state != null) state,
      if (country != null) country,
    ].where((e) => e.isNotEmpty).join(', ');

    final parts = <String>[
      if (addressParts.isNotEmpty) addressParts.join(' '),
      if (localityParts.isNotEmpty) localityParts,
      if (regionParts.isNotEmpty) regionParts,
    ];

    if (parts.isNotEmpty) {
      return parts.join(', ');
    }

    return displayName;
  }
}
