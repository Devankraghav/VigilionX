/// VigilionX - Trip Provider
/// Manages safe trip monitoring, ETA tracking, and automatic alert generation.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';
import '../models/trip_model.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../providers/sos_provider.dart';

class TripProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();

  TripModel? _activeTrip;
  List<TripModel> _tripHistory = [];
  bool _isLoading = false;
  String? _error;
  Timer? _monitorTimer;
  StreamSubscription? _activeTripSubscription;
  StreamSubscription? _historySubscription;

  TripModel? get activeTrip => _activeTrip;
  List<TripModel> get tripHistory => _tripHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActiveTrip => _activeTrip != null;

  /// Start listening to active trip and history
  void initialize(String uid) {
    _activeTripSubscription?.cancel();
    _historySubscription?.cancel();

    // Listen to active trip
    _activeTripSubscription = _firestoreService.getActiveTrip(uid).listen(
      (trip) {
        _activeTrip = trip;
        notifyListeners();

        // Start monitoring if trip is active
        if (trip != null) {
          _startMonitoring(uid);
        } else {
          _stopMonitoring();
        }
      },
    );

    // Listen to trip history
    _historySubscription = _firestoreService.getTripHistory(uid).listen(
      (trips) {
        _tripHistory = trips;
        notifyListeners();
      },
    );
  }

  /// Create a new safe trip
  Future<bool> startTrip({
    required String ownerUid,
    required String destinationName,
    required double destinationLat,
    required double destinationLng,
    required DateTime expectedArrivalTime,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get current location
      final position = await _locationService.getCurrentPosition();

      final trip = TripModel(
        id: '',
        ownerUid: ownerUid,
        destinationName: destinationName,
        destinationLat: destinationLat,
        destinationLng: destinationLng,
        startTime: DateTime.now(),
        expectedArrivalTime: expectedArrivalTime,
        status: AppConstants.tripActive,
        lastKnownLat: position?.latitude,
        lastKnownLng: position?.longitude,
        createdAt: DateTime.now(),
      );

      await _firestoreService.createTrip(trip);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to start trip: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Mark active trip as completed
  Future<bool> completeTrip() async {
    if (_activeTrip == null) return false;

    try {
      await _firestoreService.completeTrip(_activeTrip!.id);
      _stopMonitoring();
      return true;
    } catch (e) {
      _error = 'Failed to complete trip';
      notifyListeners();
      return false;
    }
  }

  /// Start periodic monitoring for ETA overdue
  void _startMonitoring(String uid) {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(
      const Duration(seconds: AppConstants.tripCheckInterval),
      (_) => _checkTripStatus(uid),
    );
  }

  /// Check if active trip is overdue and trigger automatic alert
  Future<void> _checkTripStatus(String uid) async {
    if (_activeTrip == null) return;

    // Update last known location
    final position = await _locationService.getCurrentPosition();
    if (position != null) {
      await _firestoreService.updateTrip(_activeTrip!.id, {
        'lastKnownLat': position.latitude,
        'lastKnownLng': position.longitude,
      });
    }

    // Check if trip is overdue
    if (_activeTrip!.isOverdue) {
      // Mark trip as alerted
      await _firestoreService.updateTrip(_activeTrip!.id, {
        'status': AppConstants.tripAlerted,
      });

      // Trigger automatic delay alert via SOS provider
      final sosProvider = SOSProvider();
      await sosProvider.triggerTripDelayAlert(
        ownerUid: uid,
        tripId: _activeTrip!.id,
        lat: position?.latitude ?? _activeTrip!.lastKnownLat ?? 0,
        lng: position?.longitude ?? _activeTrip!.lastKnownLng ?? 0,
        tripName: _activeTrip!.destinationName,
      );

      _stopMonitoring();
    }
  }

  void _stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }

  @override
  void dispose() {
    _stopMonitoring();
    _activeTripSubscription?.cancel();
    _historySubscription?.cancel();
    super.dispose();
  }
}
