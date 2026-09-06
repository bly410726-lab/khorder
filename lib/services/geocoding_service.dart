import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import '../app/constants/maps_constants.dart';
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
      'maps.googleapis.com',
      'maps/api/geocode/json',
      {
        'latlng': '$latitude,$longitude',
        'key': MapsConstants.googleApiKey,
        'language': 'en',
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
      final response = await http.get(uri).timeout(_timeout);

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
      final status = decoded['status'] as String?;

      if (status != 'OK') {
        final errorMsg =
            decoded['error_message'] as String? ?? 'Unknown error ($status)';
        developer.log(
          '[REVERSE GEOCODING ERROR]\n'
          'Google status: $status\n'
          'Error message: $errorMsg',
          name: 'GeocodingService',
        );
        if (status == 'REQUEST_DENIED') {
          return GeocodingResult(
            errorMessage:
                'Geocoding API request denied. $errorMsg',
          );
        }
        if (status == 'ZERO_RESULTS') {
          return GeocodingResult(
            errorMessage:
                'No address found for this location.',
          );
        }
        if (status == 'OVER_QUERY_LIMIT') {
          return GeocodingResult(
            errorMessage:
                'Geocoding API quota exceeded. Please try again later.',
          );
        }
        if (status == 'INVALID_REQUEST') {
          return const GeocodingResult(
            errorMessage: 'Invalid geocoding request.',
          );
        }
        return GeocodingResult(
          errorMessage: 'Geocoding failed: $errorMsg',
        );
      }

      final results = decoded['results'] as List?;
      if (results == null || results.isEmpty) {
        return const GeocodingResult(
          errorMessage: 'No address found for this location.',
        );
      }

      final result = results.first as Map<String, dynamic>;
      final formattedAddress = result['formatted_address'] as String?;
      if (formattedAddress == null || formattedAddress.isEmpty) {
        return const GeocodingResult(
          errorMessage: 'No address found for this location.',
        );
      }

      final addressComponents =
          result['address_components'] as List<dynamic>? ?? const [];
      final addressLine = _buildLocalAddress(
        formattedAddress: formattedAddress,
        components: addressComponents,
      );

      return GeocodingResult(
        location: DeliveryLocation(
          address: addressLine,
          latitude: latitude,
          longitude: longitude,
        ),
      );
    } on TimeoutException {
      developer.log(
        '[REVERSE GEOCODING ERROR] Request timed out',
        name: 'GeocodingService',
      );
      return const GeocodingResult(
        errorMessage: 'Geocoding request timed out. Check your connection.',
      );
    } on http.ClientException catch (e) {
      developer.log(
        '[REVERSE GEOCODING ERROR] ClientException: ${e.message}',
        name: 'GeocodingService',
      );
      return const GeocodingResult(
        errorMessage: 'Network error while finding address.',
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
    required String formattedAddress,
    required List<dynamic> components,
  }) {
    String? street;
    String? houseNumber;
    String? district;
    String? commune;
    String? city;
    String? province;
    String? country;

    for (final component in components) {
      final map = component as Map<String, dynamic>;
      final types = (map['types'] as List?)?.whereType<String>().toList() ?? [];
      final shortName = map['short_name'] as String? ?? '';
      final longName = map['long_name'] as String? ?? '';

      if (types.contains('street_number')) {
        houseNumber = shortName;
      } else if (types.contains('route')) {
        street = shortName.isNotEmpty ? shortName : longName;
      } else if (types.contains('sublocality_level_1')) {
        district = longName;
      } else if (types.contains('sublocality_level_2')) {
        commune = longName;
      } else if (types.contains('locality')) {
        city = longName;
      } else if (types.contains('administrative_area_level_1')) {
        province = longName;
      } else if (types.contains('country')) {
        country = longName;
      }
    }

    final addressParts = <String>[
      ?houseNumber,
      ?street,
    ];
    final addressLine = addressParts.join(' ');

    final localityParts = <String>[
      ?commune,
      ?district,
    ].join(', ');

    final cityProvinceParts = <String>[
      ?city,
      ?province,
      ?country,
    ].join(', ');

    final parts = <String>[
      if (addressLine.isNotEmpty) addressLine,
      if (localityParts.isNotEmpty) localityParts,
      if (cityProvinceParts.isNotEmpty) cityProvinceParts,
    ];

    if (parts.isNotEmpty) {
      return parts.join(', ');
    }

    return formattedAddress;
  }
}
