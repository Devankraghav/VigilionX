/// VigilionX - Home Dashboard Screen
/// Main dashboard with map preview, SOS button, active trip, stats, and recent alerts.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/sos_alert.dart';
import '../../models/trip_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/trip_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  final FirestoreService _firestoreService = FirestoreService();
  int _currentIndex = 0;
  double? _currentLat;
  double? _currentLng;
  GoogleMapController? _mapController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _initLocation();
    _initProviders();
  }

  Future<void> _initLocation() async {
    final position = await _locationService.getCurrentPosition();
    if (position != null && mounted) {
      setState(() {
        _currentLat = position.latitude;
        _currentLng = position.longitude;
      });
    }
  }

  void _initProviders() {
    final uid = Provider.of<AuthProvider>(context, listen: false).uid;
    if (uid != null) {
      Provider.of<ContactsProvider>(context, listen: false).listenToContacts(uid);
      Provider.of<TripProvider>(context, listen: false).initialize(uid);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final contactsProvider = Provider.of<ContactsProvider>(context);
    final tripProvider = Provider.of<TripProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0A0E21), Color(0xFF141A2E)],
                )
              : null,
          color: isDark ? null : AppColors.lightBg,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with greeting
                _buildHeader(authProvider),
                const SizedBox(height: 20),

                // Safety Status Card
                _buildSafetyStatus(tripProvider),
                const SizedBox(height: 20),

                // Map Preview Card
                _buildMapPreview(),
                const SizedBox(height: 20),

                // Quick Stats Row
                _buildQuickStats(contactsProvider, tripProvider),
                const SizedBox(height: 20),

                // Active Trip Card (if exists)
                if (tripProvider.hasActiveTrip)
                  _buildActiveTripCard(tripProvider.activeTrip!),

                // Quick Actions Grid
                const SectionHeader(title: 'Quick Actions'),
                _buildQuickActions(),
                const SizedBox(height: 16),

                // Recent Alerts
                const SectionHeader(title: 'Recent Activity'),
                _buildRecentAlerts(authProvider.uid ?? ''),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      // Bottom Navigation
      bottomNavigationBar: _buildBottomNav(isDark),
      // Floating SOS Button
      floatingActionButton: _buildSOSFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader(AuthProvider auth) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.primaryGradient),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                auth.user?.fullName != null && auth.user!.fullName.isNotEmpty
                    ? auth.user!.fullName.substring(0, 1).toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${auth.user?.fullName.split(' ').first ?? 'User'} 👋',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Stay safe today',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textLight
                      : AppColors.textDarkSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.alertHistory),
          icon: Stack(
            children: [
              const Icon(Icons.notifications_outlined, size: 28),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyStatus(TripProvider tripProvider) {
    final isTripActive = tripProvider.hasActiveTrip;
    return GlassCard(
      gradientColors: isTripActive
          ? [const Color(0xFF1A237E), const Color(0xFF0D47A1)]
          : [const Color(0xFF1B5E20), const Color(0xFF2E7D32)],
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isTripActive ? Icons.directions_run : Icons.shield,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTripActive ? 'Trip in Progress' : 'You\'re Safe',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isTripActive
                      ? 'Heading to ${tripProvider.activeTrip!.destinationName}'
                      : 'No active emergencies',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 14 + (_pulseController.value * 4),
                height: 14 + (_pulseController.value * 4),
                decoration: BoxDecoration(
                  color: isTripActive
                      ? AppColors.info
                      : AppColors.success,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isTripActive
                              ? AppColors.info
                              : AppColors.success)
                          .withValues(alpha: 0.5),
                      blurRadius: 8 + (_pulseController.value * 4),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMapPreview() {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 180,
          child: Stack(
            children: [
              if (_currentLat != null && _currentLng != null)
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_currentLat!, _currentLng!),
                    zoom: 15,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  onMapCreated: (controller) => _mapController = controller,
                  markers: {
                    Marker(
                      markerId: const MarkerId('current'),
                      position: LatLng(_currentLat!, _currentLng!),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ),
                    ),
                  },
                )
              else
                Container(
                  color: AppColors.darkCard,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, size: 40, color: AppColors.textMuted),
                        SizedBox(height: 8),
                        Text(
                          'Loading map...',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),

              // Overlay button
              Positioned(
                right: 12,
                bottom: 12,
                child: GestureDetector(
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.liveTracking),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fullscreen, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Full Map',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(ContactsProvider contacts, TripProvider trips) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Contacts',
            value: '${contacts.contactCount}',
            icon: Icons.people,
            gradient: AppColors.accentGradient,
            onTap: () => Navigator.pushNamed(context, AppRoutes.contacts),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            title: 'Trips',
            value: '${trips.tripHistory.length}',
            icon: Icons.route,
            gradient: AppColors.purpleGradient,
            onTap: () => Navigator.pushNamed(context, AppRoutes.tripHistory),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTripCard(TripModel trip) {
    return Column(
      children: [
        GlassCard(
          gradientColors: const [Color(0xFF1A237E), Color(0xFF283593)],
          onTap: () => Navigator.pushNamed(context, AppRoutes.safeTrip),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_run,
                      color: AppColors.accent, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      trip.destinationName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: trip.isOverdue
                          ? AppColors.warning
                          : AppColors.info,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      trip.isOverdue ? 'OVERDUE' : 'ACTIVE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Time progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: trip.timeProgress,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  color: trip.isOverdue ? AppColors.warning : AppColors.accent,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ETA: ${Helpers.formatTime(trip.expectedArrivalTime)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    trip.isOverdue
                        ? 'Overdue!'
                        : '${Helpers.formatDuration(trip.remainingTime)} remaining',
                    style: TextStyle(
                      color: trip.isOverdue
                          ? AppColors.warning
                          : AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        icon: Icons.people,
        label: 'Contacts',
        gradient: AppColors.accentGradient,
        onTap: () => Navigator.pushNamed(context, AppRoutes.contacts),
      ),
      _QuickAction(
        icon: Icons.route,
        label: 'Safe Trip',
        gradient: AppColors.safeGradient,
        onTap: () => Navigator.pushNamed(context, AppRoutes.safeTrip),
      ),
      _QuickAction(
        icon: Icons.location_on,
        label: 'Live Track',
        gradient: AppColors.purpleGradient,
        onTap: () => Navigator.pushNamed(context, AppRoutes.liveTracking),
      ),
      _QuickAction(
        icon: Icons.history,
        label: 'History',
        gradient: const [Color(0xFFFF9800), Color(0xFFF57C00)],
        onTap: () => Navigator.pushNamed(context, AppRoutes.tripHistory),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return GestureDetector(
          onTap: action.onTap,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: action.gradient),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: action.gradient.first.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(action.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                action.label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentAlerts(String uid) {
    if (uid.isEmpty) {
      return const Center(child: Text('No recent activity'));
    }
    return StreamBuilder<List<SOSAlert>>(
      stream: _firestoreService.getSOSAlerts(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return GlassCard(
            child: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'No recent alerts — you\'re all safe!',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          );
        }

        final alerts = snapshot.data!.take(3).toList();
        return Column(
          children: alerts.map((alert) {
            return GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (alert.isManual
                              ? AppColors.error
                              : AppColors.warning)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      alert.isManual
                          ? Icons.sos
                          : Icons.timer_off,
                      color:
                          alert.isManual ? AppColors.error : AppColors.warning,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Helpers.getSOSTypeLabel(alert.type),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Helpers.timeAgo(alert.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.textLight
                                : AppColors.textDarkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSOSFab() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.sos),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.sosGradient,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary
                      .withValues(alpha: 0.3 + (_pulseController.value * 0.3)),
                  blurRadius: 16 + (_pulseController.value * 8),
                  spreadRadius: _pulseController.value * 4,
                ),
              ],
            ),
            child: const Icon(Icons.sos, color: Colors.white, size: 30),
          );
        },
      ),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_filled, 'Home', 0),
              _buildNavItem(Icons.route, 'Trips', 1),
              const SizedBox(width: 60), // space for SOS FAB
              _buildNavItem(Icons.map, 'Track', 2),
              _buildNavItem(Icons.settings, 'Settings', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
        switch (index) {
          case 1:
            Navigator.pushNamed(context, AppRoutes.tripHistory);
            break;
          case 2:
            Navigator.pushNamed(context, AppRoutes.liveTracking);
            break;
          case 3:
            Navigator.pushNamed(context, AppRoutes.settings);
            break;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isActive ? AppColors.primary : AppColors.textMuted,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? AppColors.primary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;

  _QuickAction({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });
}
