/// VigilionX - Trip Model
/// Represents a safe trip with monitoring and ETA tracking.

import 'package:cloud_firestore/cloud_firestore.dart';

class TripModel {
  final String id;
  final String ownerUid;
  final String destinationName;
  final double destinationLat;
  final double destinationLng;
  final DateTime startTime;
  final DateTime expectedArrivalTime;
  final String status; // active, completed, late, alerted
  final double? lastKnownLat;
  final double? lastKnownLng;
  final DateTime createdAt;
  final DateTime? completedAt;

  TripModel({
    required this.id,
    required this.ownerUid,
    required this.destinationName,
    required this.destinationLat,
    required this.destinationLng,
    required this.startTime,
    required this.expectedArrivalTime,
    required this.status,
    this.lastKnownLat,
    this.lastKnownLng,
    required this.createdAt,
    this.completedAt,
  });

  /// Check if trip is past its expected arrival time
  bool get isOverdue =>
      status == 'active' && DateTime.now().isAfter(expectedArrivalTime);

  /// Remaining time until ETA
  Duration get remainingTime =>
      expectedArrivalTime.difference(DateTime.now());

  /// Progress percentage (0.0 to 1.0) based on time elapsed
  double get timeProgress {
    final total = expectedArrivalTime.difference(startTime).inSeconds;
    final elapsed = DateTime.now().difference(startTime).inSeconds;
    if (total <= 0) return 1.0;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  factory TripModel.fromMap(Map<String, dynamic> map, String docId) {
    return TripModel(
      id: docId,
      ownerUid: map['ownerUid'] ?? '',
      destinationName: map['destinationName'] ?? '',
      destinationLat: (map['destinationLat'] ?? 0).toDouble(),
      destinationLng: (map['destinationLng'] ?? 0).toDouble(),
      startTime: (map['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expectedArrivalTime:
          (map['expectedArrivalTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'active',
      lastKnownLat: map['lastKnownLat']?.toDouble(),
      lastKnownLng: map['lastKnownLng']?.toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerUid': ownerUid,
      'destinationName': destinationName,
      'destinationLat': destinationLat,
      'destinationLng': destinationLng,
      'startTime': Timestamp.fromDate(startTime),
      'expectedArrivalTime': Timestamp.fromDate(expectedArrivalTime),
      'status': status,
      'lastKnownLat': lastKnownLat,
      'lastKnownLng': lastKnownLng,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  TripModel copyWith({
    String? status,
    double? lastKnownLat,
    double? lastKnownLng,
    DateTime? completedAt,
  }) {
    return TripModel(
      id: id,
      ownerUid: ownerUid,
      destinationName: destinationName,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      startTime: startTime,
      expectedArrivalTime: expectedArrivalTime,
      status: status ?? this.status,
      lastKnownLat: lastKnownLat ?? this.lastKnownLat,
      lastKnownLng: lastKnownLng ?? this.lastKnownLng,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
