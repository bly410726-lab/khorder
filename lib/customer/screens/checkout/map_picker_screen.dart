import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  final GlobalKey _mapKey = GlobalKey();

  GoogleMapController? _mapController;
  Timer? _debounce;
  LatLng? _cameraCenter;
  LatLng? _pendingTarget;

  bool _isGeocoding = false;
  bool _isLocatingUser = false;
  bool _hasError = false;

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
    _mapController?.dispose();
    super.dispose();
  }

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
      _moveCamera(
        LatLng(position.latitude, position.longitude),
        MapsConstants.defaultZoom,
      );
      _onCameraIdle();
    } catch (_) {
      // Leave the camera at the default location.
    } finally {
      if (mounted) setState(() => _isLocatingUser = false);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _moveCamera(LatLng target, double zoom) async {
    final controller = _mapController;
    if (controller == null) return;
    await controller.moveCamera(CameraUpdate.newLatLngZoom(target, zoom));
  }

  void _onCameraIdle() {
    final center = _cameraCenter;
    if (center == null) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _reverseGeocode(center);
    });
  }

  Future<void> _reverseGeocode(LatLng center) async {
    if (_isGeocoding) {
      _pendingTarget = center;
      return;
    }

    setState(() {
      _isGeocoding = true;
      _hasError = false;
      _selectedLocation = null;
    });

    final requestCenter = center;
    final location = await GeocodingService.instance.reverseGeocode(
      latitude: requestCenter.latitude,
      longitude: requestCenter.longitude,
    );

    if (!mounted) return;

    setState(() {
      _isGeocoding = false;
      if (location != null) {
        _selectedLocation = location;
        _selectedAddress = location.address;
      } else {
        _hasError = true;
        _selectedAddress = null;
      }
    });

    final pending = _pendingTarget;
    _pendingTarget = null;
    if (pending != null && pending != requestCenter) {
      _reverseGeocode(pending);
    }
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
      await _moveCamera(
        LatLng(position.latitude, position.longitude),
        MapsConstants.defaultZoom,
      );
      _onCameraIdle();
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
    setState(() {
      _selectedLocation = null;
      _selectedAddress = null;
      _hasError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Delivery Location')),
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              key: _mapKey,
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  widget.initialLocation?.latitude ??
                      MapsConstants.defaultLatitude,
                  widget.initialLocation?.longitude ??
                      MapsConstants.defaultLongitude,
                ),
                zoom: MapsConstants.defaultZoom,
              ),
              onMapCreated: _onMapCreated,
              onCameraMove: (position) {
                _cameraCenter = position.target;
              },
              onCameraIdle: _onCameraIdle,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildSearchBar(),
            ),
          ),
          Center(
            child: IgnorePointer(
              child: Transform.translate(
                offset: const Offset(0, -48),
                child: const Icon(
                  Icons.location_pin,
                  size: 48,
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
                  : (_selectedAddress ?? 'Drag the map to choose a location'),
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
            Row(
              children: [
                Icon(Icons.location_on, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
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
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            Icon(Icons.error_outline,
                                color: AppColors.error, size: 32),
                            SizedBox(height: 8),
                            Text(
                              'Unable to find the address for this location.',
                              textAlign: TextAlign.center,
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
                              'Moving the map will find an address.',
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
             SizedBox(height: 16),
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
