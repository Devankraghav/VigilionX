/// VigilionX - SOS Provider
/// Manages SOS alert triggering workflow.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:another_telephony/telephony.dart';
import '../config/constants.dart';
import '../models/alert_log.dart';
import '../models/sos_alert.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';

class SOSProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();
  final Telephony _telephony = Telephony.instance;

  bool _isSending = false;
  bool _isSent = false;
  String? _error;
  SOSAlert? _lastAlert;

  bool get isSending => _isSending;
  bool get isSent => _isSent;
  String? get error => _error;
  SOSAlert? get lastAlert => _lastAlert;

  Future<bool> triggerSOS({required String ownerUid}) async {
    try {
      _isSending = true;
      _isSent = false;
      _error = null;
      notifyListeners();

      // Step 1: Get current user data directly from Firestore
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(ownerUid)
          .get();

      if (!userSnapshot.exists || userSnapshot.data() == null) {
        throw Exception('User data not found');
      }

      final userData = userSnapshot.data()!;

      final String senderName =
      (userData['fullName'] ?? userData['username'] ?? 'Unknown User')
          .toString()
          .trim();

      final String senderPhone =
      (userData['phone'] ?? userData['mobile'] ?? 'No Number')
          .toString()
          .trim();

      // Step 2: Get current location
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        throw Exception('Unable to get your location. Please enable GPS.');
      }

      final double latitude = position.latitude;
      final double longitude = position.longitude;
      final String mapsLink =
          'https://www.google.com/maps?q=$latitude,$longitude';

      // Step 3: Get trusted contacts
      final contacts =
      await _firestoreService.getEmergencyContactsOnce(ownerUid);

      final List<String> recipientPhones = contacts
          .map((c) => c.phone.trim())
          .where((phone) => phone.isNotEmpty)
          .toList();

      if (recipientPhones.isEmpty) {
        throw Exception('No trusted contacts found');
      }

      // Step 4: Request SMS permission
      final bool? smsPermission =
      await _telephony.requestPhoneAndSmsPermissions;

      if (smsPermission != true) {
        throw Exception('SMS permission denied');
      }

      final now = DateTime.now();

      // Step 5: Create SOS alert model
      final alert = SOSAlert(
        id: '',
        ownerUid: ownerUid,
        type: AppConstants.sosManual,
        latitude: latitude,
        longitude: longitude,
        message: 'Emergency SOS triggered manually',
        status: AppConstants.alertSent,
        createdAt: now,
      );

      // Step 6: Save SOS alert in Firestore
      final alertId = await _firestoreService.createSOSAlert(alert);

      // Step 7: Save alert log
      final alertLog = AlertLog(
        id: '',
        ownerUid: ownerUid,
        alertId: alertId,
        recipients: recipientPhones,
        deliveryStatus: AppConstants.alertSent,
        alertType: AppConstants.sosManual,
        message: alert.message,
        createdAt: now,
      );
      await _firestoreService.createAlertLog(alertLog);

      // Step 8: Show local notification
      await _notificationService.showSOSNotification(
        'VigilionX',
        'SOS Alert sent! Location: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
      );

      // Step 9: Auto-send SMS to all trusted contacts
      final String smsMessage = '''
EMERGENCY ALERT

Name: $senderName
Phone: $senderPhone
Time: $now

I may be in danger. Please track my current location:
$mapsLink

Please help immediately.
''';

      for (final phone in recipientPhones) {
        await _telephony.sendSms(
          to: phone,
          message: smsMessage,
        );
      }

      // Step 10: Update provider state
      _lastAlert = SOSAlert(
        id: alertId,
        ownerUid: ownerUid,
        type: AppConstants.sosManual,
        latitude: latitude,
        longitude: longitude,
        message: alert.message,
        status: AppConstants.alertSent,
        createdAt: now,
      );

      _isSending = false;
      _isSent = true;
      _error = null;
      notifyListeners();

      return true;
    } catch (e) {
      _isSending = false;
      _isSent = false;
      _error = 'Failed to send SOS: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> triggerTripDelayAlert({
    required String ownerUid,
    required String tripId,
    required double lat,
    required double lng,
    required String tripName,
  }) async {
    try {
      final alert = SOSAlert(
        id: '',
        ownerUid: ownerUid,
        type: AppConstants.sosAutoTripDelay,
        latitude: lat,
        longitude: lng,
        message: AppConstants.tripDelayMessage,
        status: AppConstants.alertSent,
        createdAt: DateTime.now(),
        tripId: tripId,
      );

      final alertId = await _firestoreService.createSOSAlert(alert);

      final contacts =
      await _firestoreService.getEmergencyContactsOnce(ownerUid);
      final recipientPhones = contacts
          .map((c) => c.phone.trim())
          .where((phone) => phone.isNotEmpty)
          .toList();

      if (recipientPhones.isNotEmpty) {
        final alertLog = AlertLog(
          id: '',
          ownerUid: ownerUid,
          alertId: alertId,
          recipients: recipientPhones,
          deliveryStatus: AppConstants.alertSent,
          alertType: AppConstants.sosAutoTripDelay,
          message: AppConstants.tripDelayMessage,
          createdAt: DateTime.now(),
        );
        await _firestoreService.createAlertLog(alertLog);
      }

      await _notificationService.showTripDelayNotification(tripName);
      return true;
    } catch (e) {
      return false;
    }
  }

  void reset() {
    _isSending = false;
    _isSent = false;
    _error = null;
    _lastAlert = null;
    notifyListeners();
  }
}