/// VigilionX - SOS Alert Model
/// Represents an emergency SOS alert (manual or automatic trip delay).

import 'package:cloud_firestore/cloud_firestore.dart';

class SOSAlert {
  final String id;
  final String ownerUid;
  final String type; // manual, automatic_trip_delay
  final double latitude;
  final double longitude;
  final String message;
  final String status; // sent, pending, failed
  final DateTime createdAt;
  final String? tripId; // linked trip for auto alerts

  SOSAlert({
    required this.id,
    required this.ownerUid,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.message,
    required this.status,
    required this.createdAt,
    this.tripId,
  });

  bool get isManual => type == 'manual';
  bool get isAutomatic => type == 'automatic_trip_delay';

  factory SOSAlert.fromMap(Map<String, dynamic> map, String docId) {
    return SOSAlert(
      id: docId,
      ownerUid: map['ownerUid'] ?? '',
      type: map['type'] ?? 'manual',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      message: map['message'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tripId: map['tripId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerUid': ownerUid,
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'message': message,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'tripId': tripId,
    };
  }
}
