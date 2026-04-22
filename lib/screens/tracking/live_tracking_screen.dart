/// VigilionX - Live Tracking Screen
/// Real-time GPS tracking with Google Maps integration.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../config/theme.dart';
import '../../services/location_service.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_widgets.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final LocationService _locationService = LocationService();
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  final List<LatLng> _polylinePoints = [];
  bool _isTracking = false;
  bool _isLoading = true;
  StreamSubscription<Position>? _trackingSubscription;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final position = await _locationService.getCurrentPosition();
    if (position != null && mounted) {
      setState(() {
        _currentPosition = position;
        _isLoading = false;
        _updateMarker(position);
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _updateMarker(Position position) {
    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('current'),
        position: LatLng(position.latitude, position.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Your Location',
          snippet:
              '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
        ),
      ),
    );
  }

  void _toggleTracking() {
    if (_isTracking) {
      _stopTracking();
    } else {
      _startTracking();
    }
  }

  void _startTracking() {
    _locationService.startTracking();
    _trackingSubscription = _locationService.locationStream.listen(
      (position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
            _updateMarker(position);
            _polylinePoints.add(
              LatLng(position.latitude, position.longitude),
            );
          });

          _mapController?.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(position.latitude, position.longitude),
            ),
          );
        }
      },
    );

    setState(() => _isTracking = true);
    Helpers.showSnackbar(context, 'Live tracking started', isSuccess: true);
  }

  void _stopTracking() {
    _trackingSubscription?.cancel();
    _locationService.stopTracking();
    setState(() => _isTracking = false);
    Helpers.showSnackbar(context, 'Tracking stopped');
  }

  @override
  void dispose() {
    _trackingSubscription?.cancel();
    _locationService.stopTracking();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          if (_isLoading)
            Container(
              color: AppColors.darkBg,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_currentPosition != null)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                zoom: 16,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              onMapCreated: (controller) => _mapController = controller,
              markers: _markers,
              polylines: _polylinePoints.length >= 2
                  ? {
                      Polyline(
                        polylineId: const PolylineId('tracking'),
                        points: _polylinePoints,
                        color: AppColors.primary,
                        width: 4,
                      ),
                    }
                  : {},
            )
          else
            Container(
              color: AppColors.darkBg,
              child: const Center(
                child: EmptyStateWidget(
                  icon: Icons.location_off,
                  title: 'Location Unavailable',
                  subtitle: 'Please enable GPS and grant location permission.',
                ),
              ),
            ),

          // Top bar overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _circleButton(
                    icon: Icons.arrow_back_ios_new,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  _circleButton(
                    icon: Icons.my_location,
                    onTap: () {
                      if (_currentPosition != null) {
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            16,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // Bottom control panel
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (_isTracking
                                  ? AppColors.success
                                  : AppColors.textMuted)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _isTracking
                              ? Icons.gps_fixed
                              : Icons.gps_not_fixed,
                          color:
                              _isTracking ? AppColors.success : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isTracking
                                  ? 'Tracking Active'
                                  : 'Live Tracking',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (_currentPosition != null)
                              Text(
                                '${_currentPosition!.latitude.toStringAsFixed(4)}, '
                                '${_currentPosition!.longitude.toStringAsFixed(4)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.textLight
                                      : AppColors.textDarkSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GradientButton(
                    text: _isTracking ? 'Stop Tracking' : 'Start Tracking',
                    icon: _isTracking ? Icons.stop : Icons.play_arrow,
                    gradient: _isTracking
                        ? [AppColors.error, AppColors.primaryDark]
                        : AppColors.accentGradient,
                    onPressed: _toggleTracking,
                    height: 48,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.darkCard.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
