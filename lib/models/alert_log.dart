/// VigilionX - Alert Log Model
/// Records the delivery status of alerts sent to trusted contacts.

import 'package:cloud_firestore/cloud_firestore.dart';

class AlertLog {
  final String id;
  final String ownerUid;
  final String alertId;
  final List<String> recipients;
  final String deliveryStatus; // sent, delivered, failed, pending
  final String alertType;
  final String? message;
  final DateTime createdAt;

  AlertLog({
    required this.id,
    required this.ownerUid,
    required this.alertId,
    required this.recipients,
    required this.deliveryStatus,
    required this.alertType,
    this.message,
    required this.createdAt,
  });

  factory AlertLog.fromMap(Map<String, dynamic> map, String docId) {
    return AlertLog(
      id: docId,
      ownerUid: map['ownerUid'] ?? '',
      alertId: map['alertId'] ?? '',
      recipients: List<String>.from(map['recipients'] ?? []),
      deliveryStatus: map['deliveryStatus'] ?? 'pending',
      alertType: map['alertType'] ?? 'manual',
      message: map['message'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerUid': ownerUid,
      'alertId': alertId,
      'recipients': recipients,
      'deliveryStatus': deliveryStatus,
      'alertType': alertType,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
