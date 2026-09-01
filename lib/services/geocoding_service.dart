import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app/constants/maps_constants.dart';
import '../models/delivery_location_model.dart';

class GeocodingService {
  GeocodingService._();

  static final GeocodingService instance = GeocodingService._();

  static const Duration _timeout = Duration(seconds: 15);

  Future<DeliveryLocation?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      'maps/api/geocode/json',
      {
        'latlng': '$latitude,$longitude',
        'key': MapsConstants.googleApiKey,
        'language': 'en',
      },
    );

    try {
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final status = decoded['status'] as String?;

      if (status != 'OK') {
        return null;
      }

      final results = decoded['results'] as List?;
      if (results == null || results.isEmpty) {
        return null;
      }

      final result = results.first as Map<String, dynamic>;
      final formattedAddress = result['formatted_address'] as String?;
      if (formattedAddress == null || formattedAddress.isEmpty) {
        return null;
      }

      final addressComponents =
          result['address_components'] as List<dynamic>? ?? const [];
      final addressLine = _buildLocalAddress(
        formattedAddress: formattedAddress,
        components: addressComponents,
      );

      return DeliveryLocation(
        address: addressLine,
        latitude: latitude,
        longitude: longitude,
      );
    } on TimeoutException {
      return null;
    } on http.ClientException {
      return null;
    } on FormatException {
      return null;
    } catch (_) {
      return null;
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
