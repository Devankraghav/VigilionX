/// VigilionX - Firestore Service
/// Handles all Cloud Firestore CRUD operations for the application.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';
import '../models/emergency_contact.dart';
import '../models/trip_model.dart';
import '../models/sos_alert.dart';
import '../models/alert_log.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─────────────────────────────────────────────────────────
  // EMERGENCY CONTACTS
  // ─────────────────────────────────────────────────────────

  /// Add a new emergency contact
  Future<String> addEmergencyContact(EmergencyContact contact) async {
    final doc = await _db
        .collection(AppConstants.emergencyContactsCollection)
        .add(contact.toMap());
    return doc.id;
  }

  /// Update an emergency contact
  Future<void> updateEmergencyContact(EmergencyContact contact) async {
    await _db
        .collection(AppConstants.emergencyContactsCollection)
        .doc(contact.id)
        .update(contact.toMap());
  }

  /// Delete an emergency contact
  Future<void> deleteEmergencyContact(String contactId) async {
    await _db
        .collection(AppConstants.emergencyContactsCollection)
        .doc(contactId)
        .delete();
  }

  /// Get a stream of emergency contacts for a user
  Stream<List<EmergencyContact>> getEmergencyContacts(String uid) {
    return _db
        .collection(AppConstants.emergencyContactsCollection)
        .where('ownerUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EmergencyContact.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get contacts once (for SOS sending)
  Future<List<EmergencyContact>> getEmergencyContactsOnce(String uid) async {
    final snapshot = await _db
        .collection(AppConstants.emergencyContactsCollection)
        .where('ownerUid', isEqualTo: uid)
        .get();
    return snapshot.docs
        .map((doc) => EmergencyContact.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ─────────────────────────────────────────────────────────
  // TRIPS
  // ─────────────────────────────────────────────────────────

  /// Create a new trip
  Future<String> createTrip(TripModel trip) async {
    final doc = await _db
        .collection(AppConstants.tripsCollection)
        .add(trip.toMap());
    return doc.id;
  }

  /// Update trip status and location
  Future<void> updateTrip(String tripId, Map<String, dynamic> data) async {
    await _db
        .collection(AppConstants.tripsCollection)
        .doc(tripId)
        .update(data);
  }

  /// Complete a trip
  Future<void> completeTrip(String tripId) async {
    await _db.collection(AppConstants.tripsCollection).doc(tripId).update({
      'status': AppConstants.tripCompleted,
      'completedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Get active trip for a user
  Stream<TripModel?> getActiveTrip(String uid) {
    return _db
        .collection(AppConstants.tripsCollection)
        .where('ownerUid', isEqualTo: uid)
        .where('status', isEqualTo: AppConstants.tripActive)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return TripModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
    });
  }

  /// Get trip history for a user
  Stream<List<TripModel>> getTripHistory(String uid) {
    return _db
        .collection(AppConstants.tripsCollection)
        .where('ownerUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TripModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get overdue trips for monitoring
  Future<List<TripModel>> getOverdueTrips(String uid) async {
    final snapshot = await _db
        .collection(AppConstants.tripsCollection)
        .where('ownerUid', isEqualTo: uid)
        .where('status', isEqualTo: AppConstants.tripActive)
        .get();

    return snapshot.docs
        .map((doc) => TripModel.fromMap(doc.data(), doc.id))
        .where((trip) => trip.isOverdue)
        .toList();
  }

  // ─────────────────────────────────────────────────────────
  // SOS ALERTS
  // ─────────────────────────────────────────────────────────

  /// Create an SOS alert
  Future<String> createSOSAlert(SOSAlert alert) async {
    final doc = await _db
        .collection(AppConstants.sosAlertsCollection)
        .add(alert.toMap());
    return doc.id;
  }

  /// Get SOS alerts for a user
  Stream<List<SOSAlert>> getSOSAlerts(String uid) {
    return _db
        .collection(AppConstants.sosAlertsCollection)
        .where('ownerUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SOSAlert.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ─────────────────────────────────────────────────────────
  // ALERT LOGS
  // ─────────────────────────────────────────────────────────

  /// Create an alert log entry
  Future<String> createAlertLog(AlertLog log) async {
    final doc = await _db
        .collection(AppConstants.alertLogsCollection)
        .add(log.toMap());
    return doc.id;
  }

  /// Get alert logs for a user
  Stream<List<AlertLog>> getAlertLogs(String uid) {
    return _db
        .collection(AppConstants.alertLogsCollection)
        .where('ownerUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AlertLog.fromMap(doc.data(), doc.id))
            .toList());
  }
}
