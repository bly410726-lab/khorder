import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/constants/maps_constants.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/delivery_location_model.dart';
import '../../../services/geocoding_service.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key, this.initialLocation});

  final DeliveryLocation? initialLocation;

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  Timer? _debounce;
  LatLng? _cameraCenter;

  int _requestId = 0;

  bool _isGeocoding = false;
  bool _isLocatingUser = false;
  bool _hasError = false;
  String? _errorMessage;

  DeliveryLocation? _selectedLocation;
  String? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _selectedAddress = widget.initialLocation?.address;
    if (widget.initialLocation != null) {
      _cameraCenter = LatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
    }
    _ensureInitialLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  LatLng get _initialCenter => _cameraCenter ??
      LatLng(
        widget.initialLocation?.latitude ?? MapsConstants.defaultLatitude,
        widget.initialLocation?.longitude ?? MapsConstants.defaultLongitude,
      );

  Future<void> _ensureInitialLocation() async {
    if (widget.initialLocation != null) return;

    try {
      setState(() => _isLocatingUser = true);
      final permission = await Geolocator.checkPermission();
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isEnabled) return;

      var status = permission;
      if (status == LocationPermission.denied) {
        status = await Geolocator.requestPermission();
      }
      if (status == LocationPermission.denied ||
          status == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      if (!mounted) return;
      final target = LatLng(position.latitude, position.longitude);
      _cameraCenter = target;
      _mapController.move(target, MapsConstants.defaultZoom);
      _onMapTap(target);
    } catch (_) {
      // Leave the camera at the default location.
    } finally {
      if (mounted) setState(() => _isLocatingUser = false);
    }
  }

  Future<void> _reverseGeocode(LatLng center) async {
    final int myRequestId = ++_requestId;

    setState(() {
      _isGeocoding = true;
      _hasError = false;
      _errorMessage = null;
      _selectedLocation = null;
    });

    final result = await GeocodingService.instance.reverseGeocode(
      latitude: center.latitude,
      longitude: center.longitude,
    );

    if (!mounted) return;
    if (myRequestId != _requestId) return;

    setState(() {
      _isGeocoding = false;
      if (result.location != null) {
        _selectedLocation = result.location;
        _selectedAddress = result.location!.address;
      } else {
        _hasError = true;
        _errorMessage = result.errorMessage;
        _selectedAddress = null;
      }
    });
  }

  void _onMapTap(LatLng point) {
    _cameraCenter = point;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _reverseGeocode(point);
    });
    setState(() {});
  }

  Future<void> _locateUser() async {
    try {
      setState(() => _isLocatingUser = true);
      final permission = await Geolocator.checkPermission();
      var status = permission;
      if (status == LocationPermission.denied) {
        status = await Geolocator.requestPermission();
      }
      if (status == LocationPermission.denied ||
          status == LocationPermission.deniedForever) {
        if (mounted) {
          Helpers.showSnackBar(
            context,
            'Location permission is required to find your current location.',
            isError: true,
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      if (!mounted) return;
      final target = LatLng(position.latitude, position.longitude);
      _cameraCenter = target;
      _mapController.move(target, MapsConstants.defaultZoom);
      _onMapTap(target);
    } catch (_) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Could not find your location. Please try again.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLocatingUser = false);
    }
  }

  bool get _canConfirm =>
      _selectedLocation != null &&
          _selectedLocation!.isValid &&
          _selectedAddress != null &&
          _selectedAddress!.isNotEmpty &&
          !_isGeocoding &&
          !_hasError;

  void _confirm() {
    final location = _selectedLocation;
    if (location == null || !location.isValid) return;
    Navigator.of(context).pop(location);
  }

  void _changeLocation() {
    _requestId++;
    _debounce?.cancel();

    setState(() {
      _selectedLocation = null;
      _selectedAddress = null;
      _hasError = false;
      _isGeocoding = false;
    });

    final center = _cameraCenter;
    if (center != null) {
      _reverseGeocode(center);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Delivery Location')),
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialCenter,
                initialZoom: MapsConstants.defaultZoom,
                onTap: (tapPosition, point) => _onMapTap(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.khorder.app',
                ),
                MarkerLayer(
                  markers: [
                    if (_cameraCenter != null)
                      Marker(
                        point: _cameraCenter!,
                        width: 50,
                        height: 50,
                        child: const Icon(
                          Icons.location_pin,
                          size: 50,
                          color: AppColors.primary,
                          shadows: [
                            Shadow(
                              color: Colors.black38,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildSearchBar(),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isGeocoding
                  ? 'Finding address...'
                  : (_selectedAddress ?? 'Tap the map to choose a location'),
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
          ),
          IconButton(
            onPressed: _isLocatingUser ? null : _locateUser,
            icon: _isLocatingUser
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
                : const Icon(Icons.my_location, color: AppColors.primary),
            tooltip: 'Use my current location',
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.42,
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.location_on, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Selected Delivery Location',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _isGeocoding
                ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Finding address...'),
                ],
              ),
            )
                : _hasError
                ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage ??
                        'Unable to find the address for this location.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      final center = _cameraCenter;
                      if (center != null) {
                        _reverseGeocode(center);
                      }
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ],
              ),
            )
                : Column(
              children: [
                if (_selectedAddress != null)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _selectedAddress!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  const Text(
                    'Tap the map to choose a location.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                if (_selectedLocation != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Latitude: ${_selectedLocation!.latitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Longitude: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _changeLocation,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    child: const Text('Change Location'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _canConfirm ? _confirm : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    child: const Text('Confirm Location'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
